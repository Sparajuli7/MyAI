use anyhow::Result;
use ort::{Session, Value};
use std::path::Path;
use tokenizers::Tokenizer;
use tracing::info;

use crate::{create_session, pad_sequences, tokenize_texts, Reranker};

pub struct RerankerModel {
    session: Session,
    tokenizer: Tokenizer,
}

impl RerankerModel {
    pub async fn new(model_dir: &str) -> Result<Self> {
        let model_path = Path::new(model_dir).join("bge-small-cross-encoder.onnx");
        let tokenizer_path = Path::new(model_dir).join("bge-small-tokenizer.json");
        
        info!("Loading reranker model from {:?}", model_path);
        
        if !model_path.exists() {
            return Err(anyhow::anyhow!(
                "Reranker model not found at {:?}. Please download the ONNX model.",
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
        
        info!("Reranker model loaded successfully");
        
        Ok(Self { session, tokenizer })
    }
}

impl Reranker for RerankerModel {
    async fn rerank(&self, query: &str, candidates: &[(String, String)]) -> Result<Vec<f32>> {
        if candidates.is_empty() {
            return Ok(vec![]);
        }
        
        // Prepare query-document pairs
        let mut texts = Vec::new();
        for (doc_title, doc_content) in candidates {
            // Combine title and content for reranking
            let combined = format!("{} [SEP] {}", doc_title, doc_content);
            texts.push(format!("{} [SEP] {}", query, combined));
        }
        
        // Tokenize texts
        let tokenized = tokenize_texts(&self.tokenizer, &texts)?;
        
        // Pad sequences
        let (input_ids, attention_mask) = pad_sequences(&tokenized, 0);
        
        // Prepare input tensors
        let batch_size = candidates.len();
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
        
        // Extract scores (usually logits that need to be softmaxed)
        let logits = outputs[0].try_extract::<f32>()?;
        
        // Convert logits to probabilities (simple sigmoid for binary classification)
        let scores: Vec<f32> = logits
            .iter()
            .map(|&logit| 1.0 / (1.0 + (-logit).exp()))
            .collect();
        
        Ok(scores)
    }
}
