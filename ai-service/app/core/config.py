from functools import lru_cache

from pydantic import Field, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")
    internal_service_key: str = Field(min_length=32)
    app_env: str = "local"
    mock_ai_mode: bool = True
    llm_provider: str = "openai"
    llm_api_key: str = ""
    llm_model: str = ""
    emotion_model_name: str = ""
    embedding_model_name: str = "sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2"
    qdrant_url: str = "http://qdrant:6333"
    qdrant_api_key: str = ""
    rag_min_score: float = Field(default=0.65, ge=0, le=1)
    emergency_resource_text: str = ""

    @model_validator(mode="after")
    def live_configuration(self):
        if self.app_env == "production" and self.mock_ai_mode:
            raise ValueError("Mock mode cannot be enabled in production")
        if not self.mock_ai_mode and (not self.llm_api_key or not self.llm_model):
            raise ValueError("Live AI requires LLM_API_KEY and LLM_MODEL")
        return self


@lru_cache
def get_settings() -> Settings:
    return Settings()
