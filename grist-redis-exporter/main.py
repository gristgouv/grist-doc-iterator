import json
import os

import redis
from prometheus_client import start_http_server
from prometheus_client.core import CollectorRegistry, GaugeMetricFamily
from prometheus_client.registry import Collector

REDIS_HOST = os.environ.get("REDIS_HOST", "localhost")
REDIS_PORT = int(os.environ.get("REDIS_PORT", 6379))
REDIS_PASSWORD = os.environ.get("REDIS_PASSWORD")
METRICS_PORT = int(os.environ.get("METRICS_PORT", 9090))

r = redis.Redis(
    host=REDIS_HOST,
    port=REDIS_PORT,
    password=REDIS_PASSWORD,
    decode_responses=True,
)


class CustomCollector(Collector):
    def collect(self):
        doc_metrics = GaugeMetricFamily(
            "doc_assignments",
            "Documents assigned to doc workers",
            labels=["doc_wk_ip", "doc_id"],
        )

        keys = r.keys("doc-*")
        for key in keys:
            if key.endswith("-checksum"):
                continue
            data = r.hgetall(key)
            doc_wk_ip = json.loads(data["docWorker"])["id"].replace("-", ".")
            doc_id = key.removeprefix("doc-")
            doc_metrics.add_metric([doc_wk_ip, doc_id], 1)

        yield doc_metrics


# Create new registry to drop default python metrics
registry = CollectorRegistry()
registry.register(CustomCollector())

_, t = start_http_server(METRICS_PORT, registry=registry)
print("Started server on port " + str(METRICS_PORT))
t.join()
