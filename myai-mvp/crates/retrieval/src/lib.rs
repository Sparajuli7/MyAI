use anyhow::Result;
use chrono::Utc;
use std::collections::HashMap;
use std::time::Instant;
use tracing::{info, warn};
use types::{
    AppConfig, Chunk, QueryFilters, QueryRequest, QueryResponse, ReasoningStage, ReasoningTrace,
    SearchHit,
};

use models::ModelManager;
use storage::StorageManager;

pub struct HybridIndex {
    storage: StorageManager,
    models: ModelManager,
    config: AppConfig,
}

impl HybridIndex {
    pub async fn new(storage: StorageManager, models: ModelManager, config: AppConfig) -> Result<Self> {
        Ok(Self {
            storage,
            models,
            config,
        })
    }
    
    pub async fn add_document(&self, doc: &types::Document) -> Result<()> {
        self.storage.save_document(doc).await
    }
    
    pub async fn add_chunk(&self, chunk: &Chunk) -> Result<()> {
        // Generate embedding for the chunk
        let mut chunk_with_embedding = chunk.clone();
        let embeddings = self.models.embedder.embed(&[chunk.text.clone()]).await?;
        
        if let Some(embedding) = embeddings.first() {
            chunk_with_embedding.embedding = Some(embedding.clone());
        }
        
        // Store chunk with embedding
        self.storage.upsert_chunk(&chunk_with_embedding).await
    }
    
    pub async fn search(
        &self,
        request: &QueryRequest,
    ) -> Result<(Vec<SearchHit>, ReasoningTrace)> {
        let start_time = Instant::now();
        let mut stages = Vec::new();
        
        info!("Starting hybrid search for query: {}", request.query);
        
        // Step 1: BM25 search
        let bm25_start = Instant::now();
        let bm25_results = self
            .storage
            .search_bm25(&request.query, self.config.retrieval.rerank_top)
            .await?;
        let bm25_elapsed = bm25_start.elapsed().as_millis() as u64;
        
        info!("BM25 found {} results in {}ms", bm25_results.len(), bm25_elapsed);
        
        // Step 2: ANN search
        let ann_start = Instant::now();
        let query_embedding = self
            .models
            .embedder
            .embed(&[request.query.clone()])
            .await?;
        
        let ann_results = if let Some(embedding) = query_embedding.first() {
            self.storage
                .search_ann(embedding, self.config.retrieval.rerank_top)
                .await?
        } else {
            vec![]
        };
        let ann_elapsed = ann_start.elapsed().as_millis() as u64;
        
        info!("ANN found {} results in {}ms", ann_results.len(), ann_elapsed);
        
        // Step 3: Hybrid union and scoring
        let hybrid_start = Instant::now();
        let mut combined_results = HashMap::new();
        
        // Add BM25 results
        for (chunk_id, bm25_score) in bm25_results {
            combined_results.insert(chunk_id, (bm25_score, 0.0));
        }
        
        // Add ANN results and combine scores
        for (chunk_id, ann_score) in ann_results {
            let entry = combined_results.entry(chunk_id).or_insert((0.0, 0.0));
            entry.1 = ann_score;
        }
        
        // Calculate hybrid scores
        let mut hybrid_results: Vec<(String, f32)> = combined_results
            .into_iter()
            .map(|(chunk_id, (bm25_score, ann_score))| {
                let hybrid_score = self.config.retrieval.alpha * bm25_score
                    + self.config.retrieval.beta * ann_score;
                (chunk_id, hybrid_score)
            })
            .collect();
        
        // Sort by hybrid score
        hybrid_results.sort_by(|a, b| b.1.partial_cmp(&a.1).unwrap());
        
        // Take top candidates for reranking
        let rerank_candidates: Vec<String> = hybrid_results
            .iter()
            .take(self.config.retrieval.rerank_top)
            .map(|(id, _)| id.clone())
            .collect();
        
        let hybrid_elapsed = hybrid_start.elapsed().as_millis() as u64;
        
        info!(
            "Hybrid union found {} candidates in {}ms",
            rerank_candidates.len(),
            hybrid_elapsed
        );
        
        // Step 4: Reranking
        let rerank_start = Instant::now();
        let chunks = self.storage.get_chunks_by_ids(&rerank_candidates).await?;
        
        let mut rerank_candidates_with_text = Vec::new();
        for chunk in &chunks {
            rerank_candidates_with_text.push((
                chunk.id.clone(),
                chunk.text.clone(),
            ));
        }
        
        let rerank_scores = self
            .models
            .reranker
            .rerank(&request.query, &rerank_candidates_with_text)
            .await?;
        
        let rerank_elapsed = rerank_start.elapsed().as_millis() as u64;
        
        info!("Reranking completed in {}ms", rerank_elapsed);
        
        // Step 5: Final ranking and snippet generation
        let mut final_results = Vec::new();
        for (i, chunk) in chunks.iter().enumerate() {
            if i < rerank_scores.len() {
                let rerank_score = rerank_scores[i];
                let snippet = self.generate_snippet(&chunk.text, &request.query);
                
                let search_hit = SearchHit {
                    chunk_id: chunk.id.clone(),
                    doc_id: chunk.doc_id.clone(),
                    title: chunk.metadata.get("title")
                        .and_then(|v| v.as_str())
                        .unwrap_or("Unknown")
                        .to_string(),
                    snippet,
                    score: rerank_score,
                    metadata: serde_json::to_value(&chunk.metadata)?,
                    created_at: chunk.created_at,
                };
                
                final_results.push(search_hit);
            }
        }
        
        // Sort by rerank score and take final top results
        final_results.sort_by(|a, b| b.score.partial_cmp(&a.score).unwrap());
        final_results.truncate(request.k as usize);
        
        let total_elapsed = start_time.elapsed().as_millis() as u64;
        
        info!(
            "Search completed in {}ms, returning {} results",
            total_elapsed,
            final_results.len()
        );
        
        // Build reasoning trace
        stages.push(ReasoningStage {
            stage: "bm25_topN".to_string(),
            partial_hits: vec![], // Would contain partial results for streaming
            elapsed_ms: bm25_elapsed,
        });
        
        stages.push(ReasoningStage {
            stage: "ann_topN".to_string(),
            partial_hits: vec![],
            elapsed_ms: ann_elapsed,
        });
        
        stages.push(ReasoningStage {
            stage: "hybrid_union".to_string(),
            partial_hits: vec![],
            elapsed_ms: hybrid_elapsed,
        });
        
        stages.push(ReasoningStage {
            stage: "rerank_topK".to_string(),
            partial_hits: vec![],
            elapsed_ms: rerank_elapsed,
        });
        
        let reasoning = ReasoningTrace { stages };
        
        Ok((final_results, reasoning))
    }
    
    fn generate_snippet(&self, text: &str, query: &str) -> String {
        // Simple snippet generation - find query terms and create a window around them
        let query_terms: Vec<&str> = query.split_whitespace().collect();
        let text_lower = text.to_lowercase();
        
        // Find the first occurrence of any query term
        let mut best_start = 0;
        let mut best_score = 0;
        
        for term in &query_terms {
            if let Some(pos) = text_lower.find(&term.to_lowercase()) {
                let score = term.len();
                if score > best_score {
                    best_score = score;
                    best_start = pos;
                }
            }
        }
        
        // Create a window around the best match
        let window_size = 200;
        let start = best_start.saturating_sub(window_size / 2);
        let end = (best_start + window_size).min(text.len());
        
        let snippet = &text[start..end];
        
        // Add ellipsis if we're not at the beginning/end
        let mut result = String::new();
        if start > 0 {
            result.push_str("...");
        }
        result.push_str(snippet);
        if end < text.len() {
            result.push_str("...");
        }
        
        result
    }
}
