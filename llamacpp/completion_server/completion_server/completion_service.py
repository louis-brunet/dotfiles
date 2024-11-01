import asyncio
import logging
import multiprocessing
from multiprocessing.managers import DictProxy, SyncManager
import queue
import time
from typing import Iterator
import uuid

from llama_cpp import CreateCompletionResponse, CreateCompletionStreamResponse

from completion_server.entities import CompletionRequest
from completion_server.runner import CompletionRunner, CompletionRunnerRequest

_module_logger = logging.getLogger(__name__)


class CompletionService:
    def __init__(
        self,
        manager: SyncManager,
        verbose: bool = False,
    ):
        self.logger = _module_logger.getChild(self.__class__.__name__)
        self.manager = manager
        self.pending_request = manager.Queue(maxsize=1)
        self.pending_responses: DictProxy = manager.dict()
        self.verbose: bool = verbose

        self.runner_busy_event = multiprocessing.Event()
        self.current_runner = None
        self.reload_runner()
        # self.runner_busy: bool = False
        # self.current_runner = CompletionRunner(
        #     request_queue=self.pending_request,
        #     response_queues=self.pending_responses,
        # )
        # self.current_runner.start()

    def reload_runner(self):
        if self.current_runner is not None:
            self.logger.info("Terminating current runner")
            self.current_runner.kill()

        self.runner_busy_event.clear()
        # self.runner_busy = False

        self.logger.info("Initializing new runner")
        self.current_runner = CompletionRunner(
            request_queue=self.pending_request,
            response_queues=self.pending_responses,
            runner_busy_event=self.runner_busy_event,
            verbose=self.verbose,
        )
        self.current_runner.start()

    async def generate(
        self, request: CompletionRequest
    ) -> CreateCompletionResponse | Iterator[CreateCompletionStreamResponse]:
        request_start_time = time.time()
        request_id = uuid.uuid4()

        logger = self.logger.getChild(self.generate.__name__)
        logger = logger.getChild(str(request_id))

        logger.info(f"Received request: {request}")

        # Empty request queue
        try:
            self.pending_request.get_nowait()
            logger.info("Emptied pending request queue")
        except queue.Empty:
            logger.info("No pending requests to empty")

        # Kill and reload runner if a request is being processed
        if self.runner_busy_event.is_set():
            # if self.runner_busy:
            logger.info("Current runner is busy.")
            self.reload_runner()
            # if self.current_runner is not None:
            #     logger.info("Terminating current runner")
            #     self.current_runner.kill()
            # logger.info("Initializing new runner")
            # self.current_runner = CompletionRunner(
            #     request_queue=self.pending_request,
            #     response_queues=self.pending_responses,
            #     verbose=self.verbose,
            # )

        # Initialize response queue
        response_queue = self.manager.Queue(maxsize=1)
        self.pending_responses[request_id.int] = response_queue

        # Set pending request
        runner_request = CompletionRunnerRequest(
            request=request, request_id=request_id.int
        )
        # self.runner_busy = True
        logger.info("Sending request to pending queue")
        self.pending_request.put_nowait(runner_request)

        # Wait for response
        empty_response = CreateCompletionResponse(
            choices=[],
            id=str(request_id),
            created=0,
            model=request.model,
            object="text_completion",
        )
        logger.info("Waiting for response...")

        try:
            # response = response_queue.get(block=True, timeout=None)
            response = await asyncio.to_thread(
                response_queue.get,
                block=True,
                timeout=None,
            )
            logger.info(f"received response {response}")
            # self.runner_busy = False
            return response or empty_response
        except Exception as e:
            logger.error(f"error while waiting for response: {e}")
            return empty_response
        finally:
            self.pending_responses.pop(request_id.int)
            request_processing_time = time.time() - request_start_time
            logger.info(
                "Requested processing finished in %.3fs." % request_processing_time
            )

    def shutdown(self):
        logger = self.logger.getChild(self.shutdown.__name__)

        if self.current_runner is not None:
            self.current_runner.kill()
            self.current_runner = None
            logger.info("runner stopped")
