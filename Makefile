.PHONY = sync lock lint format format-check typecheck test pre-commit clean

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
	cd source_code_placeholder && uv run mypy

test:
	cd source_code_placeholder && uv run pytest

pre-commit:
	uv run pre-commit run --all-files

clean:
	rm -rf .venv
	rm -rf source_code_placeholder/.venv
	rm -rf __pycache__
	rm -rf */__pycache__
	rm -rf .ruff_cache
	rm -rf .pytest_cache
	rm -rf .mypy_cache
	rm -rf source_code_placeholder/.pytest_cache
	rm -rf source_code_placeholder/.mypy_cache
	rm -rf *.egg-info
