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

The backend and the root Makefile read `.env`. Frontend development settings
include `FE_HOST`, `FE_PORT`, and `API_BASE_URL`; backend settings include
`BACKEND_PORT` and the Neo4j credentials.

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

In a third terminal, start the Flutter web client in development mode:

```bash
make fe-up
```

`fe-up` is an alias for the more explicit `fe-dev` target. Development mode
supports hot reload. Use profile mode to investigate rendering performance:

```bash
make fe-profile
```

Use release mode to validate the optimized user experience without profiling
overhead:

```bash
make fe-prod
```

Run only one frontend mode at a time because all three use `FE_PORT`.

## Change local addresses

Edit `.env` to change the frontend development server address or the backend URL:

```dotenv
FE_HOST=127.0.0.1
FE_PORT=3000
API_BASE_URL=http://localhost:8000
```

Values can also be overridden for a single command:

```bash
make fe-up FE_HOST=127.0.0.1 FE_PORT=3001 API_BASE_URL=http://localhost:8001
```

When the frontend origin changes, update `CORS_ORIGINS` in `.env` to allow it.
These commands start local development or validation servers. A deployment uses
a release build and a separate hosting workflow.

## List available commands

```bash
make help
```

## Known setup limitation

`[[CONFLICT]]` The `dev-all-up` launcher uses Bash job control and currently
targets Linux and macOS. A supported native Windows workflow has not yet been
defined.
