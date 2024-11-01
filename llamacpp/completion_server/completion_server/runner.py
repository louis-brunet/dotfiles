import logging
import multiprocessing
import queue
import uuid
from multiprocessing.managers import DictProxy
from multiprocessing.synchronize import Event
from typing import Iterator

from llama_cpp import CreateCompletionResponse, CreateCompletionStreamResponse, Llama

from completion_server import model
from completion_server.entities import CompletionRequest

_module_logger = logging.getLogger(__name__)


class CompletionRunnerRequest:
    def __init__(
        self,
        request: CompletionRequest,
        request_id: int,
    ):
        self.request = request
        self.request_id = request_id


def _run_completion(
    request_queue: queue.Queue,
    response_queues: DictProxy,  # [int, queue.Queue[CreateCompletionResponse | Iterator[CreateCompletionStreamResponse]]],  # [int, queue.Queue],
    stop_accepting_requests_event: Event,
    runner_busy_event: Event,
    verbose: bool = False,
):
    import signal
    import sys

    # import logging
    from completion_server import log

    log.configure_logging()

    logger = logging.getLogger(
        f"_run_completion.pid.{multiprocessing.current_process().pid}"
    )
    llm: Llama | None = None
    pending_response_queue: (
        queue.Queue[
            None | CreateCompletionResponse | Iterator[CreateCompletionStreamResponse]
        ]
        | None
    ) = None

    def force_terminate(signum, frame):
        logger.error(
            f"Received signal {signal.strsignal(signum)} ({signum}), terminating..."
        )

        nonlocal pending_response_queue
        if pending_response_queue is not None:
            logger.info("There is a pending response queue, sending None to signal end")
            pending_response_queue.put(None)
            pending_response_queue = None

        sys.exit(0)

    signal.signal(signal.SIGINT, force_terminate)
    signal.signal(signal.SIGTERM, force_terminate)
    # signal.signal(signal.SIGKILL, force_terminate)

    while not stop_accepting_requests_event.is_set():
        logger.info("Waiting for request...")
        runner_busy_event.clear()
        try:
            request = request_queue.get(block=True, timeout=None)
        except EOFError as e:
            logger.error(f"Request queue closed, cannot process any more requests: {e}")
            break
        runner_busy_event.set()

        request_logger = logger.getChild(f"request.{uuid.UUID(int=request.request_id)}")
        request_logger.info(f"Received request: {str(request)}")

        assert isinstance(
            request, CompletionRunnerRequest
        ), "request is not a CompletionRunnerRequest"
        # if not isinstance(request, CompletionRunnerRequest):
        #     logger.error(f"Unexpected request type: {type(request)}")
        #     continue

        pending_response_queue = response_queues[request.request_id]
        assert (
            pending_response_queue is not None
        ), f"response queue not found for request with ID: {request.request_id}"

        req = request.request
        request_logger.info(f"Processing request with ID: {request.request_id}")

        if llm is not None and not model.can_model_respond_to_request(llm, req):
            request_logger.info(
                "Loaded model is not compatible with request parameters, unloading..."
            )
            llm.close()
            llm = None

        if llm is None:
            request_logger.info("Loading model...")
            try:
                llm = model.load_model(
                    model_name_or_alias=req.model, n_ctx=req.n_ctx, verbose=verbose
                )
            # except model.ModelNotFoundError as e:
            #     request_logger.error(f"Model not found: {e}")
            except Exception as e:
                request_logger.error(f"Failed to load model: {e}")

        if llm is not None:
            request_logger.info("Model is loaded, generating response")

            llm_response = llm(
                prompt=req.prompt,
                temperature=req.temperature,
                top_p=req.top_p,
                max_tokens=req.max_tokens,
                stream=req.stream,
                suffix=req.suffix,
            )

            if pending_response_queue is not None:
                pending_response_queue.put(llm_response)
                # response_queue.shutdown(immediate=False)
                pending_response_queue = None
                request_logger.info("Put response in response queue")
        else:
            request_logger.error("Model is not loaded, cannot generate response")
            if pending_response_queue is not None:
                pending_response_queue.put(None)
                pending_response_queue = None


class CompletionRunner:
    def __init__(
        self,
        request_queue: queue.Queue[CompletionRunnerRequest],
        response_queues: DictProxy,
        runner_busy_event: Event,
        # [
        #     int,
        #     queue.Queue[
        #         CreateCompletionResponse | Iterator[CreateCompletionStreamResponse]
        #     ],
        # ],
        stop_accepting_requests_event: Event = multiprocessing.Event(),
        verbose: bool = False,
    ):
        self.logger = _module_logger.getChild(self.__class__.__name__)
        self.runner_busy_event = runner_busy_event

        self.process = multiprocessing.Process(
            target=_run_completion,
            args=(
                request_queue,
                response_queues,
                stop_accepting_requests_event,
                runner_busy_event,
                verbose,
            ),
            # args=(request_queue, self.stop_accepting_requests_event),
            # daemon=False,
        )

    def start(self):
        self.process.start()
        self.logger.info(f"started child process with PID: {self.process.pid}")

    # def stop(self):
    #     """Stop after the current request has been processed."""
    #     self.stop_accepting_requests_event.set()
    #     self.process.join()
    #
    def kill(self):
        """Force stop immediately"""
        if self.process.is_alive():
            self.logger.info(f"terminating child process with PID: {self.process.pid}")

            self.process.terminate()

            # import os
            # import signal
            # if self.process.pid:
            #     os.kill(self.process.pid, signal.SIGINT)

        self.process.join()  # timeout=5)
