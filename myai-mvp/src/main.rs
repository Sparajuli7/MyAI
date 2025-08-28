use anyhow::Result;
use clap::{Parser, Subcommand};
use std::path::PathBuf;
use std::sync::Arc;
use tokio::signal;
use tokio::sync::broadcast;
use tracing::{error, info, warn};
use types::AppConfig;

use models::ModelManager;
use retrieval::HybridIndex;
use server::{create_app, AppState};
use storage::StorageManager;

#[derive(Parser)]
#[command(name = "myai-mvp")]
#[command(about = "Personal AGI with privacy - Your local-first AI data hub")]
struct Cli {
    #[command(subcommand)]
    command: Option<Commands>,
    
    #[arg(short, long, default_value = "config/default.toml")]
    config: PathBuf,
}

#[derive(Subcommand)]
enum Commands {
    /// Run the server
    Run,
    /// Ingest a file or directory
    Ingest {
        path: PathBuf,
    },
    /// Query the index
    Query {
        text: String,
    },
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
    
    match cli.command {
        Some(Commands::Run) => run_server(config).await?,
        Some(Commands::Ingest { path }) => ingest_path(config, &path).await?,
        Some(Commands::Query { text }) => query_text(config, &text).await?,
        None => run_server(config).await?,
    }
    
    Ok(())
}

fn load_config(config_path: &PathBuf) -> Result<AppConfig> {
    info!("Loading configuration from {:?}", config_path);
    
    if config_path.exists() {
        let config_content = std::fs::read_to_string(config_path)?;
        let config: AppConfig = toml::from_str(&config_content)?;
        info!("Configuration loaded successfully");
        Ok(config)
    } else {
        warn!("Config file not found, using defaults");
        Ok(AppConfig::default())
    }
}

async fn run_server(config: AppConfig) -> Result<()> {
    info!("Starting MyAI MVP - Your Personal AGI with Privacy...");
    info!("🔒 Your data stays private - nothing leaves your device");
    info!("🧠 AI that understands your personal data");
    info!("⚡ Lightning-fast search across all your files");
    
    // Ensure directories exist
    ensure_directories(&config).await?;
    
    // Initialize components
    let models = Arc::new(ModelManager::new(&config).await?);
    let storage = Arc::new(StorageManager::new(&config.paths.data_dir).await?);
    let index = Arc::new(HybridIndex::new(storage.clone(), models.clone(), config.clone()).await?);
    
    // Create progress channel
    let (progress_tx, _) = broadcast::channel(100);
    
    // Create app state
    let state = AppState {
        index,
        models,
        storage,
        progress_tx,
    };
    
    // Create router
    let app = create_app(state);
    
    // Parse bind address
    let bind_addr = config.api.bind.parse()?;
    info!("Server listening on {}", bind_addr);
    
    // Start server
    axum::Server::bind(&bind_addr)
        .serve(app.into_make_service())
        .with_graceful_shutdown(shutdown_signal())
        .await?;
    
    info!("Server shutdown complete");
    Ok(())
}

async fn ingest_path(config: AppConfig, path: &PathBuf) -> Result<()> {
    info!("Ingesting path: {:?}", path);
    
    // Initialize components
    let models = Arc::new(ModelManager::new(&config).await?);
    let storage = Arc::new(StorageManager::new(&config.paths.data_dir).await?);
    let index = Arc::new(HybridIndex::new(storage.clone(), models.clone(), config.clone()).await?);
    
    // Create ingest pipeline
    let pipeline = ingest::IngestPipeline::new(config)?;
    
    if path.is_file() {
        let result = pipeline.ingest_path(path).await?;
        info!("Ingested file: {} chunks, {} skipped, {}ms", 
              result.chunks, result.skipped, result.took_ms);
    } else if path.is_dir() {
        // TODO: Implement directory ingestion
        warn!("Directory ingestion not implemented yet");
    } else {
        return Err(anyhow::anyhow!("Path does not exist: {:?}", path));
    }
    
    Ok(())
}

async fn query_text(config: AppConfig, text: &str) -> Result<()> {
    info!("Querying: {}", text);
    
    // Initialize components
    let models = Arc::new(ModelManager::new(&config).await?);
    let storage = Arc::new(StorageManager::new(&config.paths.data_dir).await?);
    let index = Arc::new(HybridIndex::new(storage.clone(), models.clone(), config.clone()).await?);
    
    // Create query request
    let request = types::QueryRequest {
        query: text.to_string(),
        k: 10,
        date_from: None,
        date_to: None,
        filters: None,
        stream: false,
    };
    
    // Execute search
    let (hits, reasoning) = index.search(&request).await?;
    
    // Print results
    println!("Found {} results:", hits.len());
    for (i, hit) in hits.iter().enumerate() {
        println!("{}. {} (score: {:.3})", i + 1, hit.title, hit.score);
        println!("   {}", hit.snippet);
        println!();
    }
    
    println!("Reasoning trace:");
    for stage in &reasoning.stages {
        println!("  {}: {}ms", stage.stage, stage.elapsed_ms);
    }
    
    Ok(())
}

async fn ensure_directories(config: &AppConfig) -> Result<()> {
    let data_dir = expand_path(&config.paths.data_dir)?;
    let model_dir = expand_path(&config.paths.model_dir)?;
    
    tokio::fs::create_dir_all(&data_dir).await?;
    tokio::fs::create_dir_all(&model_dir).await?;
    
    info!("Directories ensured: {:?}, {:?}", data_dir, model_dir);
    Ok(())
}

fn expand_path(path: &str) -> Result<PathBuf> {
    if path.starts_with("~/") {
        let home = std::env::var("HOME")
            .or_else(|_| std::env::var("USERPROFILE"))
            .map_err(|_| anyhow::anyhow!("Could not determine home directory"))?;
        Ok(PathBuf::from(home).join(&path[2..]))
    } else {
        Ok(PathBuf::from(path))
    }
}

async fn shutdown_signal() {
    let ctrl_c = async {
        signal::ctrl_c()
            .await
            .expect("failed to install Ctrl+C handler");
    };

    #[cfg(unix)]
    let terminate = async {
        signal::unix::signal(signal::unix::SignalKind::terminate())
            .expect("failed to install signal handler")
            .recv()
            .await;
    };

    #[cfg(not(unix))]
    let terminate = std::future::pending::<()>();

    tokio::select! {
        _ = ctrl_c => {},
        _ = terminate => {},
    }

    info!("Shutdown signal received");
}
