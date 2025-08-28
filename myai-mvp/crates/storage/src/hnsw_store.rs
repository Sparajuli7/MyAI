use anyhow::Result;
use hnsw_rs::{Hnsw, Searcher};
use std::path::Path;
use std::sync::Arc;
use tokio::sync::Mutex;
use tracing::info;

pub struct HnswStore {
    hnsw: Arc<Mutex<Hnsw<f32, u32>>>,
    searcher: Arc<Mutex<Searcher<f32, u32>>>,
    id_to_index: Arc<Mutex<std::collections::HashMap<String, u32>>>,
    index_to_id: Arc<Mutex<std::collections::HashMap<u32, String>>>,
    next_index: Arc<Mutex<u32>>,
}

impl HnswStore {
    pub async fn new(data_dir: &str) -> Result<Self> {
        let hnsw_path = Path::new(data_dir).join("hnsw");
        info!("Initializing HNSW index at {:?}", hnsw_path);
        
        // HNSW parameters
        let dim = 384; // MiniLM-L6-v2 dimension
        let max_nb_connection = 16;
        let nb_layer = 16;
        let ef_c = 100;
        let ef_s = 50;
        
        let hnsw = Hnsw::<f32, u32>::new(
            max_nb_connection,
            nb_layer,
            dim,
            ef_c,
            ef_s,
        );
        
        let searcher = Searcher::default();
        
        info!("HNSW index initialized successfully (dim: {})", dim);
        
        Ok(Self {
            hnsw: Arc::new(Mutex::new(hnsw)),
            searcher: Arc::new(Mutex::new(searcher)),
            id_to_index: Arc::new(Mutex::new(std::collections::HashMap::new())),
            index_to_id: Arc::new(Mutex::new(std::collections::HashMap::new())),
            next_index: Arc::new(Mutex::new(0)),
        })
    }
    
    pub async fn add_vector(&self, id: &str, embedding: &[f32]) -> Result<()> {
        let mut hnsw = self.hnsw.lock().await;
        let mut id_to_index = self.id_to_index.lock().await;
        let mut index_to_id = self.index_to_id.lock().await;
        let mut next_index = self.next_index.lock().await;
        
        // Check if vector already exists
        if let Some(&existing_index) = id_to_index.get(id) {
            // Update existing vector
            hnsw.update_vector(embedding, existing_index)?;
        } else {
            // Add new vector
            let index = *next_index;
            hnsw.insert_vector(embedding, index)?;
            
            id_to_index.insert(id.to_string(), index);
            index_to_id.insert(index, id.to_string());
            *next_index += 1;
        }
        
        Ok(())
    }
    
    pub async fn search(&self, query_embedding: &[f32], limit: usize) -> Result<Vec<(String, f32)>> {
        let hnsw = self.hnsw.lock().await;
        let searcher = self.searcher.lock().await;
        let index_to_id = self.index_to_id.lock().await;
        
        let search_result = searcher.search(&hnsw, query_embedding, limit, None)?;
        
        let mut results = Vec::new();
        for (index, distance) in search_result {
            if let Some(id) = index_to_id.get(&index) {
                // Convert distance to similarity score (1 - normalized distance)
                let similarity = 1.0 - (distance / query_embedding.len() as f32).min(1.0);
                results.push((id.clone(), similarity));
            }
        }
        
        Ok(results)
    }
    
    pub async fn save(&self, _path: &Path) -> Result<()> {
        // TODO: Implement HNSW persistence
        // For now, we'll rebuild the index on restart
        info!("HNSW save not implemented yet - will rebuild on restart");
        Ok(())
    }
    
    pub async fn load(&self, _path: &Path) -> Result<()> {
        // TODO: Implement HNSW loading
        info!("HNSW load not implemented yet - starting with empty index");
        Ok(())
    }
}
