use anyhow::Result;
use std::path::Path;

#[async_trait::async_trait]
pub trait FileHandler: Send + Sync {
    async fn extract_text(&self, path: &Path) -> Result<String>;
}

pub struct TextHandler;

#[async_trait::async_trait]
impl FileHandler for TextHandler {
    async fn extract_text(&self, path: &Path) -> Result<String> {
        let content = tokio::fs::read_to_string(path).await?;
        Ok(content)
    }
}

pub struct MarkdownHandler;

#[async_trait::async_trait]
impl FileHandler for MarkdownHandler {
    async fn extract_text(&self, path: &Path) -> Result<String> {
        let content = tokio::fs::read_to_string(path).await?;
        // For now, just return the raw markdown
        // TODO: Add markdown parsing to extract plain text
        Ok(content)
    }
}

pub struct PdfHandler;

#[async_trait::async_trait]
impl FileHandler for PdfHandler {
    async fn extract_text(&self, path: &Path) -> Result<String> {
        // For now, return a placeholder
        // TODO: Add PDF text extraction using pdf-extract or similar
        Ok(format!("PDF content from {:?} (text extraction not implemented yet)", path))
    }
}
