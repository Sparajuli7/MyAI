use anyhow::Result;
use ndarray::{Array1, Array2};
use ort::{Environment, ExecutionProvider, GraphOptimizationLevel, Session, SessionBuilder, Value};
use std::path::Path;
use std::sync::Arc;
use tokenizers::Tokenizer;
use tracing::{info, warn};
use types::AppConfig;

pub mod embedding;
pub mod reranker;

pub use embedding::EmbeddingModel;
pub use reranker::RerankerModel;

#[derive(Debug)]
pub struct ModelManager {
    pub embedder: EmbeddingModel,
    pub reranker: RerankerModel,
}

impl ModelManager {
    pub async fn new(config: &AppConfig) -> Result<Self> {
        info!("Initializing model manager...");
        
        let embedder = EmbeddingModel::new(&config.paths.model_dir).await?;
        let reranker = RerankerModel::new(&config.paths.model_dir).await?;
        
        info!("Model manager initialized successfully");
        Ok(Self { embedder, reranker })
    }
}

pub trait Embedder {
    async fn embed(&self, texts: &[String]) -> Result<Vec<Vec<f32>>>;
}

pub trait Reranker {
    async fn rerank(&self, query: &str, candidates: &[(String, String)]) -> Result<Vec<f32>>;
}

// Helper function to create ONNX session
pub fn create_session(model_path: &Path) -> Result<Session> {
    let environment = Arc::new(
        Environment::builder()
            .with_name("myai-mvp")
            .with_log_level(ort::LoggingLevel::Warning)
            .build()?
    );

    let session = SessionBuilder::new(&environment)?
        .with_optimization_level(GraphOptimizationLevel::Level1)?
        .with_execution_providers([ExecutionProvider::CPU(Default::default())])?
        .with_model_from_file(model_path)?;

    Ok(session)
}

// Helper function to convert strings to tokenized input
pub fn tokenize_texts(tokenizer: &Tokenizer, texts: &[String]) -> Result<Vec<Vec<i64>>> {
    let mut tokenized = Vec::new();
    
    for text in texts {
        let encoding = tokenizer.encode(text, true)?;
        tokenized.push(encoding.get_ids().to_vec());
    }
    
    Ok(tokenized)
}

// Helper function to pad sequences to same length
pub fn pad_sequences(sequences: &[Vec<i64>], pad_value: i64) -> (Vec<i64>, Vec<i64>) {
    let max_len = sequences.iter().map(|seq| seq.len()).max().unwrap_or(0);
    
    let mut input_ids = Vec::new();
    let mut attention_mask = Vec::new();
    
    for sequence in sequences {
        let mut padded = sequence.clone();
        let mut mask = vec![1; sequence.len()];
        
        while padded.len() < max_len {
            padded.push(pad_value);
            mask.push(0);
        }
        
        input_ids.extend(padded);
        attention_mask.extend(mask);
    }
    
    (input_ids, attention_mask)
}

// Helper function to convert ONNX output to vectors
pub fn output_to_vectors(output: Value) -> Result<Vec<Vec<f32>>> {
    let shape = output.shape();
    let data = output.try_extract::<f32>()?;
    
    if shape.len() != 2 {
        return Err(anyhow::anyhow!("Expected 2D output, got {:?}", shape));
    }
    
    let batch_size = shape[0] as usize;
    let embedding_dim = shape[1] as usize;
    
    let mut vectors = Vec::new();
    for i in 0..batch_size {
        let start = i * embedding_dim;
        let end = start + embedding_dim;
        vectors.push(data[start..end].to_vec());
    }
    
    Ok(vectors)
}
