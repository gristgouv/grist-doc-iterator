FROM python:3.13-alpine

WORKDIR /app

# install dependencies
COPY uv.lock pyproject.toml ./
RUN apk add bash jq minio-client sqlite
RUN --mount=from=ghcr.io/astral-sh/uv,source=/uv,target=/bin/uv uv export --no-dev --locked > requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# install source
COPY main.py scripts doc-iterator.sh ./

ENV MINIO_MC=mcli
ENTRYPOINT [ "python", "main.py" ]

