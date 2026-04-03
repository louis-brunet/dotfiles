.PHONY: bootstrap install lint format test check pre-commit-install pre-commit

install:
	uv run python -m engine.cli install

bootstrap:
	python3 -m scripts.bootstrap

lint:
	uv run ruff check engine/ tests/

format:
	uv run ruff format engine/ tests/

test:
	uv run pytest tests/

check: lint test

pre-commit-install:
	uv run pip install pre-commit
	uv run pre-commit install

pre-commit:
	uv run pre-commit run --all-files
