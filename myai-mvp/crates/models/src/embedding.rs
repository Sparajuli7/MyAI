use anyhow::Result;
use ort::{Session, Value};
use std::path::Path;
use tokenizers::Tokenizer;
use tracing::info;
use types::Chunk;

use crate::{create_session, output_to_vectors, pad_sequences, tokenize_texts, Embedder};

pub struct EmbeddingModel {
    session: Session,
    tokenizer: Tokenizer,
    embedding_dim: usize,
}

impl EmbeddingModel {
    pub async fn new(model_dir: &str) -> Result<Self> {
        let model_path = Path::new(model_dir).join("all-MiniLM-L6-v2.onnx");
        let tokenizer_path = Path::new(model_dir).join("all-MiniLM-L6-v2-tokenizer.json");
        
        info!("Loading embedding model from {:?}", model_path);
        
        if !model_path.exists() {
            return Err(anyhow::anyhow!(
                "Embedding model not found at {:?}. Please download the ONNX model.",
                model_path
            ));
        }
        
        if !tokenizer_path.exists() {
            return Err(anyhow::anyhow!(
                "Tokenizer not found at {:?}. Please download the tokenizer.",
                tokenizer_path
            ));
        }
        
        let session = create_session(&model_path)?;
        let tokenizer = Tokenizer::from_file(tokenizer_path)?;
        
        // MiniLM-L6-v2 has 384-dimensional embeddings
        let embedding_dim = 384;
        
        info!("Embedding model loaded successfully (dim: {})", embedding_dim);
        
        Ok(Self {
            session,
            tokenizer,
            embedding_dim,
        })
    }
    
    pub fn embedding_dim(&self) -> usize {
        self.embedding_dim
    }
}

impl Embedder for EmbeddingModel {
    async fn embed(&self, texts: &[String]) -> Result<Vec<Vec<f32>>> {
        if texts.is_empty() {
            return Ok(vec![]);
        }
        
        // Tokenize texts
        let tokenized = tokenize_texts(&self.tokenizer, texts)?;
        
        // Pad sequences
        let (input_ids, attention_mask) = pad_sequences(&tokenized, 0);
        
        // Prepare input tensors
        let batch_size = texts.len();
        let seq_len = input_ids.len() / batch_size;
        
        let input_ids_tensor = Value::from_array(
            self.session.allocator(),
            &ndarray::Array2::from_shape_vec(
                (batch_size, seq_len),
                input_ids,
            )?,
        )?;
        
        let attention_mask_tensor = Value::from_array(
            self.session.allocator(),
            &ndarray::Array2::from_shape_vec(
                (batch_size, seq_len),
                attention_mask,
            )?,
        )?;
        
        // Run inference
        let outputs = self.session.run([
            ("input_ids", &input_ids_tensor),
            ("attention_mask", &attention_mask_tensor),
        ])?;
        
        // Extract embeddings (usually the last hidden state)
        let embeddings = outputs[0].clone();
        
        // Convert to vectors
        let vectors = output_to_vectors(embeddings)?;
        
        Ok(vectors)
    }
}

impl EmbeddingModel {
    pub async fn embed_chunks(&self, chunks: &[Chunk]) -> Result<Vec<Vec<f32>>> {
        let texts: Vec<String> = chunks.iter().map(|chunk| chunk.text.clone()).collect();
        self.embed(&texts).await
    }
}
