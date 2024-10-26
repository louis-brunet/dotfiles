import logging
import multiprocessing
from multiprocessing.synchronize import Event
from typing import Iterator
from llama_cpp import CreateCompletionResponse, CreateCompletionStreamResponse, Llama

from completion_server import model
from completion_server.entities import CompletionRequest


class CompletionRunnerRequest:
    def __init__(
        self,
        request: CompletionRequest,
        response_queue: multiprocessing.Queue[
            CreateCompletionResponse | Iterator[CreateCompletionStreamResponse]
        ],
    ):
        self.request = request
        self.response_queue = response_queue


def _run_completion(
    request_queue: multiprocessing.Queue, stop_accepting_requests_event: Event
):
    logger = logging.getLogger("_run_completion")
    llm: Llama | None = None

    while not stop_accepting_requests_event.is_set():
        request = request_queue.get(block=True, timeout=None)

        if not isinstance(request, CompletionRunnerRequest):
            logger.error(f"Unexpected request type: {type(request)}")
            continue

        req = request.request
        logger.info(f"Processing request: {req}")

        if llm is None:
            # TODO: or if requested different model or different model params (ctx)
            llm = model.load_model(model_name_or_alias=req.model, n_ctx=req.n_ctx)

        llm_response = llm(
            prompt=req.prompt,
            temperature=req.temperature,
            top_p=req.top_p,
            max_tokens=req.max_tokens,
            stream=req.stream,
        )
        request.response_queue.put(llm_response)
        request.response_queue.close()


class CompletionRunner:
    def __init__(
        self,
        request_queue: multiprocessing.Queue[CompletionRunnerRequest],
    ):
        self.stop_accepting_requests_event = multiprocessing.Event()

        self.process = multiprocessing.Process(
            target=_run_completion,
            args=(request_queue, self.stop_accepting_requests_event),
        )

    def start(self):
        self.process.start()

    # def stop(self):
    #     """Stop after the current request has been processed."""
    #     self.stop_accepting_requests_event.set()
    #     self.process.join()
    #
    def kill(self):
        """Force stop immediately"""
        self.process.kill()
        self.process.join()

