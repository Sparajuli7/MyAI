use anyhow::Result;
use std::path::Path;
use std::sync::Arc;
use tantivy::{
    collector::TopDocs,
    doc,
    query::{QueryParser, TermQuery},
    schema::{Field, Schema, STORED, TEXT},
    Document, Index, IndexReader, IndexWriter, Term,
};
use tokio::sync::Mutex;
use tracing::info;
use types::Chunk;

pub struct TantivyStore {
    index: Arc<Index>,
    writer: Mutex<IndexWriter>,
    reader: IndexReader,
    text_field: Field,
    id_field: Field,
}

impl TantivyStore {
    pub async fn new(data_dir: &str) -> Result<Self> {
        let index_path = Path::new(data_dir).join("tantivy");
        info!("Opening Tantivy index at {:?}", index_path);
        
        let mut schema_builder = Schema::builder();
        let text_field = schema_builder.add_text_field("text", TEXT | STORED);
        let id_field = schema_builder.add_text_field("id", STORED);
        let schema = schema_builder.build();
        
        let index = if index_path.exists() {
            Index::open_in_dir(&index_path)?
        } else {
            Index::create_in_dir(&index_path, schema)?
        };
        
        let writer = index.writer(50_000_000)?; // 50MB buffer
        let reader = index.reader()?;
        
        info!("Tantivy index initialized successfully");
        
        Ok(Self {
            index: Arc::new(index),
            writer: Mutex::new(writer),
            reader,
            text_field,
            id_field,
        })
    }
    
    pub async fn index_chunk(&self, chunk: &Chunk) -> Result<()> {
        let mut writer = self.writer.lock().await;
        
        let doc = doc!(
            self.text_field => chunk.text.clone(),
            self.id_field => chunk.id.clone(),
        );
        
        // Delete existing document with same ID if it exists
        let term = Term::from_field_text(self.id_field, &chunk.id);
        writer.delete_term(term);
        
        // Add new document
        writer.add_document(doc)?;
        writer.commit()?;
        
        Ok(())
    }
    
    pub async fn search(&self, query: &str, limit: usize) -> Result<Vec<(String, f32)>> {
        let searcher = self.reader.searcher();
        let query_parser = QueryParser::for_index(&self.index, vec![self.text_field]);
        let query = query_parser.parse_query(query)?;
        
        let top_docs = searcher.search(&query, &TopDocs::with_limit(limit))?;
        
        let mut results = Vec::new();
        for (score, doc_address) in top_docs {
            let doc = searcher.doc(doc_address)?;
            if let Some(id) = doc.get_first(self.id_field).and_then(|v| v.as_text()) {
                results.push((id.to_string(), score));
            }
        }
        
        Ok(results)
    }
}
