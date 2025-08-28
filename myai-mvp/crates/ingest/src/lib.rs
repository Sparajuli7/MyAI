use anyhow::Result;
use chrono::Utc;
use std::collections::HashMap;
use std::path::Path;
use tracing::{info, warn};
use types::{AppConfig, Chunk, Document, IngestResult};
use uuid::Uuid;

pub mod chunker;
pub mod handlers;

pub use chunker::Chunker;
pub use handlers::FileHandler;

pub struct IngestPipeline {
    config: AppConfig,
    chunker: Chunker,
    handlers: HashMap<String, Box<dyn FileHandler>>,
}

impl IngestPipeline {
    pub fn new(config: AppConfig) -> Result<Self> {
        let chunker = Chunker::new(config.ingest.chunk_size, config.ingest.overlap);
        let mut handlers: HashMap<String, Box<dyn FileHandler>> = HashMap::new();
        
        // Register file handlers
        handlers.insert("text/plain".to_string(), Box::new(handlers::TextHandler));
        handlers.insert("text/markdown".to_string(), Box::new(handlers::MarkdownHandler));
        handlers.insert("application/pdf".to_string(), Box::new(handlers::PdfHandler));
        
        Ok(Self {
            config,
            chunker,
            handlers,
        })
    }
    
    pub async fn ingest_path(&self, path: &Path) -> Result<IngestResult> {
        let start_time = std::time::Instant::now();
        
        info!("Ingesting file: {:?}", path);
        
        // Determine MIME type
        let mime_type = mime_guess::from_path(path)
            .first_or_octet_stream()
            .to_string();
        
        // Check if MIME type is allowed
        if !self.is_mime_allowed(&mime_type) {
            return Err(anyhow::anyhow!("MIME type {} not allowed", mime_type));
        }
        
        // Check file size
        let metadata = tokio::fs::metadata(path).await?;
        let file_size_mb = metadata.len() / (1024 * 1024);
        if file_size_mb > self.config.privacy.max_file_mb {
            return Err(anyhow::anyhow!(
                "File too large: {}MB (max: {}MB)",
                file_size_mb,
                self.config.privacy.max_file_mb
            ));
        }
        
        // Create document
        let doc = Document::new(
            path.to_string_lossy().to_string(),
            path.file_name()
                .unwrap_or_default()
                .to_string_lossy()
                .to_string(),
            "file".to_string(),
            mime_type.clone(),
        );
        
        // Extract text content
        let handler = self.handlers.get(&mime_type)
            .ok_or_else(|| anyhow::anyhow!("No handler for MIME type: {}", mime_type))?;
        
        let content = handler.extract_text(path).await?;
        
        // Generate chunks
        let chunks = self.chunker.chunk(&content, &doc.id)?;
        
        // Deduplicate chunks
        let (unique_chunks, skipped) = self.deduplicate_chunks(chunks)?;
        
        let took_ms = start_time.elapsed().as_millis() as u64;
        
        info!(
            "Ingested {} chunks ({} skipped) in {}ms",
            unique_chunks.len(),
            skipped,
            took_ms
        );
        
        Ok(IngestResult {
            doc_id: doc.id.clone(),
            chunks: unique_chunks.len() as u32,
            skipped,
            took_ms,
        })
    }
    
    pub async fn ingest_text(&self, text: &str, title: Option<String>, source: Option<String>) -> Result<IngestResult> {
        let start_time = std::time::Instant::now();
        
        info!("Ingesting text: {}", title.as_deref().unwrap_or("Untitled"));
        
        // Create document
        let doc = Document::new(
            "text://".to_string(),
            title.unwrap_or_else(|| "Untitled".to_string()),
            source.unwrap_or_else(|| "text".to_string()),
            "text/plain".to_string(),
        );
        
        // Generate chunks
        let chunks = self.chunker.chunk(text, &doc.id)?;
        
        // Deduplicate chunks
        let (unique_chunks, skipped) = self.deduplicate_chunks(chunks)?;
        
        let took_ms = start_time.elapsed().as_millis() as u64;
        
        info!(
            "Ingested {} chunks ({} skipped) in {}ms",
            unique_chunks.len(),
            skipped,
            took_ms
        );
        
        Ok(IngestResult {
            doc_id: doc.id.clone(),
            chunks: unique_chunks.len() as u32,
            skipped,
            took_ms,
        })
    }
    
    fn is_mime_allowed(&self, mime_type: &str) -> bool {
        let mime_group = mime_type.split('/').next().unwrap_or("");
        self.config.privacy.allowed_mime_groups.contains(&mime_group.to_string())
    }
    
    fn deduplicate_chunks(&self, chunks: Vec<Chunk>) -> Result<(Vec<Chunk>, u32)> {
        let mut unique_chunks = Vec::new();
        let mut seen_hashes = std::collections::HashSet::new();
        let mut skipped = 0;
        
        for chunk in chunks {
            let hash = blake3::hash(chunk.text.as_bytes()).to_string();
            if seen_hashes.insert(hash) {
                unique_chunks.push(chunk);
            } else {
                skipped += 1;
            }
        }
        
        Ok((unique_chunks, skipped))
    }
}
