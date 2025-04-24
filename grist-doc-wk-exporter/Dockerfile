FROM python:3.13-slim AS builder
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/
WORKDIR /app

COPY uv.lock pyproject.toml ./
RUN uv sync --frozen --no-install-project --no-editable

FROM python:3.13-slim
WORKDIR /app

COPY --from=builder --chown=app:app /app/.venv /app/.venv

ENV PATH="/app/.venv/bin:$PATH"
ENV VIRTUAL_ENV="/app/.venv/"

COPY main.py .

ENTRYPOINT [ "python" ]
CMD ["/app/main.py"]
