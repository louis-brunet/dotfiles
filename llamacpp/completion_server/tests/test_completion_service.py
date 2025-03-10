import asyncio
import multiprocessing
from typing import Coroutine, Iterator

from completion_server.completion_service import CompletionService
from completion_server.entities import CompletionRequest
import pytest

TEST_MODEL = "qwen2.5-coder:1.5b-instruct"


def create_test_completion_service() -> CompletionService:
    manager = multiprocessing.Manager()
    return CompletionService(manager=manager, verbose=False)


def create_test_request(
    prompt: str = "Why is the sky blue?",
    max_tokens: int = 10,
    stream: bool = False,
) -> CompletionRequest:
    return CompletionRequest(
        model=TEST_MODEL,
        prompt=prompt,
        max_tokens=max_tokens,
        stream=stream,
    )


class TestCompletionService:
    def test_immediate_shutdown(self):
        completion_service = create_test_completion_service()

        # assert completion_service.current_runner is not None
        completion_service.shutdown()
        assert completion_service.current_runner is None

    @pytest.mark.asyncio
    async def test_generate_once(self):
        request = create_test_request()
        completion_service = create_test_completion_service()
        response = await completion_service.generate(request=request)
        completion_service.shutdown()

        assert response is not None
        assert not isinstance(response, Iterator)
        assert response["choices"][0] is not None

    # @pytest.mark.asyncio
    # async def test_generate_twice(self):
    #     request = create_test_request()
    #     completion_service = create_test_completion_service()
    #
    #     coroutine1 = completion_service.generate(request=request)
    #     await asyncio.sleep(0.3)
    #     coroutine2 = completion_service.generate(request=request)
    #
    #     response1, response2 = await asyncio.gather(coroutine1, coroutine2)
    #
    #     completion_service.shutdown()
    #
    #     assert response1 is not None
    #     assert not isinstance(response1, Iterator)
    #     assert response1["choices"] is None or len(response1["choices"]) == 0
    #
    #     assert response2 is not None
    #     assert not isinstance(response2, Iterator)
    #     assert response2["choices"] is not None
    #     assert response2["choices"][0] is not None
    #     assert isinstance(response2["choices"][0]["text"], str)
    #
    #     # await asyncio.sleep(0.5)

    @pytest.mark.asyncio
    async def test_generate_n(self):
        request = create_test_request()

        for request_count in [
            2,  # TODO: 3, # FIXME: if too many requests, completion_service hangs
        ]:  # 3, 4, 5, 10]:
            completion_service = create_test_completion_service()

            coroutines: list[Coroutine] = []
            for request_index in range(request_count - 1):
                coroutines.append(completion_service.generate(request=request))
                await asyncio.sleep(0.4) # FIXME: if the delay between requests is too low, completion_service hangs
            coroutines.append(completion_service.generate(request=request))

            responses = await asyncio.gather(*coroutines)

            completion_service.shutdown()

            assert len(responses) == request_count
            for response in responses:
                assert response is not None
                assert not isinstance(response, Iterator)

            await asyncio.sleep(0.5)
