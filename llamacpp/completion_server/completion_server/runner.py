import multiprocessing
from typing import Callable, Iterator
from llama_cpp import CreateCompletionResponse, CreateCompletionStreamResponse

from completion_server.entities import CompletionRequest


class CompletionRunner:
    def __init__(
        self,
        llm: Callable[
            [CompletionRequest],
            CreateCompletionResponse | Iterator[CreateCompletionStreamResponse],
        ],
        request: CompletionRequest,
        on_result: Callable[
            [CreateCompletionResponse | Iterator[CreateCompletionStreamResponse]], None
        ],
        on_kill: Callable[[], None],
    ):
        self._on_result = on_result
        self._on_kill = on_kill
        self._llm = llm

        self.process = multiprocessing.Process(target=self._run, args=(request,))

    def start(self):
        self.process.start()

    def kill(self):
        self.process.kill()
        self.process.join()
        self._on_kill()

    def _run(self, request: CompletionRequest):
        output = self._llm(request)
        self._on_result(output)
