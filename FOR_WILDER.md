# MyAI MVP Audit Report

## A) Executive Summary

MyAI MVP is a **privacy-first personal AGI** built with Rust backend and Flutter frontend. The project implements a **hybrid dense retrieval system** (BM25 + HNSW + reranking) targeting <300ms query latency. The architecture follows a modular crate design with SQLite storage, Tantivy BM25 indexing, and ONNX model integration.

**Implementation Status**: ~75% complete with solid foundations but missing key components.

**Core Strengths**: Well-structured workspace, comprehensive HTTP API with OpenAPI docs, functional hybrid search pipeline, proper async/await throughout, config-driven parameters.

**Critical Gaps**: HNSW persistence not implemented, PDF/Markdown handlers are stubs, directory ingestion missing, no SQLCipher integration, eval harness incomplete (no queries.jsonl), streaming SSE not wired to search stages.

**Risk Level**: MEDIUM - Core functionality works but production readiness requires addressing persistence, file handlers, and security features. Models are external dependencies requiring manual setup.

**Estimated Completion**: 2-3 weeks for MVP compliance, assuming dedicated development effort.

## B) File Tree

```
myai-mvp/
├── Cargo.toml                     # Workspace (7 crates) + shared deps
├── src/main.rs                    # CLI entry point, server runner
├── config/default.toml            # Runtime configuration
├── Makefile                       # Build automation (11 targets)
├── samples/
│   ├── sample1.txt                # Sample meeting notes
│   └── sample2.txt                # Sample visa document
└── crates/
    ├── types/src/lib.rs           # DTOs, Config, API types (264 lines)
    ├── server/src/lib.rs          # Axum router, OpenAPI, handlers (214 lines)
    ├── retrieval/src/lib.rs       # HybridIndex, search pipeline (254 lines)
    ├── models/
    │   ├── src/lib.rs             # ModelManager, ONNX session utils (115 lines)
    │   ├── src/embedding.rs       # MiniLM-L6-v2 embedder (111 lines)
    │   └── src/reranker.rs        # BGE-small cross-encoder (102 lines)
    ├── storage/
    │   ├── src/lib.rs             # StorageManager coordinator (87 lines)
    │   ├── src/database.rs        # SQLite CRUD operations (186 lines)
    │   ├── src/tantivy_store.rs   # BM25 indexing via Tantivy (90 lines)
    │   └── src/hnsw_store.rs      # Vector search via hnsw_rs (104 lines)
    ├── ingest/
    │   ├── src/lib.rs             # IngestPipeline orchestrator (162 lines)
    │   ├── src/chunker.rs         # Text chunking with overlap (71 lines)
    │   └── src/handlers.rs        # File type handlers (41 lines)
    └── eval/src/main.rs           # Evaluation harness (149 lines)
```

**Key Public APIs by Crate:**
- **types**: `QueryRequest`, `QueryResponse`, `AppConfig`, `SearchHit`, `ReasoningTrace`
- **server**: `create_app()`, `AppState`
- **retrieval**: `HybridIndex::new()`, `::search()`, `::add_document()`, `::add_chunk()`
- **models**: `ModelManager::new()`, `EmbeddingModel`, `RerankerModel`
- **storage**: `StorageManager::new()`, `::search_bm25()`, `::search_ann()`
- **ingest**: `IngestPipeline::new()`, `::ingest_path()`, `::ingest_text()`

## C) API Endpoints (Found vs. Spec)

**Registered in Axum Router** (server/src/lib.rs:58-64):
- ✅ POST `/api/query` → `query()` handler
- ✅ POST `/api/ingest/file` → `ingest_file()` multipart handler  
- ✅ POST `/api/ingest/text` → `ingest_text()` JSON handler
- ✅ GET `/api/status` → `status()` stats handler
- ✅ GET `/ws/progress` → `progress_websocket()` SSE stream
- ✅ GET `/docs` → Swagger UI (utoipa integration)

**Compliance vs. MVP Spec**:
- ✅ All required endpoints present
- ✅ OpenAPI documentation auto-generated
- ✅ CORS configured (though currently wide-open)
- 🟡 SSE streaming exists but not connected to search stages
- ✅ Multipart file upload working
- ✅ JSON request/response formats match spec

## D) Models & Assets

**Expected Locations** (`~/.myai-mvp/models/`):
- `all-MiniLM-L6-v2.onnx` - MiniLM embedder (384-dim)
- `all-MiniLM-L6-v2-tokenizer.json` - Tokenizer for embedder
- `bge-small-cross-encoder.onnx` - BGE reranker  
- `bge-small-tokenizer.json` - Tokenizer for reranker

**Loading Logic**:
- `models/src/embedding.rs:18-50` - Model existence checks with clear error messages
- `models/src/reranker.rs:16-41` - Same pattern for reranker
- **Missing**: No auto-download, requires manual wget setup per README
- **Missing**: No model version validation or checksums

**ONNX Runtime Configuration**:
- CPU-only execution provider (models/src/lib.rs:53)
- Session optimization level 1
- Models loaded at startup, not lazy-loaded

## E) Retrieval Pipeline (BM25→ANN→Hybrid→Rerank)

**Complete Implementation** in `retrieval/src/lib.rs:46-213`:

1. **BM25 Stage** (lines 56-63):
   - `storage.search_bm25(query, rerank_top)` 
   - Uses Tantivy full-text search
   - Returns `Vec<(chunk_id, bm25_score)>`

2. **ANN Stage** (lines 66-82):
   - Query embedding via `models.embedder.embed([query])`
   - `storage.search_ann(embedding, rerank_top)`
   - HNSW nearest neighbor search
   - Returns `Vec<(chunk_id, ann_score)>`

3. **Hybrid Union** (lines 85-120):
   - Combines BM25 + ANN results in HashMap
   - Hybrid score = `alpha * bm25_score + beta * ann_score`
   - Configurable α=0.35, β=0.65 weights
   - Sorts by hybrid score, takes top `rerank_top`

4. **Reranking** (lines 128-147):
   - Fetches full chunk text for candidates
   - Cross-encoder reranking via BGE-small
   - `models.reranker.rerank(query, chunk_pairs)`
   - Final ranking by rerank scores

5. **Snippet Generation** (lines 215-252):
   - Simple keyword-based snippet extraction
   - 200-char window around best matching term
   - Adds ellipsis for truncation

**Performance**: Reasoning trace captures per-stage timings, total latency logged.

## F) Config Surface (All Tunables)

**File**: `config/default.toml`, overridable via `~/.myai-mvp/config.toml`

**Paths**:
- `dataDir = "~/.myai-mvp/data"` - SQLite, Tantivy, HNSW storage
- `modelDir = "~/.myai-mvp/models"` - ONNX model files
- `watchPaths = []` - File system watch (unused)

**API**:
- `bind = "127.0.0.1:7777"` - Server bind address
- `corsOrigins = ["http://localhost:3000", "http://localhost:8080"]`

**Retrieval**:
- `bm25K1 = 1.2` - BM25 term frequency saturation
- `annEf = 100` - HNSW search parameter (accuracy vs speed)
- `annM = 16` - HNSW graph connectivity
- `alpha = 0.35` - BM25 weight in hybrid scoring
- `beta = 0.65` - ANN weight in hybrid scoring
- `rerankTop = 50` - Candidates sent to reranker
- `finalTop = 10` - Results returned to user

**Privacy**:
- `enableSqlcipher = false` - Database encryption (not implemented)
- `maxFileMb = 500` - File size limit
- `allowedMimeGroups = ["pdf", "text"]` - MIME type allowlist

**Ingest**:
- `chunkSize = 800` - Characters per chunk
- `overlap = 120` - Overlapping characters between chunks

## G) Gaps & Risks (Prioritized)

### CRITICAL (Blocks MVP)

1. **HNSW Persistence Missing** (`storage/src/hnsw_store.rs:92,99`)
   - HNSW index rebuilds from scratch on restart
   - No save/load implementation
   - Data loss risk on server restart

2. **PDF Handler Stub** (`ingest/src/handlers.rs:37`)
   - Returns placeholder text instead of extraction
   - Breaks PDF ingestion workflow
   - Missing pdf-extract or similar dependency

3. **Markdown Handler Incomplete** (`ingest/src/handlers.rs:26`)
   - Raw markdown returned, no plain text conversion
   - Affects search quality for .md files

### HIGH (Production Readiness)

4. **Directory Ingestion Missing** (`src/main.rs:134`)
   - CLI supports file-only ingestion
   - No bulk directory processing
   - Manual file-by-file workflow

5. **SQLCipher Not Implemented**
   - Config flag exists but no encryption logic
   - Privacy promise unfulfilled
   - Requires rusqlite feature flag + key management

6. **Eval Harness Incomplete**
   - `eval/` crate exists but no `queries.jsonl` file
   - Cannot run `make eval` target
   - No benchmark baseline

### MEDIUM (Nice to Have)

7. **SSE Streaming Disconnected**
   - WebSocket endpoint exists but reasoning stages don't stream
   - Partial results not sent during search
   - UX degradation for slow queries

8. **Uptime Tracking Missing** (`server/src/lib.rs:193`)
   - Status endpoint returns uptime=0
   - Basic monitoring gap

9. **Config Path Inconsistency**
   - Default path uses `~/.nexus-mvp/` in types/src/lib.rs:188
   - Should be `~/.myai-mvp/` for branding consistency

## H) Diff Against Spec

| Feature | Status | File(s) | Notes |
|---------|--------|---------|-------|
| **Fast hybrid retrieval <300ms** | ✅ | retrieval/src/lib.rs | Implemented, performance logging |
| **Local-only storage** | ✅ | storage/src/database.rs | SQLite working |
| **Optional SQLCipher encryption** | ❌ | N/A | Flag exists, no implementation |
| **TXT/PDF ingest** | 🟡 | ingest/src/handlers.rs | TXT works, PDF stub |
| **Chunking (800/120)** | ✅ | ingest/src/chunker.rs | Configurable, sentence boundaries |
| **BM25 + HNSW indexing** | 🟡 | storage/src/ | Works but HNSW not persistent |
| **POST /api/query** | ✅ | server/src/lib.rs:80 | JSON, temporal filters supported |
| **POST /api/ingest/file** | ✅ | server/src/lib.rs:113 | Multipart upload |
| **POST /api/ingest/text** | ✅ | server/src/lib.rs:160 | JSON text ingestion |
| **GET /api/status** | ✅ | server/src/lib.rs:183 | Doc/chunk counts |
| **WS /ws/progress** | 🟡 | server/src/lib.rs:199 | Endpoint exists, not connected |
| **SSE streaming per stage** | ❌ | N/A | Reasoning trace exists, no streaming |
| **MiniLM embeddings (ONNX)** | ✅ | models/src/embedding.rs | 384-dim, working |
| **BGE-small reranker (ONNX)** | ✅ | models/src/reranker.rs | Cross-encoder working |
| **SQLite schema** | ✅ | storage/src/database.rs:23-47 | Documents + chunks tables |
| **Tantivy under data/tantivy** | ✅ | storage/src/tantivy_store.rs:25 | BM25 indexing |
| **HNSW under data/hnsw** | 🟡 | storage/src/hnsw_store.rs:18 | In-memory only |
| **Config overrides** | ✅ | src/main.rs:50,62 | TOML loading |
| **Flutter-ready CORS** | ✅ | server/src/lib.rs:53 | Wide-open currently |
| **Swagger at /docs** | ✅ | server/src/lib.rs:64 | OpenAPI auto-gen |
| **Makefile targets** | ✅ | Makefile | All required targets |
| **Basic unit/integration tests** | ❌ | N/A | No test files found |
| **Eval harness (queries.jsonl)** | 🟡 | eval/src/main.rs | Code exists, no test data |

## I) Actionable Task List

### MUST for MVP (Estimated: 1-2 weeks)

**HNSW Persistence** (Owner: TBD, Size: L, Deps: None)
- Implement `HnswStore::save()` and `::load()` methods
- Add HNSW serialization to disk on index updates
- Load existing index on startup to prevent rebuilds
- Files: `storage/src/hnsw_store.rs:92-102`

**PDF Text Extraction** (Owner: TBD, Size: M, Deps: pdf-extract crate)
- Add `pdf-extract` or `lopdf` dependency to `Cargo.toml`
- Implement actual text extraction in `PdfHandler::extract_text()`
- Handle extraction errors gracefully
- Files: `ingest/src/handlers.rs:35-39`, `Cargo.toml`

**SQLCipher Integration** (Owner: TBD, Size: M, Deps: None)
- Add "sqlcipher" feature to rusqlite dependency
- Implement encryption key derivation and storage
- Wire `PrivacyConfig::enable_sqlcipher` to database creation
- Files: `storage/src/database.rs:17-20`, `Cargo.toml`

**Directory Ingestion** (Owner: TBD, Size: S, Deps: None)
- Implement recursive directory walking in `ingest_path()`
- Add file filtering by allowed MIME types
- Batch processing with progress reporting
- Files: `src/main.rs:134-138`

### SHOULD (Estimated: 1 week)

**Evaluation Test Data** (Owner: TBD, Size: S, Deps: None)
- Create `eval/queries.jsonl` with sample queries and expected results
- Add benchmark targets to Makefile
- Document evaluation methodology
- Files: `eval/queries.jsonl` (new), `Makefile:37`

**SSE Streaming Integration** (Owner: TBD, Size: M, Deps: None)
- Connect search pipeline stages to progress broadcast
- Send reasoning stage events through WebSocket
- Add streaming flag handling in search logic
- Files: `retrieval/src/lib.rs:186-210`, `server/src/lib.rs:199-213`

**Markdown Plain Text** (Owner: TBD, Size: S, Deps: pulldown-cmark)
- Add markdown parsing dependency
- Convert markdown to plain text for better search
- Preserve structure in metadata
- Files: `ingest/src/handlers.rs:23-28`

**Security Hardening** (Owner: TBD, Size: M, Deps: None)
- Implement path traversal protection in file handlers
- Restrict CORS origins to config values
- Add request size limits and timeouts
- Files: `server/src/lib.rs:53-56`, `ingest/src/handlers.rs`

### NICE LATER (Estimated: 2+ weeks)

**Advanced Chunking** (Owner: TBD, Size: L, Deps: NLP libraries)
- Semantic boundary detection
- Table/list preservation
- Multi-column PDF handling
- Files: `ingest/src/chunker.rs`

**Model Auto-Download** (Owner: TBD, Size: M, Deps: HTTP client)
- Download models from HuggingFace on first run
- Verify checksums and versions
- Graceful fallback and caching
- Files: `models/src/lib.rs`, `models/src/embedding.rs`

**Real-time File Watching** (Owner: TBD, Size: L, Deps: notify crate)
- Monitor `watchPaths` for file changes
- Auto-ingest new/modified files
- Incremental index updates
- Files: New crate `watch/`

**GraphRAG Integration** (Owner: TBD, Size: XL, Deps: Graph databases)
- Entity extraction and linking
- Knowledge graph construction
- Graph-aware retrieval
- Files: New crate `knowledge/`

---

**Report Generated**: $(date)  
**Total Implementation**: ~75% complete  
**Critical Path**: HNSW persistence → PDF extraction → SQLCipher  
**MVP Target**: 2-3 weeks with focused development effort
