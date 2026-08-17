"""
Central config. All secrets come from environment variables (.env),
never hardcoded. Copy .env.example to .env and fill in your keys.
"""
from pydantic import field_validator
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    openai_api_key: str = ""

    @field_validator("openai_api_key", mode="after")
    @classmethod
    def _clean_key(cls, value: str) -> str:
        """Strips whitespace and stray quotes from the API key.

        Pasting into a hosting dashboard very often carries a trailing newline
        or wrapping quotes, and OpenAI rejects the result with a bare
        AuthenticationError that looks identical to a wrong key. Cheap to
        defend against, and impossible to debug from the outside.
        """
        return value.strip().strip('"').strip("'")
    chat_model: str = "gpt-4o"
    vision_model: str = "gpt-4o"
    embedding_model: str = "text-embedding-3-small"
    tts_model: str = "tts-1"
    stt_model: str = "whisper-1"

    vector_store_path: str = "./vector_store"

    # Comma-separated list of web origins allowed to call this API, e.g.
    # "https://pregnancy-ai.netlify.app,http://localhost:8080".
    #
    # Default is "*" so a fresh clone works with `flutter run -d chrome`
    # without configuration. Set it to your real origins before going public:
    # a wide-open API with your OpenAI key behind it is somebody else's free
    # inference budget.
    allowed_origins: str = "*"

    @property
    def cors_origins(self) -> list[str]:
        return [o.strip() for o in self.allowed_origins.split(",") if o.strip()]

    class Config:
        env_file = ".env"
        # Ignore env vars we do not declare, rather than refusing to start.
        # Hosts inject their own (PORT, RENDER_*, KOYEB_*), and a leftover
        # line in someone's .env should never take the API down on boot.
        extra = "ignore"


settings = Settings()
