use anyhow::Result;
use std::collections::HashMap;
use types::{Chunk, Document};

pub struct Chunker {
    chunk_size: usize,
    overlap: usize,
}

impl Chunker {
    pub fn new(chunk_size: usize, overlap: usize) -> Self {
        Self {
            chunk_size,
            overlap,
        }
    }
    
    pub fn chunk(&self, text: &str, doc_id: &str) -> Result<Vec<Chunk>> {
        let mut chunks = Vec::new();
        let mut start = 0;
        
        while start < text.len() {
            let end = (start + self.chunk_size).min(text.len());
            
            // Try to break at sentence boundaries
            let actual_end = if end < text.len() {
                self.find_sentence_boundary(&text[start..end])
            } else {
                end - start
            };
            
            let chunk_text = text[start..start + actual_end].trim();
            
            if !chunk_text.is_empty() {
                let mut metadata = HashMap::new();
                metadata.insert("title".to_string(), serde_json::Value::String("Document".to_string()));
                metadata.insert("section".to_string(), serde_json::Value::String(format!("chunk_{}", chunks.len())));
                
                let chunk = Chunk {
                    id: uuid::Uuid::new_v4().to_string(),
                    doc_id: doc_id.to_string(),
                    text: chunk_text.to_string(),
                    embedding: None,
                    metadata,
                    created_at: chrono::Utc::now(),
                };
                
                chunks.push(chunk);
            }
            
            // Move to next chunk with overlap
            start += actual_end.saturating_sub(self.overlap);
        }
        
        Ok(chunks)
    }
    
    fn find_sentence_boundary(&self, text: &str) -> usize {
        // Simple sentence boundary detection
        let sentence_endings = ['.', '!', '?', '\n'];
        
        for (i, char) in text.char_indices().rev() {
            if sentence_endings.contains(&char) {
                return i + 1;
            }
        }
        
        text.len()
    }
}
