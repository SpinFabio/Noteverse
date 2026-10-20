# Start Noteverse

Prerequisites: Docker with Compose, Python 3.12, uv, Flutter stable, Chrome,
GNU Make, and Bash 4.3 or later.

From the project root, create the environment file if it does not exist:

```bash
cp .env.example .env
```

Start Neo4j in Docker and the backend and frontend locally:

```bash
make dev-all-up
```

Open http://localhost:3000. Press Ctrl+C to stop the local frontend and backend.
Neo4j remains running. To stop it:

```bash
make services-down
```

## Start each component separately

Start Neo4j:

```bash
make services-up
```

In a second terminal, start the backend with reload:

```bash
make be-up
```

In a third terminal, start Flutter web:

```bash
make fe-up
```

The backend reads the root `.env`, including `BACKEND_PORT` and the Neo4j credentials.
If you change `BACKEND_PORT`, pass the matching URL when starting the frontend:

```bash
make fe-up API_BASE_URL=http://localhost:8001
```

To use a different frontend port, update `CORS_ORIGINS` in `.env` to allow its origin,
then run:

```bash
make fe-up FE_PORT=3001
```

Show available commands:

```bash
make help
```
