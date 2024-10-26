from contextlib import asynccontextmanager
import logging
import multiprocessing
from typing import Iterator

from fastapi import FastAPI
from llama_cpp import CreateCompletionResponse, CreateCompletionStreamResponse

from completion_server.entities import CompletionRequest
from completion_server.runner import CompletionRunner, CompletionRunnerRequest

logger = logging.getLogger(__name__)


class CompletionService:
    current_runner: CompletionRunner | None = None
    request_queue: multiprocessing.Queue[CompletionRunnerRequest] = (
        multiprocessing.Queue(maxsize=0)
    )
    runner_busy: bool = False

    def __init__(self):
        self.logger = logging.getLogger(self.__class__.__name__)

    async def generate(
        self,
        request: CompletionRequest,
    ) -> CreateCompletionResponse | Iterator[CreateCompletionStreamResponse]:
        if self.current_runner is not None and self.runner_busy:
            self.logger.info("Current runner is busy, terminating.")
            self.current_runner.kill()
            self.current_runner = None

        if self.current_runner is None:
            self.logger.info("Creating new completionn runner.")
            current_runner = CompletionRunner(self.request_queue)
            current_runner.start()

        response_queue = multiprocessing.Queue(maxsize=1)
        self.request_queue.put(
            CompletionRunnerRequest(request=request, response_queue=response_queue)
        )
        self.runner_busy = True
        response = await response_queue.get(block=True, timeout=None)
        if self.request_queue.empty():
            self.logger.info("No more requests, runner is idle.")
            self.runner_busy = False
        return response


def create_app(completion_service: CompletionService) -> FastAPI:
    @asynccontextmanager
    async def lifespan(app: FastAPI):
        # startup logic
        logger.info("App starting")

        yield

        # shutdown logic
        logger.info("App shutting down")
        if completion_service.current_runner is not None:
            completion_service.current_runner.kill()
            completion_service.current_runner = None
            logger.info("Completion service runner stopped")

    app = FastAPI(lifespan=lifespan)

    @app.post("/completion")
    async def completion(request: CompletionRequest):
        return await completion_service.generate(request)

    return app


app = create_app(CompletionService())

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
