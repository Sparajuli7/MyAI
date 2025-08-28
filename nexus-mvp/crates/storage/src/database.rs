use anyhow::Result;
use chrono::{DateTime, Utc};
use rusqlite::{Connection, Row};
use serde_json::Value;
use std::collections::HashMap;
use std::path::Path;
use tokio::sync::Mutex;
use tracing::info;
use types::{Chunk, Document};

pub struct Database {
    conn: Mutex<Connection>,
}

impl Database {
    pub async fn new(data_dir: &str) -> Result<Self> {
        let db_path = Path::new(data_dir).join("myai.db");
        info!("Opening database at {:?}", db_path);
        
        let conn = Connection::open(&db_path)?;
        
        // Create tables if they don't exist
        conn.execute_batch(
            r#"
            CREATE TABLE IF NOT EXISTS documents (
                id TEXT PRIMARY KEY,
                path TEXT NOT NULL,
                title TEXT NOT NULL,
                modified_at INTEGER NOT NULL,
                source TEXT NOT NULL,
                mime TEXT NOT NULL
            );
            
            CREATE TABLE IF NOT EXISTS chunks (
                id TEXT PRIMARY KEY,
                doc_id TEXT NOT NULL,
                text TEXT NOT NULL,
                ts INTEGER NOT NULL,
                meta TEXT NOT NULL,
                vec BLOB,
                FOREIGN KEY (doc_id) REFERENCES documents (id)
            );
            
            CREATE INDEX IF NOT EXISTS idx_chunks_doc_id ON chunks (doc_id);
            CREATE INDEX IF NOT EXISTS idx_chunks_ts ON chunks (ts);
            "#,
        )?;
        
        info!("Database initialized successfully");
        Ok(Self {
            conn: Mutex::new(conn),
        })
    }
    
    pub async fn save_document(&self, doc: &Document) -> Result<()> {
        let conn = self.conn.lock().await;
        conn.execute(
            "INSERT OR REPLACE INTO documents (id, path, title, modified_at, source, mime) VALUES (?, ?, ?, ?, ?, ?)",
            (
                &doc.id,
                &doc.path,
                &doc.title,
                doc.modified_at.timestamp(),
                &doc.source,
                &doc.mime,
            ),
        )?;
        Ok(())
    }
    
    pub async fn upsert_chunk(&self, chunk: &Chunk) -> Result<()> {
        let conn = self.conn.lock().await;
        
        let meta_json = serde_json::to_string(&chunk.metadata)?;
        let vec_blob = chunk.embedding.as_ref().map(|v| {
            let bytes: Vec<u8> = v.iter().flat_map(|&f| f.to_le_bytes()).collect();
            bytes
        });
        
        conn.execute(
            "INSERT OR REPLACE INTO chunks (id, doc_id, text, ts, meta, vec) VALUES (?, ?, ?, ?, ?, ?)",
            (
                &chunk.id,
                &chunk.doc_id,
                &chunk.text,
                chunk.created_at.timestamp(),
                &meta_json,
                vec_blob.as_deref(),
            ),
        )?;
        Ok(())
    }
    
    pub async fn get_chunks_by_ids(&self, chunk_ids: &[String]) -> Result<Vec<Chunk>> {
        if chunk_ids.is_empty() {
            return Ok(vec![]);
        }
        
        let conn = self.conn.lock().await;
        let placeholders = chunk_ids.iter().map(|_| "?").collect::<Vec<_>>().join(",");
        let query = format!("SELECT * FROM chunks WHERE id IN ({})", placeholders);
        
        let mut stmt = conn.prepare(&query)?;
        let mut rows = stmt.query(rusqlite::params_from_iter(chunk_ids))?;
        
        let mut chunks = Vec::new();
        while let Some(row) = rows.next()? {
            chunks.push(self.row_to_chunk(row)?);
        }
        
        Ok(chunks)
    }
    
    pub async fn list_recent_docs(&self, limit: usize) -> Result<Vec<Document>> {
        let conn = self.conn.lock().await;
        let mut stmt = conn.prepare(
            "SELECT * FROM documents ORDER BY modified_at DESC LIMIT ?"
        )?;
        
        let mut rows = stmt.query([limit as i64])?;
        let mut docs = Vec::new();
        
        while let Some(row) = rows.next()? {
            docs.push(self.row_to_document(row)?);
        }
        
        Ok(docs)
    }
    
    pub async fn count_documents(&self) -> Result<u64> {
        let conn = self.conn.lock().await;
        let count: i64 = conn.query_row("SELECT COUNT(*) FROM documents", [], |row| row.get(0))?;
        Ok(count as u64)
    }
    
    pub async fn count_chunks(&self) -> Result<u64> {
        let conn = self.conn.lock().await;
        let count: i64 = conn.query_row("SELECT COUNT(*) FROM chunks", [], |row| row.get(0))?;
        Ok(count as u64)
    }
    
    fn row_to_chunk(&self, row: &Row) -> Result<Chunk> {
        let id: String = row.get(0)?;
        let doc_id: String = row.get(1)?;
        let text: String = row.get(2)?;
        let ts: i64 = row.get(3)?;
        let meta_json: String = row.get(4)?;
        let vec_blob: Option<Vec<u8>> = row.get(5)?;
        
        let metadata: HashMap<String, Value> = serde_json::from_str(&meta_json)?;
        let embedding = vec_blob.map(|bytes| {
            bytes
                .chunks_exact(4)
                .map(|chunk| f32::from_le_bytes([chunk[0], chunk[1], chunk[2], chunk[3]]))
                .collect()
        });
        
        Ok(Chunk {
            id,
            doc_id,
            text,
            embedding,
            metadata,
            created_at: DateTime::from_timestamp(ts, 0).unwrap_or_else(|| Utc::now()),
        })
    }
    
    fn row_to_document(&self, row: &Row) -> Result<Document> {
        let id: String = row.get(0)?;
        let path: String = row.get(1)?;
        let title: String = row.get(2)?;
        let modified_at: i64 = row.get(3)?;
        let source: String = row.get(4)?;
        let mime: String = row.get(5)?;
        
        Ok(Document {
            id,
            path,
            title,
            modified_at: DateTime::from_timestamp(modified_at, 0).unwrap_or_else(|| Utc::now()),
            source,
            mime,
        })
    }
}
