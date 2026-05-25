.PHONY = sync lock lint format format-check typecheck test pre-commit run clean

sync:
	uv sync --all-groups

lock:
	uv lock

lint:
	uv run ruff check .

format:
	uv run ruff format .

format-check:
	uv run ruff format --check .

typecheck:
	uv run mypy

test:
	uv run pytest

pre-commit:
	uv run pre-commit run --all-files

run:
	uv run python main.py

clean:
	rm -rf .venv
	rm -rf __pycache__
	rm -rf */__pycache__
	rm -rf .pytest_cache
	rm -rf .ruff_cache
	rm -rf .mypy_cache
	rm -rf *.egg-info
