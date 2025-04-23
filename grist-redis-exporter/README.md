# Prometheus exporter for Grist data in Redis

**Status: ✅ Ready to be used in production**

This simple service allows exporting data from Redis as a prometheus metrics endpoint.

In its first version, it is used to track document assignments to workers.

## Setup

Using `mise`:

- [install `mise`](https://mise.jdx.dev/getting-started.html)
- run `mise i`
- run `uv sync`
- configure your Redis instance (see `main.py`)
- run `uv run main.py`
