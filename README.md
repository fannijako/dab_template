# Python repository template

[![Coverage Status](https://img.shields.io/badge/coverage-100%25-brightgreen)](https://github.com/fannijako/repo_template)

## Project Overview

Repository template for my Python projects.

Toolchain:
- **[uv](https://docs.astral.sh/uv/)** — environment & dependency management
- **[poetry-core](https://python-poetry.org/)** — PEP 517 build backend
- **[ruff](https://docs.astral.sh/ruff/)** — linting & formatting
- **pytest** — testing

## Dependencies

- python package 1
- python package 2

## Installation

Install [uv](https://docs.astral.sh/uv/getting-started/installation/), then sync the environment:

```bash
make sync
```

This creates `.venv/` and installs the project plus the `dev` and `test` groups.

## Common tasks

```bash
make lint          # ruff check
make format        # ruff format (in place)
make format-check  # ruff format --check
make test          # pytest with coverage
make run           # python main.py
make clean         # remove .venv and caches
```

## Usage

Create a `.env` file with the variables your app needs:

```bash
KEY_NAME=key_value
```

Then:

```bash
make sync
make run
```
