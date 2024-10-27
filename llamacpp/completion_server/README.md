# Prerequisites

- Python 3.12+
- Poetry: [installation instructions](https://python-poetry.org/docs/#installing-with-the-official-installer) 

# Usage

```python
poetry install
poetry run python completion_server
```
# Development

```python
# Install dependencies
poetry install

# Run your editor in the project virtual environment
poetry run "$EDITOR"

# Or use the poetry shell
poetry shell
```

# Server

```
Server 1<-->1 CompletionService
CompletionService 1<-->0..1 CompletionRunner
```
