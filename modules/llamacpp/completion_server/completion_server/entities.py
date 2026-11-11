from pydantic import BaseModel


class CompletionRequest(BaseModel):
    model: str
    prompt: str
    suffix: str | None = None
    max_tokens: int = 100
    temperature: float = 0.2
    top_p: float = 0.95
    top_k: int = 40
    stream: bool = False
    stop: list[str] | None = None
    n_ctx: int = 4096
