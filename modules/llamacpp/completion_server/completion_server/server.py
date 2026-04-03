import logging
import multiprocessing
from contextlib import asynccontextmanager

from fastapi import FastAPI

from completion_server.completion_service import CompletionService
from completion_server.entities import CompletionRequest

_module_logger = logging.getLogger(__name__)


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
