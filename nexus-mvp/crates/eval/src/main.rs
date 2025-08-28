use anyhow::Result;
use clap::Parser;
use std::path::PathBuf;
use std::time::Instant;
use tracing::info;
use types::AppConfig;

use models::ModelManager;
use retrieval::HybridIndex;
use storage::StorageManager;

#[derive(Parser)]
#[command(name = "eval")]
#[command(about = "Evaluation harness for MyAI MVP")]
struct Cli {
    #[arg(short, long)]
    file: PathBuf,
    
    #[arg(short, long, default_value = "config/default.toml")]
    config: PathBuf,
}

#[derive(serde::Deserialize)]
struct EvalQuery {
    query: String,
    expected_docs: Vec<String>,
}

#[tokio::main]
async fn main() -> Result<()> {
    // Initialize tracing
    tracing_subscriber::fmt()
        .with_env_filter(tracing_subscriber::EnvFilter::from_default_env())
        .init();
    
    let cli = Cli::parse();
    
    // Load configuration
    let config = load_config(&cli.config)?;
    
    // Initialize components
    let models = ModelManager::new(&config).await?;
    let storage = StorageManager::new(&config.paths.data_dir).await?;
    let index = HybridIndex::new(storage, models, config).await?;
    
    // Load evaluation queries
    let queries = load_queries(&cli.file).await?;
    
    info!("Running evaluation on {} queries", queries.len());
    
    let mut total_latency = 0;
    let mut total_precision = 0.0;
    let mut total_recall = 0.0;
    
    for (i, eval_query) in queries.iter().enumerate() {
        info!("Query {}: {}", i + 1, eval_query.query);
        
        let start_time = Instant::now();
        
        let request = types::QueryRequest {
            query: eval_query.query.clone(),
            k: 10,
            date_from: None,
            date_to: None,
            filters: None,
            stream: false,
        };
        
        let (hits, _reasoning) = index.search(&request).await?;
        
        let latency = start_time.elapsed().as_millis() as u64;
        total_latency += latency;
        
        // Calculate precision and recall
        let retrieved_docs: Vec<String> = hits.iter().map(|h| h.doc_id.clone()).collect();
        let precision = calculate_precision(&retrieved_docs, &eval_query.expected_docs);
        let recall = calculate_recall(&retrieved_docs, &eval_query.expected_docs);
        
        total_precision += precision;
        total_recall += recall;
        
        info!("  Latency: {}ms", latency);
        info!("  Precision@10: {:.3}", precision);
        info!("  Recall@10: {:.3}", recall);
        info!("  Retrieved: {:?}", retrieved_docs);
        info!("  Expected: {:?}", eval_query.expected_docs);
    }
    
    let avg_latency = total_latency / queries.len() as u64;
    let avg_precision = total_precision / queries.len() as f32;
    let avg_recall = total_recall / queries.len() as f32;
    
    info!("=== EVALUATION RESULTS ===");
    info!("Average Latency: {}ms", avg_latency);
    info!("Average Precision@10: {:.3}", avg_precision);
    info!("Average Recall@10: {:.3}", avg_recall);
    info!("F1 Score: {:.3}", 2.0 * avg_precision * avg_recall / (avg_precision + avg_recall));
    
    Ok(())
}

fn load_config(config_path: &PathBuf) -> Result<AppConfig> {
    if config_path.exists() {
        let config_content = std::fs::read_to_string(config_path)?;
        let config: AppConfig = toml::from_str(&config_content)?;
        Ok(config)
    } else {
        Ok(AppConfig::default())
    }
}

async fn load_queries(path: &PathBuf) -> Result<Vec<EvalQuery>> {
    let content = tokio::fs::read_to_string(path).await?;
    let mut queries = Vec::new();
    
    for line in content.lines() {
        if !line.trim().is_empty() {
            let query: EvalQuery = serde_json::from_str(line)?;
            queries.push(query);
        }
    }
    
    Ok(queries)
}

fn calculate_precision(retrieved: &[String], expected: &[String]) -> f32 {
    if retrieved.is_empty() {
        return 0.0;
    }
    
    let relevant_retrieved = retrieved.iter()
        .filter(|doc| expected.contains(doc))
        .count();
    
    relevant_retrieved as f32 / retrieved.len() as f32
}

fn calculate_recall(retrieved: &[String], expected: &[String]) -> f32 {
    if expected.is_empty() {
        return 0.0;
    }
    
    let relevant_retrieved = retrieved.iter()
        .filter(|doc| expected.contains(doc))
        .count();
    
    relevant_retrieved as f32 / expected.len() as f32
}
