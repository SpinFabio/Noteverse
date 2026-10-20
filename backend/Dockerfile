FROM python:3.12-slim
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
WORKDIR /app
COPY pyproject.toml uv.lock ./
RUN pip install --no-cache-dir uv==0.9.28 && uv sync --frozen --no-dev
COPY app ./app
RUN useradd --create-home --uid 1000 app && mkdir -p /app/data/pages && chown -R app:app /app/data
USER app
EXPOSE 8000
CMD [".venv/bin/uvicorn", "app.main:create_app", "--factory", "--host", "0.0.0.0", "--port", "8000"]
