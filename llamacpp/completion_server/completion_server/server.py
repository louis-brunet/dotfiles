import asyncio
import logging
import multiprocessing
import queue
import uuid
import time
from contextlib import asynccontextmanager
from multiprocessing.managers import DictProxy, SyncManager
from typing import Iterator

from fastapi import FastAPI
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


# class CompletionService:
#     current_runner: CompletionRunner | None = None
#     # runner_busy: bool = False
#
#     def __init__(
#         self,
#         manager: SyncManager,
#         verbose: bool = False,
#         # request_queue: queue.Queue[CompletionRunnerRequest],
#         # response_queues: DictProxy[
#         #     int,
#         #     queue.Queue[CreateCompletionResponse | Iterator[CreateCompletionStreamResponse]],
#         # ] = multiprocessing.Manager().dict(),
#     ):  # , response_queues):
#         self.logger = _module_logger.getChild(self.__class__.__name__)
#         self.manager = manager
#         self.request_queue = manager.Queue(maxsize=0)
#         self.response_queues: DictProxy[
#             int,
#             queue.Queue[
#                 CreateCompletionResponse | Iterator[CreateCompletionStreamResponse]
#             ],
#         ] = manager.dict()
#         self.verbose = verbose
#         # self.request_queue = request_queue
#         # self.response_queues = response_queues
#
#         self.logger.info("Completion service initialized.")
#
#     async def generate(
#         self,
#         request: CompletionRequest,
#     ) -> CreateCompletionResponse | Iterator[CreateCompletionStreamResponse]:
#         logger = self.logger.getChild(self.generate.__name__)
#
#         while True:
#             try:
#                 pending_request: CompletionRunnerRequest = (
#                     self.request_queue.get_nowait()
#                 )
#                 self.response_queues.pop(pending_request.request_id)
#                 logger.info(
#                     f"Removed pending request {pending_request.request_id} from queue"
#                 )
#             except queue.Empty:
#                 break
#
#         # if self.current_runner is not None and self.runner_busy:
#         max_concurrent_requests = 1
#         if (
#             self.current_runner is not None
#             and len(self.response_queues) >= max_concurrent_requests
#         ):
#             logger.info("Current runner is busy, terminating.")
#             self.current_runner.kill()
#             self.current_runner = None
#
#         if self.current_runner is None:
#             logger.info("Creating new completionn runner.")
#             self.current_runner = CompletionRunner(
#                 request_queue=self.request_queue,
#                 response_queues=self.response_queues,
#                 verbose=self.verbose,
#             )
#             self.current_runner.start()
#
#         # response_queue = multiprocessing.Queue(maxsize=1)
#
#         request_id = uuid.uuid4()
#         response_queue = self.manager.Queue(maxsize=1)
#         self.response_queues[request_id.int] = response_queue
#         # response_queue = self.response_queues[request_id.int]
#         # self.response_queues[request_id.int] = response_queue
#
#         self.request_queue.put(
#             CompletionRunnerRequest(request=request, request_id=request_id.int)
#         )
#         # logger.info(f"Request added to queue. There are {self.request_queue.} requests pending")
#         # self.runner_busy = True
#         empty_response = CreateCompletionResponse(
#             choices=[],
#             id=str(request_id),
#             created=0,
#             model=request.model,
#             object="text_completion",
#         )
#         try:
#             response = await asyncio.to_thread(
#                 response_queue.get, block=True, timeout=None
#             )
#             return response or empty_response
#         except Exception as e:
#             logger.error(f"Error generating completion: {e}")
#             return empty_response
#         finally:
#             self.response_queues.pop(request_id.int)
#
#             # response = await response_queue.get(block=True, timeout=None)
#
#             # if self.request_queue.empty():
#             #     logger.info("No more requests, runner is idle.")
#             #     self.runner_busy = False
#
#         # return response
#
#     def shutdown(self):
#         logger = self.logger.getChild(self.shutdown.__name__)
#
#         if self.current_runner is not None:
#             self.current_runner.kill()
#             self.current_runner = None
#             logger.info("runner stopped")


def create_app() -> FastAPI:
    @asynccontextmanager
    async def lifespan(app: FastAPI):
        # startup logic

        lifespan_logger = _module_logger.getChild("lifespan")
        lifespan_logger.info("App starting")

        manager = multiprocessing.Manager()

        lifespan_logger.info("Creating completion service")
        app.state.completion_service = CompletionService(manager=manager, verbose=False)

        yield

        # shutdown logic

        lifespan_logger.info("App shutting down")

        completion_service = get_completion_service(app)
        completion_service.shutdown()
        # if completion_service.current_runner is not None:
        #     completion_service.current_runner.kill()
        #     completion_service.current_runner = None
        #     logger.info("Completion service runner stopped")

        manager.shutdown()

    app = FastAPI(lifespan=lifespan)

    def get_completion_service(app: FastAPI) -> CompletionService:
        completion_service = app.state.completion_service
        assert isinstance(
            completion_service, CompletionService
        ), "Expected completion_service to be initialized"

        return completion_service

    @app.post("/v1/completions")
    async def completion(request: CompletionRequest):
        # -> CreateCompletionResponse | Iterator[CreateCompletionStreamResponse]:
        completion_service = get_completion_service(app)

        return await completion_service.generate(request)

    return app


app = create_app()

# class AppState(TypedDict):
#     llm: Optional[Llama]
#     current_task: Optional[asyncio.Task]
#     lock: asyncio.Lock
#
#
# MODEL_ALIASES = {
#     "qwen2.5-coder:1.5b-instruct": "qwen2.5-coder-1.5b-instruct-q8_0",
#     "qwen2.5-coder:7b-instruct": "qwen2.5-coder-7b-instruct-q5_k_m",
#     "codellama:7b": "codellama-7b.Q8_0",
# }
#
#
# class ModelNotFoundError(Exception):
#     def __init__(self, model_name: str):
#         super().__init__(f"Model {model_name} not found")
#
#
# def load_model(model_path: str, n_ctx: int) -> Llama:
#     return Llama(
#         model_path=model_path,
#         n_ctx=n_ctx,
#         n_gpu_layers=-1,
#         flash_attn=True,
#         n_threads=12,
#         # n_batch=n_batch
#         # tokenizer=,
#         # chat_format=chat_format,
#     )
#
#
# def create_app(models_directory: str) -> FastAPI:
#     logger.info(f"Creating app with models directory: {models_directory}")
#
#     app = FastAPI()
#
#     app_state = AppState(llm=None, current_task=None, lock=asyncio.Lock())
#
#     # current_task: Optional[asyncio.Task[str]] = None
#     # llm: Optional[Llama] = None
#
#     def requested_model_to_model_path(model_name: str) -> str:
#         alias = MODEL_ALIASES.get(model_name)
#
#         if alias:
#             model_name = alias
#
#         return os.path.join(models_directory, f"{model_name}.gguf")
#
#     # async def generate_completion(prompt: str, max_tokens: int):
#     async def generate_completion(
#         request: CompletionRequest,
#     ) -> CreateCompletionResponse | Iterator[CreateCompletionStreamResponse]:
#         # nonlocal current_task
#         # nonlocal llm
#
#         requested_model_path = requested_model_to_model_path(request.model)
#         if not os.path.exists(requested_model_path):
#             raise ModelNotFoundError(request.model)
#
#         async with app_state["lock"]:
#             llm = app_state["llm"]
#             app_state["current_task"] = asyncio.current_task()
#
#             if (
#                 (not llm)
#                 or llm.model_path != requested_model_path
#                 or llm.n_ctx() != request.n_ctx
#             ):
#                 if llm:
#                     logger.error(
#                         f'Unloading current model, {dict({
#                             "old_model_path": llm.model_path,
#                             "new_model_path": requested_model_path,
#                             "old_n_ctx": llm.n_ctx(),
#                             "new_n_ctx": request.n_ctx,
#                         })}',
#                     )
#                     llm.close()
#
#                 app_state["llm"] = load_model(
#                     model_path=requested_model_path, n_ctx=request.n_ctx
#                 )
#                 logger.info(f"Loaded model {requested_model_path}")
#         # elif llm:
#         #     llm.reset()
#
#         # prior_llm_state = llm.save_state()
#         logger.info("Waiting for LLM response")
#
#         llm_generate_task: Optional[asyncio.Task] = None
#         try:
#             llm_generate_task = asyncio.create_task(
#                 asyncio.to_thread(
#                     cast(Llama, app_state["llm"]),
#                     request.prompt,
#                     max_tokens=request.max_tokens,
#                     stream=request.stream,
#                     temperature=request.temperature,
#                     top_p=request.top_p,
#                     top_k=request.top_k,
#                     stop=request.stop,
#                     echo=False,
#                 )
#             )
#             output = await llm_generate_task
#             # llm(
#             #     request.prompt,
#             #     max_tokens=request.max_tokens,
#             #     stream=request.stream,
#             #     temperature=request.temperature,
#             #     top_p=request.top_p,
#             #     top_k=request.top_k,
#             #     stop=request.stop,
#             #     echo=False,
#             # )
#             return output
#         finally:
#             async with app_state["lock"]:
#                 if app_state["current_task"] == asyncio.current_task():
#                     logger.info("Setting current_task to None")
#                     app_state["current_task"] = None
#
#             if llm_generate_task:  # and not llm_generate_task.done():
#                 logger.info("Stopping llm generation thread")
#                 llm_generate_task.cancel()
#
#                 try:
#                     await llm_generate_task
#                 except asyncio.CancelledError:
#                     async with app_state["lock"]:
#                         logger.info("LLM generation thread stopped, unloading model")
#                         llm = app_state["llm"]
#                         if llm:
#                             llm.close()
#                         app_state["llm"] = None
#
#                     # logger.info("LLM generation thread stopped, resetting llm state")
#                     # llm.load_state(prior_llm_state)
#                     # pass
#
#     @app.post("/completion")
#     async def complete(request: CompletionRequest):
#         import uuid
#
#         logger = logging.getLogger(f"completion.{uuid.uuid4()}")
#
#         logger.info(f"/completion {request}")
#         # nonlocal current_task
#         #
#         # # Cancel the current task if it exists
#         # if current_task:
#
#         # async with app_state["lock"]:
#         current_task = app_state["current_task"]
#         if current_task:
#             logger.info("Cancelling existing task")
#             current_task.cancel()
#             try:
#                 await current_task
#             except asyncio.CancelledError:
#                 pass
#             finally:
#                 app_state["current_task"] = None
#             # if llm:
#             #     llm.reset()
#         else:
#             logger.info("No running task to cancel")
#
#         #     raise e # :)
#
#         # Create a new completion task
#         completion_task = asyncio.create_task(generate_completion(request))
#
#         try:
#             result = await completion_task
#             if not request.stream:
#                 logger.info("Generated result")
#                 logger.info(
#                     cast(CreateCompletionResponse, result)["choices"][0]["text"]
#                 )
#             return {"completion": result}
#         except asyncio.CancelledError:
#             logger.error("Request cancelled")
#             return {"completion": "", "error": "Request cancelled"}
#         except ModelNotFoundError as e:
#             logger.error(repr(e))
#             return {"completion": "", "error": str(e)}
#         except Exception as e:
#             return {"completion": "", "error": f"Unknown error"}  #: {e}"}
#
#     return app
#
#
# def default_models_directory() -> str:
#     script_path = os.path.realpath(__file__)
#     llamacpp_dir = os.path.dirname(os.path.dirname(os.path.dirname(script_path)))
#     models_directory = os.path.join(llamacpp_dir, "models")  # ../../models
#     return models_directory
#
#
# app = create_app(
#     models_directory=os.environ.get(
#         "COMPLETION_SERVER_MODELS_DIRECTORY", default_models_directory()
#     )
# )
