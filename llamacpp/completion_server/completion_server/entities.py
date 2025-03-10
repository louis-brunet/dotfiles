from typing import Optional
from pydantic import BaseModel


class CompletionRequest(BaseModel):
    model: str
    prompt: str
    suffix: Optional[str] = None
    max_tokens: int = 100
    temperature: float = 0.2
    top_p: float = 0.95
    top_k: int = 40
    stream: bool = False
    stop: Optional[list[str]] = None
    n_ctx: int = 4096
