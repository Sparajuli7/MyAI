use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use serde_json::Value;
use std::collections::HashMap;
use thiserror::Error;
use utoipa::ToSchema;
use uuid::Uuid;

#[derive(Error, Debug)]
pub enum ApiError {
    #[error("Internal server error: {0}")]
    Internal(String),
    #[error("Bad request: {0}")]
    BadRequest(String),
    #[error("Not found: {0}")]
    NotFound(String),
    #[error("Validation error: {0}")]
    Validation(String),
}

impl ApiError {
    pub fn internal(msg: impl Into<String>) -> Self {
        Self::Internal(msg.into())
    }
    
    pub fn bad_request(msg: impl Into<String>) -> Self {
        Self::BadRequest(msg.into())
    }
    
    pub fn not_found(msg: impl Into<String>) -> Self {
        Self::NotFound(msg.into())
    }
    
    pub fn validation(msg: impl Into<String>) -> Self {
        Self::Validation(msg.into())
    }
}

#[derive(Debug, Serialize, Deserialize, ToSchema)]
pub struct QueryRequest {
    pub query: String,
    #[serde(default = "default_k")]
    pub k: u32,
    #[serde(rename = "dateFrom")]
    pub date_from: Option<String>,
    #[serde(rename = "dateTo")]
    pub date_to: Option<String>,
    pub filters: Option<QueryFilters>,
    #[serde(default)]
    pub stream: bool,
}

fn default_k() -> u32 {
    10
}

#[derive(Debug, Serialize, Deserialize, ToSchema)]
pub struct QueryFilters {
    pub sources: Option<Vec<String>>,
    #[serde(rename = "mimeGroups")]
    pub mime_groups: Option<Vec<String>>,
    pub people: Option<Vec<String>>,
}

#[derive(Debug, Serialize, Deserialize, ToSchema)]
pub struct QueryResponse {
    pub hits: Vec<SearchHit>,
    pub reasoning: ReasoningTrace,
    #[serde(rename = "tookMs")]
    pub took_ms: u64,
}

#[derive(Debug, Serialize, Deserialize, ToSchema)]
pub struct SearchHit {
    #[serde(rename = "chunkId")]
    pub chunk_id: String,
    #[serde(rename = "docId")]
    pub doc_id: String,
    pub title: String,
    pub snippet: String,
    pub score: f32,
    pub metadata: Value,
    #[serde(rename = "createdAt")]
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Serialize, Deserialize, ToSchema)]
pub struct ReasoningTrace {
    pub stages: Vec<ReasoningStage>,
}

#[derive(Debug, Serialize, Deserialize, ToSchema)]
pub struct ReasoningStage {
    pub stage: String,
    #[serde(rename = "partialHits")]
    pub partial_hits: Vec<SearchHit>,
    #[serde(rename = "elapsedMs")]
    pub elapsed_ms: u64,
}

#[derive(Debug, Serialize, Deserialize, ToSchema)]
pub struct IngestResult {
    #[serde(rename = "docId")]
    pub doc_id: String,
    pub chunks: u32,
    pub skipped: u32,
    #[serde(rename = "tookMs")]
    pub took_ms: u64,
}

#[derive(Debug, Serialize, Deserialize, ToSchema)]
pub struct IngestTextRequest {
    pub text: String,
    pub title: Option<String>,
    pub source: Option<String>,
}

#[derive(Debug, Serialize, Deserialize, ToSchema)]
pub struct StatusResponse {
    pub version: String,
    pub documents: u64,
    pub chunks: u64,
    pub uptime: u64,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct AppConfig {
    pub paths: PathsConfig,
    pub api: ApiConfig,
    pub retrieval: RetrievalConfig,
    pub privacy: PrivacyConfig,
    pub ingest: IngestConfig,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct PathsConfig {
    #[serde(rename = "dataDir")]
    pub data_dir: String,
    #[serde(rename = "modelDir")]
    pub model_dir: String,
    #[serde(rename = "watchPaths")]
    pub watch_paths: Vec<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ApiConfig {
    pub bind: String,
    #[serde(rename = "corsOrigins")]
    pub cors_origins: Vec<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct RetrievalConfig {
    #[serde(rename = "bm25K1")]
    pub bm25_k1: f32,
    #[serde(rename = "annEf")]
    pub ann_ef: usize,
    pub ann_m: usize,
    pub alpha: f32,
    pub beta: f32,
    #[serde(rename = "rerankTop")]
    pub rerank_top: usize,
    #[serde(rename = "finalTop")]
    pub final_top: usize,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct PrivacyConfig {
    #[serde(rename = "enableSqlcipher")]
    pub enable_sqlcipher: bool,
    #[serde(rename = "maxFileMb")]
    pub max_file_mb: u64,
    #[serde(rename = "allowedMimeGroups")]
    pub allowed_mime_groups: Vec<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct IngestConfig {
    #[serde(rename = "chunkSize")]
    pub chunk_size: usize,
    pub overlap: usize,
}

impl Default for AppConfig {
    fn default() -> Self {
        Self {
            paths: PathsConfig {
                data_dir: "~/.nexus-mvp/data".to_string(),
                model_dir: "~/.nexus-mvp/models".to_string(),
                watch_paths: vec![],
            },
            api: ApiConfig {
                bind: "127.0.0.1:7777".to_string(),
                cors_origins: vec!["http://localhost:3000".to_string()],
            },
            retrieval: RetrievalConfig {
                bm25_k1: 1.2,
                ann_ef: 100,
                ann_m: 16,
                alpha: 0.35,
                beta: 0.65,
                rerank_top: 50,
                final_top: 10,
            },
            privacy: PrivacyConfig {
                enable_sqlcipher: false,
                max_file_mb: 500,
                allowed_mime_groups: vec!["pdf".to_string(), "text".to_string()],
            },
            ingest: IngestConfig {
                chunk_size: 800,
                overlap: 120,
            },
        }
    }
}

// Internal types for the backend
#[derive(Debug, Clone)]
pub struct Chunk {
    pub id: String,
    pub doc_id: String,
    pub text: String,
    pub embedding: Option<Vec<f32>>,
    pub metadata: HashMap<String, Value>,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Clone)]
pub struct Document {
    pub id: String,
    pub path: String,
    pub title: String,
    pub modified_at: DateTime<Utc>,
    pub source: String,
    pub mime: String,
}

impl Chunk {
    pub fn new(doc_id: String, text: String) -> Self {
        Self {
            id: Uuid::new_v4().to_string(),
            doc_id,
            text,
            embedding: None,
            metadata: HashMap::new(),
            created_at: Utc::now(),
        }
    }
}

impl Document {
    pub fn new(path: String, title: String, source: String, mime: String) -> Self {
        Self {
            id: Uuid::new_v4().to_string(),
            path,
            title,
            modified_at: Utc::now(),
            source,
            mime,
        }
    }
}
