.PHONY: run build test clean ingest-samples query eval

# Build the project
build:
	cargo build --release

# Run the server
run:
	cargo run --release

# Run in development mode
dev:
	cargo run

# Test the project
test:
	cargo test

# Clean build artifacts
clean:
	cargo clean

# Ingest sample documents
ingest-samples:
	cargo run --release -- ingest samples/

# Query with specific text
query:
	@if [ -z "$(Q)" ]; then \
		echo "Usage: make query Q=\"your query text\""; \
		exit 1; \
	fi
	cargo run --release -- query "$(Q)"

# Run evaluation
eval:
	cargo run --release -p eval -- --file eval/queries.jsonl

# Install dependencies
deps:
	cargo build

# Format code
fmt:
	cargo fmt

# Lint code
lint:
	cargo clippy

# Check for security vulnerabilities
audit:
	cargo audit

# Generate documentation
doc:
	cargo doc --open

# Create release build
release: clean build
	@echo "Release build complete"

# Help
help:
	@echo "Available targets:"
	@echo "  build        - Build the project"
	@echo "  run          - Run the server"
	@echo "  dev          - Run in development mode"
	@echo "  test         - Run tests"
	@echo "  clean        - Clean build artifacts"
	@echo "  ingest-samples - Ingest sample documents"
	@echo "  query        - Query with text (Q=\"your query\")"
	@echo "  eval         - Run evaluation"
	@echo "  deps         - Install dependencies"
	@echo "  fmt          - Format code"
	@echo "  lint         - Lint code"
	@echo "  audit        - Check for security vulnerabilities"
	@echo "  doc          - Generate documentation"
	@echo "  release      - Create release build"
	@echo "  help         - Show this help"
