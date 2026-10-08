FROM python:3.12-slim
WORKDIR /app
COPY ai-service/ /app/
ARG WITH_LOCAL_MODELS=false
RUN pip install --no-cache-dir '.[dev]' && if [ "$WITH_LOCAL_MODELS" = "true" ]; then pip install --no-cache-dir torch --index-url https://download.pytorch.org/whl/cpu && pip install --no-cache-dir '.[ml]'; fi && useradd --create-home app && chown -R app:app /app
USER app
EXPOSE 8001
CMD ["python", "-m", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8001", "--no-access-log"]
