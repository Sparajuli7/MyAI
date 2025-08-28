use axum::{
    extract::{Multipart, Path, State},
    http::{HeaderMap, StatusCode},
    response::{sse::Event, Sse},
    routing::{get, post},
    Json, Router,
};
use futures::stream::{self, Stream};
use std::convert::Infallible;
use std::sync::Arc;
use std::time::Duration;
use tokio::sync::broadcast;
use tower_http::cors::{Any, CorsLayer};
use tracing::{error, info};
use types::{
    ApiError, IngestTextRequest, QueryRequest, QueryResponse, StatusResponse,
};
use utoipa::OpenApi;
use utoipa_swagger_ui::SwaggerUi;

use models::ModelManager;
use retrieval::HybridIndex;
use storage::StorageManager;

#[derive(Clone)]
pub struct AppState {
    pub index: Arc<HybridIndex>,
    pub models: Arc<ModelManager>,
    pub storage: Arc<StorageManager>,
    pub progress_tx: broadcast::Sender<String>,
}

#[derive(OpenApi)]
#[openapi(
    paths(
        query,
        ingest_file,
        ingest_text,
        status,
    ),
    components(
        schemas(QueryRequest, QueryResponse, IngestTextRequest, StatusResponse)
    ),
    tags(
        (name = "search", description = "Search API"),
        (name = "ingest", description = "Ingest API"),
        (name = "status", description = "Status API")
    )
)]
struct ApiDoc;

pub fn create_app(state: AppState) -> Router {
    let cors = CorsLayer::new()
        .allow_origin(Any)
        .allow_methods(Any)
        .allow_headers(Any);

    Router::new()
        .route("/api/query", post(query))
        .route("/api/ingest/file", post(ingest_file))
        .route("/api/ingest/text", post(ingest_text))
        .route("/api/status", get(status))
        .route("/ws/progress", get(progress_websocket))
        .merge(SwaggerUi::new("/docs").url("/api-docs/openapi.json", ApiDoc::openapi()))
        .layer(cors)
        .with_state(state)
}

#[utoipa::path(
    post,
    path = "/api/query",
    request_body = QueryRequest,
    responses(
        (status = 200, description = "Search results", body = QueryResponse),
        (status = 400, description = "Bad request"),
        (status = 500, description = "Internal server error")
    ),
    tag = "search"
)]
async fn query(
    State(state): State<AppState>,
    Json(request): Json<QueryRequest>,
) -> Result<Json<QueryResponse>, ApiError> {
    info!("Processing query: {}", request.query);
    
    let start_time = std::time::Instant::now();
    
    let (hits, reasoning) = state.index.search(&request).await
        .map_err(|e| ApiError::internal(format!("Search failed: {}", e)))?;
    
    let took_ms = start_time.elapsed().as_millis() as u64;
    
    let response = QueryResponse {
        hits,
        reasoning,
        took_ms,
    };
    
    Ok(Json(response))
}

#[utoipa::path(
    post,
    path = "/api/ingest/file",
    request_body(content = Vec<u8>, content_type = "multipart/form-data"),
    responses(
        (status = 200, description = "File ingested successfully"),
        (status = 400, description = "Bad request"),
        (status = 500, description = "Internal server error")
    ),
    tag = "ingest"
)]
async fn ingest_file(
    State(state): State<AppState>,
    mut multipart: Multipart,
) -> Result<Json<types::IngestResult>, ApiError> {
    info!("Processing file upload");
    
    while let Some(field) = multipart.next_field().await
        .map_err(|e| ApiError::bad_request(format!("Multipart error: {}", e)))? {
        
        let filename = field.file_name()
            .ok_or_else(|| ApiError::bad_request("No filename provided"))?
            .to_string();
        
        let data = field.bytes().await
            .map_err(|e| ApiError::bad_request(format!("Failed to read file: {}", e)))?;
        
        // Save to temporary file
        let temp_path = std::env::temp_dir().join(&filename);
        tokio::fs::write(&temp_path, &data).await
            .map_err(|e| ApiError::internal(format!("Failed to save file: {}", e)))?;
        
        // Process the file
        let result = ingest::IngestPipeline::new(types::AppConfig::default())
            .map_err(|e| ApiError::internal(format!("Failed to create ingest pipeline: {}", e)))?
            .ingest_path(&temp_path).await
            .map_err(|e| ApiError::internal(format!("Failed to ingest file: {}", e)))?;
        
        // Clean up temp file
        let _ = tokio::fs::remove_file(&temp_path).await;
        
        return Ok(Json(result));
    }
    
    Err(ApiError::bad_request("No file provided"))
}

#[utoipa::path(
    post,
    path = "/api/ingest/text",
    request_body = IngestTextRequest,
    responses(
        (status = 200, description = "Text ingested successfully"),
        (status = 400, description = "Bad request"),
        (status = 500, description = "Internal server error")
    ),
    tag = "ingest"
)]
async fn ingest_text(
    State(state): State<AppState>,
    Json(request): Json<IngestTextRequest>,
) -> Result<Json<types::IngestResult>, ApiError> {
    info!("Processing text ingest: {}", request.title.as_deref().unwrap_or("Untitled"));
    
    let result = ingest::IngestPipeline::new(types::AppConfig::default())
        .map_err(|e| ApiError::internal(format!("Failed to create ingest pipeline: {}", e)))?
        .ingest_text(&request.text, request.title, request.source).await
        .map_err(|e| ApiError::internal(format!("Failed to ingest text: {}", e)))?;
    
    Ok(Json(result))
}

#[utoipa::path(
    get,
    path = "/api/status",
    responses(
        (status = 200, description = "Server status", body = StatusResponse),
        (status = 500, description = "Internal server error")
    ),
    tag = "status"
)]
async fn status(
    State(state): State<AppState>,
) -> Result<Json<StatusResponse>, ApiError> {
    let (documents, chunks) = state.storage.get_stats().await
        .map_err(|e| ApiError::internal(format!("Failed to get stats: {}", e)))?;
    
    let response = StatusResponse {
        version: env!("CARGO_PKG_VERSION").to_string(),
        documents,
        chunks,
        uptime: 0, // TODO: Track uptime
    };
    
    Ok(Json(response))
}

async fn progress_websocket(
    State(state): State<AppState>,
) -> impl Stream<Item = Result<Event, Infallible>> {
    let mut rx = state.progress_tx.subscribe();
    
    stream::unfold(rx, |mut rx| async move {
        match rx.recv().await {
            Ok(message) => {
                let event = Event::default().data(message);
                Some((Ok(event), rx))
            }
            Err(_) => None,
        }
    })
}
