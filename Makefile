SHELL := /bin/bash
.DEFAULT_GOAL := help

FE_PORT ?= 3000
API_BASE_URL ?= http://localhost:8000

.PHONY: help services-up services-down be-up fe-up dev-all-up check

help:
	@echo "make services-up    Start Neo4j in Docker and wait until healthy"
	@echo "make services-down  Stop Neo4j without deleting its data"
	@echo "make be-up          Start the local backend with reload (uv)"
	@echo "make fe-up          Start the local Flutter web frontend"
	@echo "make dev-all-up     Start Neo4j and local BE/FE; Ctrl+C stops BE/FE"
	@echo "make check          Run backend API tests/lint and Flutter checks"
	@echo "Frontend overrides: FE_PORT=3000 API_BASE_URL=http://localhost:8000"

services-up:
	docker compose up -d --wait neo4j

services-down:
	docker compose stop neo4j

be-up:
	cd backend && uv run --env-file ../.env python -c 'import os, uvicorn; os.environ.setdefault("NEO4J_URI", "bolt://localhost:" + os.getenv("NEO4J_BOLT_PORT", "7687")); uvicorn.run("app.main:create_app", factory=True, reload=True, host="127.0.0.1", port=int(os.getenv("BACKEND_PORT", "8000")))'

fe-up:
	cd frontend && flutter run -d chrome --web-port $(FE_PORT) --dart-define=API_BASE_URL=$(API_BASE_URL)

# Separate process groups include reload/browser children in cleanup. Neo4j stays running.
# Job control and wait -n require Bash; this launcher targets Linux/macOS with Bash 4.3+.
dev-all-up: services-up
	@set -m; \
	be_pid=; fe_pid=; \
	cleanup() { \
		trap '' INT TERM; \
		for pid in $$be_pid $$fe_pid; do kill -TERM -- -$$pid 2>/dev/null || true; done; \
		wait $$be_pid $$fe_pid 2>/dev/null || true; \
	}; \
	trap cleanup EXIT; \
	trap 'exit 130' INT; \
	trap 'exit 143' TERM; \
	$(MAKE) be-up & be_pid=$$!; \
	$(MAKE) fe-up & fe_pid=$$!; \
	wait -n $$be_pid $$fe_pid

check:
	cd backend && uv run ruff check . && uv run pytest
	cd frontend && flutter analyze && flutter test
