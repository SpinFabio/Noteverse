import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from neo4j import GraphDatabase
from neo4j.exceptions import Neo4jError, ServiceUnavailable, SessionExpired
from pydantic import BaseModel, Field

from app.config import Settings

logger = logging.getLogger(__name__)


class HelloResponse(BaseModel):
    message: str = Field(description="Greeting displayed by the setup test screen.")


def create_app(settings: Settings | None = None) -> FastAPI:
    settings = settings or Settings()

    @asynccontextmanager
    async def lifespan(app: FastAPI):
        settings.pages_dir.mkdir(parents=True, exist_ok=True)
        driver = GraphDatabase.driver(
            settings.neo4j_uri,
            auth=(settings.neo4j_user, settings.neo4j_password.get_secret_value()),
            connection_timeout=settings.neo4j_connection_timeout,
            connection_acquisition_timeout=settings.neo4j_connection_timeout,
        )
        app.state.driver = driver
        try:
            yield
        finally:
            driver.close()

    app = FastAPI(title=settings.app_name, version="0.1.0", lifespan=lifespan)
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE"],
        allow_headers=["Content-Type"],
    )

    @app.get("/api/hello", response_model=HelloResponse)
    def hello():
        return HelloResponse(message="Hello from Noteverse!")

    @app.get("/health/live")
    def live():
        return {"status": "ok"}

    @app.get("/health/ready")
    def ready(request: Request):
        try:
            with request.app.state.driver.session(
                database=settings.neo4j_database
            ) as session:
                session.run("RETURN 1 AS ok").consume()
        except (Neo4jError, ServiceUnavailable, SessionExpired):
            logger.exception("Neo4j readiness check failed")
            return JSONResponse(
                status_code=503,
                content={"status": "unavailable", "neo4j": "unavailable"},
            )
        return {"status": "ok", "neo4j": "ok"}

    return app
