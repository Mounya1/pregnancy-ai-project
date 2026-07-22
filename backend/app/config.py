"""
Central config. All secrets come from environment variables (.env),
never hardcoded. Copy .env.example to .env and fill in your keys.
"""
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    openai_api_key: str = ""
    chat_model: str = "gpt-4o"
    vision_model: str = "gpt-4o"
    embedding_model: str = "text-embedding-3-small"
    tts_model: str = "tts-1"
    stt_model: str = "whisper-1"

    database_url: str = "postgresql://user:password@localhost:5432/pregnancy_ai"

    vector_store_path: str = "./vector_store"

    class Config:
        env_file = ".env"


settings = Settings()
