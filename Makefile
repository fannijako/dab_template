.PHONY = sync lock lint format format-check pre-commit clean

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

pre-commit:
	uv run pre-commit run --all-files

clean:
	rm -rf .venv
	rm -rf __pycache__
	rm -rf */__pycache__
	rm -rf .ruff_cache
	rm -rf *.egg-info
