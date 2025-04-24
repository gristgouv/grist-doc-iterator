import os

import psutil
from prometheus_client import start_http_server
from prometheus_client.core import (
    CollectorRegistry,
    CounterMetricFamily,
    GaugeMetricFamily,
)
from prometheus_client.registry import Collector

METRICS_PORT = int(os.environ.get("METRICS_PORT", 9090))


def get_tini_process():
    for proc in psutil.process_iter():
        try:
            cmdline = proc.cmdline()
        except Exception as e:
            print(f"Could not retrieve cmdline: {e}")
            continue
        if "/usr/bin/tini" in cmdline:
            return proc


class CustomCollector(Collector):
    def collect(self):
        # To read correct cgroup we need to read the root fs of the grist init process
        tini_process = get_tini_process()
        process_root_prefix = f"/proc/{tini_process.pid}/root"
        cgroup_path = f"{process_root_prefix}/sys/fs/cgroup"

        # Max cgroup memory
        pod_cgroup_mem_max_metrics = GaugeMetricFamily(
            "pod_cgroup_memory_max", "Max memory available to pod cgroup"
        )
        with open(f"{cgroup_path}/memory.max", "r") as f:
            raw_value = f.read().strip()
        if raw_value == "max":
            value = 0
        else:
            try:
                value = int(raw_value)
            except ValueError:
                print(f"Could not parse value {raw_value} in {cgroup_path}/memory.max")
                value = 0
        pod_cgroup_mem_max_metrics.add_metric([], value)

        yield pod_cgroup_mem_max_metrics

        # Current cgroup memory usage
        pod_cgroup_mem_usage_metrics = GaugeMetricFamily(
            "pod_cgroup_memory_usage", "Memory used by pod cgroup"
        )
        with open(f"{cgroup_path}/memory.current", "r") as f:
            raw_value = f.read().strip()
        try:
            value = int(raw_value)
        except ValueError:
            print(f"Could not parse value {raw_value} in {cgroup_path}/memory.current")
            value = 0
        pod_cgroup_mem_usage_metrics.add_metric([], value)

        yield pod_cgroup_mem_usage_metrics

        # Doc memory and cpu
        grist_doc_mem_pss_metrics = GaugeMetricFamily(
            "grist_doc_mem_pss",
            "Memory proportional set size used by grist documents",
            labels=["doc_id"],
        )
        grist_doc_cpu_metrics = CounterMetricFamily(
            "grist_doc_cpu",
            "CPU usage for a grist document",
            labels=["doc_id", "mode"],
        )
        for proc in psutil.process_iter():
            try:
                cmdline = proc.cmdline()
            except Exception as e:
                print(f"Could not retrieve cmdline: {e}")
                continue
            if "/grist/sandbox/grist/main.py" in cmdline:
                # doc id is at the end of the python sandbox process cmdline
                doc_id = cmdline[-1]
                # compute total pss for whole sandbox process tree
                pss = sum(
                    [
                        p.memory_full_info().pss
                        for p in [proc] + proc.children(recursive=True)
                    ]
                )
                grist_doc_mem_pss_metrics.add_metric([doc_id], pss)

                # cpu time is split in user and system (aka kernel) mode
                cpu_times = [
                    p.cpu_times() for p in [proc] + proc.children(recursive=True)
                ]
                # there is an existing children_{user,system} property but it doesn't seem to properly sum childen times
                user = sum([t.user for t in cpu_times])
                system = sum([t.system for t in cpu_times])
                grist_doc_cpu_metrics.add_metric([doc_id, "user"], user)
                grist_doc_cpu_metrics.add_metric([doc_id, "system"], system)

        yield grist_doc_mem_pss_metrics
        yield grist_doc_cpu_metrics


# Create new registry to drop default python metrics
registry = CollectorRegistry()
registry.register(CustomCollector())

_, t = start_http_server(METRICS_PORT, registry=registry)
print("Started server on port " + str(METRICS_PORT))
t.join()
