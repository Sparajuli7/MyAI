use anyhow::Result;
use chrono::{DateTime, Utc};
use rusqlite::{Connection, Row};
use serde_json::Value;
use std::collections::HashMap;
use std::path::Path;
use tantivy::{
    collector::TopDocs,
    doc,
    query::{BooleanQuery, Occur, QueryParser, TermQuery},
    schema::{Field, Schema, STORED, TEXT},
    Document, Index, IndexReader, IndexWriter, Term,
};
use tracing::{info, warn};
use types::{Chunk, Document as DocType};
use uuid::Uuid;

pub mod database;
pub mod tantivy_store;
pub mod hnsw_store;

pub use database::Database;
pub use tantivy_store::TantivyStore;
pub use hnsw_store::HnswStore;

#[derive(Debug)]
pub struct StorageManager {
    pub database: Database,
    pub tantivy: TantivyStore,
    pub hnsw: HnswStore,
}

impl StorageManager {
    pub async fn new(data_dir: &str) -> Result<Self> {
        info!("Initializing storage manager...");
        
        let database = Database::new(data_dir).await?;
        let tantivy = TantivyStore::new(data_dir).await?;
        let hnsw = HnswStore::new(data_dir).await?;
        
        info!("Storage manager initialized successfully");
        Ok(Self {
            database,
            tantivy,
            hnsw,
        })
    }
    
    pub async fn save_document(&self, doc: &DocType) -> Result<()> {
        self.database.save_document(doc).await?;
        Ok(())
    }
    
    pub async fn upsert_chunk(&self, chunk: &Chunk) -> Result<()> {
        self.database.upsert_chunk(chunk).await?;
        self.tantivy.index_chunk(chunk).await?;
        
        if let Some(embedding) = &chunk.embedding {
            self.hnsw.add_vector(&chunk.id, embedding).await?;
        }
        
        Ok(())
    }
    
    pub async fn get_chunks_by_ids(&self, chunk_ids: &[String]) -> Result<Vec<Chunk>> {
        self.database.get_chunks_by_ids(chunk_ids).await
    }
    
    pub async fn list_recent_docs(&self, limit: usize) -> Result<Vec<DocType>> {
        self.database.list_recent_docs(limit).await
    }
    
    pub async fn search_bm25(&self, query: &str, limit: usize) -> Result<Vec<(String, f32)>> {
        self.tantivy.search(query, limit).await
    }
    
    pub async fn search_ann(&self, query_embedding: &[f32], limit: usize) -> Result<Vec<(String, f32)>> {
        self.hnsw.search(query_embedding, limit).await
    }
    
    pub async fn get_stats(&self) -> Result<(u64, u64)> {
        let docs = self.database.count_documents().await?;
        let chunks = self.database.count_chunks().await?;
        Ok((docs, chunks))
    }
}
