import argparse
import asyncio
import json
import logging
import platform
import sys
import time

import psutil
import websockets
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[logging.StreamHandler(sys.stdout)],
)
log = logging.getLogger(__name__)

def _bytes_to_mb(b: int) -> float:
    return round(b / (1024 * 1024), 2)

def _get_network_stats() -> dict:
    now = time.monotonic()
    counters = psutil.net_io_counters(pernic=True)

    cache = _get_network_stats._cache  # type: ignore[attr-defined]
    last_time = _get_network_stats._last_time  # type: ignore[attr-defined]

    elapsed = now - last_time if last_time else 1.0
    interfaces = []

    for iface, stats in counters.items():
        if iface == "lo" or iface.startswith("Loopback"):
            continue
        prev = cache.get(iface)
        if prev and elapsed > 0:
            rx_rate = max(0, (stats.bytes_recv - prev.bytes_recv) / elapsed)
            tx_rate = max(0, (stats.bytes_sent - prev.bytes_sent) / elapsed)
        else:
            rx_rate = tx_rate = 0.0
        interfaces.append(
            {
                "interface": iface,
                "rx_bytes_per_sec": round(rx_rate, 1),
                "tx_bytes_per_sec": round(tx_rate, 1),
                "rx_total_mb": _bytes_to_mb(stats.bytes_recv),
                "tx_total_mb": _bytes_to_mb(stats.bytes_sent),
            }
        )

    _get_network_stats._cache = counters  # type: ignore[attr-defined]
    _get_network_stats._last_time = now  # type: ignore[attr-defined]
    return {"interfaces": interfaces}


_get_network_stats._cache = {}  # type: ignore[attr-defined]
_get_network_stats._last_time = None  # type: ignore[attr-defined]


def _get_disk_stats() -> list[dict]:
    partitions = []
    for part in psutil.disk_partitions(all=False):
        # Skip pseudo filesystems
        if part.fstype in ("", "tmpfs", "devtmpfs", "squashfs", "overlay"):
            continue
        try:
            usage = psutil.disk_usage(part.mountpoint)
        except PermissionError:
            continue
        partitions.append(
            {
                "mountpoint": part.mountpoint,
                "device": part.device,
                "fstype": part.fstype,
                "total_mb": _bytes_to_mb(usage.total),
                "used_mb": _bytes_to_mb(usage.used),
                "free_mb": _bytes_to_mb(usage.free),
                "percent": usage.percent,
            }
        )
    return partitions


def collect_stats() -> dict:
    cpu_percent = psutil.cpu_percent(interval=None)
    cpu_per_core = psutil.cpu_percent(interval=None, percpu=True)
    cpu_freq = psutil.cpu_freq()

    mem = psutil.virtual_memory()
    swap = psutil.swap_memory()

    return {
        "timestamp": time.time(),
        "platform": platform.system(),
        "cpu": {
            "percent": cpu_percent,
            "per_core": cpu_per_core,
            "core_count": psutil.cpu_count(logical=False),
            "thread_count": psutil.cpu_count(logical=True),
            "freq_mhz": round(cpu_freq.current, 1) if cpu_freq else None,
            "freq_max_mhz": round(cpu_freq.max, 1) if cpu_freq else None,
        },
        "memory": {
            "total_mb": _bytes_to_mb(mem.total),
            "used_mb": _bytes_to_mb(mem.used),
            "available_mb": _bytes_to_mb(mem.available),
            "percent": mem.percent,
            "swap_total_mb": _bytes_to_mb(swap.total),
            "swap_used_mb": _bytes_to_mb(swap.used),
            "swap_percent": swap.percent,
        },
        "disks": _get_disk_stats(),
        "network": _get_network_stats(),
    }

async def handler(websocket: websockets.ServerConnection) -> None:
    try:
        await websocket.send(json.dumps(collect_stats()))
        await websocket.wait_closed()
    finally:
        log.info("Client disconnected ")


async def broadcast_loop(interval: float, websocket: websockets.Server) -> None:
    # Warm up psutil's CPU % counter (first call always returns 0.0)
    psutil.cpu_percent(interval=None)
    await asyncio.sleep(interval)

    while True:
        payload = json.dumps(collect_stats())
        for connection in websocket.connections:
            _ = await connection.send(payload)
        await asyncio.sleep(interval)


async def main(host: str, port: int, interval: float) -> None:
    log.info("Starting stats daemon on ws://%s:%d (interval=%.1fs)", host, port, interval)
    log.info("Platform: %s | Python %s", platform.system(), sys.version.split()[0])

    async with websockets.serve(handler, host, port) as server:
        await broadcast_loop(interval, server)
        await server.serve_forever()

# pip install psutil websockets
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="System stats WebSocket daemon")
    parser.add_argument("--host", default="127.0.0.1", help="Bind host (default: 127.0.0.1)")
    parser.add_argument("--port", type=int, default=9889, help="WebSocket port (default: 9889)")
    parser.add_argument("--interval", type=float, default=1.0, help="Broadcast interval in seconds (default: 1.0)")
    args = parser.parse_args()

    try:
        asyncio.run(main(args.host, args.port, args.interval))
    except KeyboardInterrupt:
        log.info("Daemon stopped.")