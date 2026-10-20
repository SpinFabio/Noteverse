from unittest.mock import MagicMock

from fastapi.testclient import TestClient
from neo4j.exceptions import ServiceUnavailable

from app.config import Settings
from app.main import create_app


def test_health_and_storage(tmp_path, monkeypatch):
    driver = MagicMock()
    monkeypatch.setattr("app.main.GraphDatabase.driver", lambda *a, **kw: driver)
    settings = Settings(data_dir=tmp_path, neo4j_password="test-password")
    with TestClient(create_app(settings)) as client:
        assert (tmp_path / "pages").is_dir()
        response = client.get("/api/hello")
        assert response.status_code == 200
        assert response.json() == {"message": "Hello from Noteverse!"}
        assert client.get("/health/live").json() == {"status": "ok"}
        assert client.get("/health/ready").status_code == 200
        driver.session.assert_called_with(database="neo4j")
        driver.session.return_value.__enter__.return_value.run.side_effect = (
            ServiceUnavailable("offline")
        )
        assert client.get("/health/ready").status_code == 503
        assert client.get("/api/hello").status_code == 200
        assert client.get("/health/live").status_code == 200
    driver.close.assert_called_once()
