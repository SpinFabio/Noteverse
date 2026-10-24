# Getting started

## Prerequisites

- Docker with Docker Compose
- Python 3.12
- uv
- Flutter stable
- Chrome
- GNU Make
- Bash 4.3 or later

## Configure the environment

From the project root, create the environment file if it does not exist:

```bash
cp .env.example .env
```

The backend reads the root `.env`, including `BACKEND_PORT` and the Neo4j
credentials.

## Start the development environment

Start Neo4j in Docker and the backend and frontend as local processes:

```bash
make dev-all-up
```

Open <http://localhost:3000>.

Press Ctrl+C to stop the local frontend and backend processes. Neo4j remains
running. Stop it separately with:

```bash
make services-down
```

## Start each component separately

Start Neo4j:

```bash
make services-up
```

In a second terminal, start the backend with reload enabled:

```bash
make be-up
```

In a third terminal, start the Flutter web client:

```bash
make fe-up
```

## Change local ports

If `BACKEND_PORT` is changed, pass the matching URL when starting the frontend:

```bash
make fe-up API_BASE_URL=http://localhost:8001
```

To use a different frontend port, update `CORS_ORIGINS` in `.env` to allow its
origin, then run:

```bash
make fe-up FE_PORT=3001
```

## List available commands

```bash
make help
```

## Known setup limitation

`[[CONFLICT]]` The `dev-all-up` launcher uses Bash job control and currently
targets Linux and macOS. A supported native Windows workflow has not yet been
defined.
