from pathlib import Path

from pydantic import Field, SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    app_name: str = "Noteverse"
    data_dir: Path = Path(__file__).resolve().parents[1] / "data"
    cors_origins: list[str] = ["http://localhost:3000"]
    neo4j_uri: str = "bolt://localhost:7687"
    neo4j_user: str = "neo4j"
    neo4j_password: SecretStr
    neo4j_database: str = "neo4j"
    neo4j_connection_timeout: float = Field(default=5, gt=0)

    @property
    def pages_dir(self) -> Path:
        return self.data_dir / "pages"
