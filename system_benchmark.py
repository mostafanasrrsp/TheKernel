#!/usr/bin/env python3
import argparse
import hashlib
import json
import math
import multiprocessing as mp
import os
import platform
import shutil
import subprocess
import sys
import time


def safe_import(module_name):
    try:
        return __import__(module_name)
    except Exception:
        return None


psutil = safe_import("psutil")
np = safe_import("numpy")


def format_bytes_per_sec(bps: float) -> str:
    units = ["B/s", "KB/s", "MB/s", "GB/s", "TB/s"]
    i = 0
    while bps >= 1024 and i < len(units) - 1:
        bps /= 1024.0
        i += 1
    return f"{bps:.2f} {units[i]}"


def cpu_sha256_worker(duration_s: float, block_size: int = 1024) -> int:
    data = bytearray(os.urandom(block_size))
    count = 0
    end = time.perf_counter() + duration_s
    h = hashlib.sha256
    while time.perf_counter() < end:
        _ = h(data).digest()
        # Mutate one byte to avoid trivial caching
        data[0] ^= (count & 0xFF)
        count += 1
    return count * block_size  # bytes processed


def bench_cpu(duration_s: float = 3.0, max_procs: int | None = None):
    # Single-thread
    single_bytes = cpu_sha256_worker(duration_s)
    single_bps = single_bytes / duration_s

    # Multi-process
    if max_procs is None:
        if psutil is not None:
            max_procs = max(1, min(psutil.cpu_count(logical=True) or 1, 8))
        else:
            max_procs = max(1, min(os.cpu_count() or 1, 8))

    with mp.Pool(processes=max_procs) as pool:
        per_proc = [pool.apply_async(cpu_sha256_worker, (duration_s,)) for _ in range(max_procs)]
        multi_bytes = sum(p.get() for p in per_proc)
    multi_bps = multi_bytes / duration_s

    return {
        "algorithm": "sha256",
        "duration_s": duration_s,
        "single_thread_bytes_per_sec": single_bps,
        "multi_process_bytes_per_sec": multi_bps,
        "processes": max_procs,
        "single_thread_human": format_bytes_per_sec(single_bps),
        "multi_process_human": format_bytes_per_sec(multi_bps),
    }


def bench_ram_numpy(buffer_size_bytes: int, iterations: int = 5):
    # Allocate
    a = np.random.randint(0, 255, size=buffer_size_bytes, dtype=np.uint8)
    b = np.empty_like(a)

    # Copy (read+write) throughput
    copy_times = []
    for _ in range(iterations):
        t0 = time.perf_counter()
        np.copyto(b, a)
        t1 = time.perf_counter()
        copy_times.append(t1 - t0)
    copy_time = min(copy_times)
    copy_throughput = buffer_size_bytes / copy_time

    # Write (memset) throughput
    fill_times = []
    for _ in range(iterations):
        t0 = time.perf_counter()
        b.fill(0)
        t1 = time.perf_counter()
        fill_times.append(t1 - t0)
    fill_time = min(fill_times)
    fill_throughput = buffer_size_bytes / fill_time

    # Read (sum) throughput
    read_times = []
    for _ in range(iterations):
        t0 = time.perf_counter()
        _ = int(a.sum(dtype=np.uint64))
        t1 = time.perf_counter()
        read_times.append(t1 - t0)
    read_time = min(read_times)
    read_throughput = buffer_size_bytes / read_time

    return {
        "buffer_size_bytes": buffer_size_bytes,
        "copy_bytes_per_sec": copy_throughput,
        "write_bytes_per_sec": fill_throughput,
        "read_bytes_per_sec": read_throughput,
        "copy_human": format_bytes_per_sec(copy_throughput),
        "write_human": format_bytes_per_sec(fill_throughput),
        "read_human": format_bytes_per_sec(read_throughput),
    }


def bench_ram_fallback(buffer_size_bytes: int, iterations: int = 3):
    src = bytearray(os.urandom(buffer_size_bytes))
    dst = bytearray(buffer_size_bytes)

    # Copy
    copy_times = []
    for _ in range(iterations):
        t0 = time.perf_counter()
        dst[:] = src
        t1 = time.perf_counter()
        copy_times.append(t1 - t0)
    copy_time = min(copy_times)
    copy_throughput = buffer_size_bytes / max(copy_time, 1e-9)

    # Write
    write_times = []
    for _ in range(iterations):
        t0 = time.perf_counter()
        for i in range(0, buffer_size_bytes, 4096):
            dst[i : i + 4096] = b"\x00" * min(4096, buffer_size_bytes - i)
        t1 = time.perf_counter()
        write_times.append(t1 - t0)
    write_time = min(write_times)
    write_throughput = buffer_size_bytes / max(write_time, 1e-9)

    # Read
    read_times = []
    for _ in range(iterations):
        t0 = time.perf_counter()
        _ = sum(src)
        t1 = time.perf_counter()
        read_times.append(t1 - t0)
    read_time = min(read_times)
    read_throughput = buffer_size_bytes / max(read_time, 1e-9)

    return {
        "buffer_size_bytes": buffer_size_bytes,
        "copy_bytes_per_sec": copy_throughput,
        "write_bytes_per_sec": write_throughput,
        "read_bytes_per_sec": read_throughput,
        "copy_human": format_bytes_per_sec(copy_throughput),
        "write_human": format_bytes_per_sec(write_throughput),
        "read_human": format_bytes_per_sec(read_throughput),
    }


def bench_ram(target_bytes: int | None = None):
    # Choose buffer size conservatively: min(256 MiB, 10% of total RAM, >= 64 MiB)
    total_mem = None
    if psutil is not None:
        try:
            total_mem = psutil.virtual_memory().total
        except Exception:
            total_mem = None
    if target_bytes is None:
        cap = 256 * 1024 * 1024
        ten_percent = int((total_mem or cap) * 0.10)
        target_bytes = max(64 * 1024 * 1024, min(cap, ten_percent))

    if np is not None:
        try:
            res = bench_ram_numpy(target_bytes)
            res["implementation"] = "numpy"
            return res
        except Exception:
            pass
    res = bench_ram_fallback(target_bytes)
    res["implementation"] = "python"
    return res


def bench_network(timeout_s: int = 60):
    speedtest = safe_import("speedtest")
    if speedtest is None:
        return {"error": "speedtest module not available"}
    try:
        st = speedtest.Speedtest()
        st.get_best_server()
        # The speedtest module APIs do not accept a 'timeout' kw for download/upload in some versions
        # so we omit it for compatibility and rely on module-level timeouts.
        download_bps = st.download()
        upload_bps = st.upload(pre_allocate=False)
        ping_ms = st.results.ping
        return {
            "download_bits_per_sec": float(download_bps),
            "upload_bits_per_sec": float(upload_bps),
            "ping_ms": float(ping_ms),
            "download_human": format_bytes_per_sec(download_bps / 8.0),
            "upload_human": format_bytes_per_sec(upload_bps / 8.0),
        }
    except Exception as e:
        return {"error": str(e)}


def bench_gpu():
    # Try PyTorch CUDA
    torch = safe_import("torch")
    results = {"available": False}
    try:
        if torch is not None and torch.cuda.is_available():
            device_name = torch.cuda.get_device_name(0)
            results["available"] = True
            results["device"] = device_name
            # Simple GEMM benchmark
            import torch as T

            N = 1024
            a = T.randn((N, N), device="cuda")
            b = T.randn((N, N), device="cuda")
            # Warm-up
            _ = a @ b
            T.cuda.synchronize()
            t0 = time.perf_counter()
            _ = a @ b
            T.cuda.synchronize()
            t1 = time.perf_counter()
            dt = max(t1 - t0, 1e-9)
            # 2*N^3 FLOPs for matrix multiply
            gflops = (2 * (N ** 3)) / dt / 1e9
            results["gemm_gflops"] = gflops
            results["gemm_time_s"] = dt
        else:
            # Try nvidia-smi detection
            if shutil.which("nvidia-smi"):
                try:
                    out = subprocess.check_output(["nvidia-smi", "--query-gpu=name,memory.total", "--format=csv,noheader"], text=True)
                    results["nvidia_smi"] = out.strip()
                except Exception:
                    pass
    except Exception as e:
        results["error"] = str(e)
    return results


def compute_memory_x_multiple(copy_bps: float, baseline_gbps: float = 1.0) -> float:
    # Define 1x as 1 GB/s copy throughput by convention
    gbps = copy_bps / (1024 ** 3)
    return gbps / baseline_gbps


def gather_system_info():
    info = {
        "platform": platform.platform(),
        "python": sys.version.split("\n")[0],
        "cpu_count": os.cpu_count(),
    }
    if psutil is not None:
        try:
            info["memory_total_bytes"] = psutil.virtual_memory().total
            info["memory_available_bytes"] = psutil.virtual_memory().available
            info["cpu_logical_count"] = psutil.cpu_count(logical=True)
            info["cpu_physical_cores"] = psutil.cpu_count(logical=False)
        except Exception:
            pass
    return info


def main():
    parser = argparse.ArgumentParser(description="System benchmark: CPU, RAM, NETWORK, GPU")
    parser.add_argument("--json", dest="json_path", default=None, help="Path to write JSON results")
    parser.add_argument("--cpu-seconds", type=float, default=3.0, help="Seconds per CPU sub-test")
    parser.add_argument("--net-timeout", type=int, default=60, help="Network timeout seconds")
    parser.add_argument("--ram-bytes", type=str, default=None, help="RAM buffer size (e.g., 256M, 1G)")
    # Scaled hardware/perf modeling
    parser.add_argument("--scale-down", type=float, default=0.69, help="Hardware scale-down fraction (0.67-0.71 → 69% default)")
    parser.add_argument("--perf-retain", type=float, default=0.27, help="Performance retained fraction after scale-down (0.25-0.30 → 27% default)")
    args = parser.parse_args()

    # Parse RAM size override
    ram_bytes_override = None
    if args.ram_bytes:
        s = args.ram_bytes.strip().upper()
        try:
            if s.endswith("G"):
                ram_bytes_override = int(float(s[:-1]) * (1024 ** 3))
            elif s.endswith("M"):
                ram_bytes_override = int(float(s[:-1]) * (1024 ** 2))
            elif s.endswith("K"):
                ram_bytes_override = int(float(s[:-1]) * 1024)
            else:
                ram_bytes_override = int(s)
        except Exception:
            print(f"Invalid --ram-bytes value: {args.ram_bytes}", file=sys.stderr)

    # Baseline user-provided theoretical config (interpreted as maxima)
    theoretical_baseline = {
        "gpus": 72,
        "cpus": 36,
        "dual_link_bandwidth_tbps": 150.0,
        "fast_memory_tb": 50.0,
        "gpu_memory_tb": 25.0,
        "gpu_mem_bandwidth_tbps": 600.0,
        "cpu_memory_tb": 20.0,
        "cpu_mem_bandwidth_tbps": 15.9,
        "cpu_cores": 3500,
        "fp4_tensor_pf": 1100.0,  # taking the lower bound in 1,400 | 1,100^2
        "fp8_pf": 720.0,
        "int8_pf": 23.0,
        "fp16_pf": 360.0,
        "tf32_pf": 180.0,
        "fp32_pf": 6.0,
        "fp64_tf": 0.1,  # 100 TFLOPS = 0.1 PFLOPS
        "port": "PCIe 7.0",
    }

    def clamp(val, lo, hi):
        return max(lo, min(hi, val))

    scale_down = clamp(args.scale_down, 0.67, 0.71)
    perf_retain = clamp(args.perf_retain, 0.25, 0.30)

    def scaled_config(base: dict, hw_scale: float, perf_scale: float) -> dict:
        # Hardware counts scale linearly by hw_scale; performance figures by perf_scale
        sc = dict(base)
        # Scale discrete counts
        sc["gpus"] = max(1, int(round(base["gpus"] * (1.0 - hw_scale))))
        sc["cpus"] = max(1, int(round(base["cpus"] * (1.0 - hw_scale))))
        sc["cpu_cores"] = max(1, int(round(base["cpu_cores"] * (1.0 - hw_scale))))
        # Scale capacities
        sc["fast_memory_tb"] = base["fast_memory_tb"] * (1.0 - hw_scale)
        sc["gpu_memory_tb"] = base["gpu_memory_tb"] * (1.0 - hw_scale)
        sc["cpu_memory_tb"] = base["cpu_memory_tb"] * (1.0 - hw_scale)
        # Scale bandwidths (assume interconnect scales with hardware presence)
        sc["dual_link_bandwidth_tbps"] = base["dual_link_bandwidth_tbps"] * (1.0 - hw_scale)
        sc["gpu_mem_bandwidth_tbps"] = base["gpu_mem_bandwidth_tbps"] * (1.0 - hw_scale)
        sc["cpu_mem_bandwidth_tbps"] = base["cpu_mem_bandwidth_tbps"] * (1.0 - hw_scale)
        # Scale performance separately (user’s performance loss vs hardware reduction)
        sc["fp4_tensor_pf"] = base["fp4_tensor_pf"] * (1.0 - perf_scale)
        sc["fp8_pf"] = base["fp8_pf"] * (1.0 - perf_scale)
        sc["int8_pf"] = base["int8_pf"] * (1.0 - perf_scale)
        sc["fp16_pf"] = base["fp16_pf"] * (1.0 - perf_scale)
        sc["tf32_pf"] = base["tf32_pf"] * (1.0 - perf_scale)
        sc["fp32_pf"] = base["fp32_pf"] * (1.0 - perf_scale)
        sc["fp64_tf"] = base["fp64_tf"] * (1.0 - perf_scale)
        sc["port"] = base["port"]
        sc["notes"] = {
            "hardware_scale_down": hw_scale,
            "performance_loss": perf_scale,
        }
        return sc

    scaled = scaled_config(theoretical_baseline, scale_down, perf_retain)

    results = {
        "system": gather_system_info(),
        "cpu": bench_cpu(duration_s=args.cpu_seconds),
        "ram": bench_ram(target_bytes=ram_bytes_override),
        "network": bench_network(timeout_s=args.net_timeout),
        "gpu": bench_gpu(),
        "theoretical_baseline": theoretical_baseline,
        "scaled_configuration": scaled,
    }

    # Memory X multiple
    mem_x = compute_memory_x_multiple(results["ram"]["copy_bytes_per_sec"]) if "copy_bytes_per_sec" in results["ram"] else None
    results["memory_x_multiple"] = mem_x

    # Pretty print
    print("CPU (SHA-256): single=", results["cpu"]["single_thread_human"], "multi=", results["cpu"]["multi_process_human"], f"({results['cpu']['processes']} procs)")
    if "error" in results["network"]:
        print("NETWORK: error:", results["network"]["error"])
    else:
        print("NETWORK: down=", results["network"]["download_human"], "up=", results["network"]["upload_human"], "ping=", f"{results['network']['ping_ms']:.1f} ms")
    print("RAM:", "copy=", results["ram"].get("copy_human", "-"), "write=", results["ram"].get("write_human", "-"), "read=", results["ram"].get("read_human", "-"), f"[{results['ram'].get('implementation','n/a')}]")
    if results["memory_x_multiple"] is not None:
        print(f"FREE-FORM MEMORY PERFORMANCE MULTIPLIER: {results['memory_x_multiple']:.2f}x (baseline 1 GB/s)")
    if results["gpu"].get("available"):
        g = results["gpu"]
        print(f"GPU: {g.get('device','')} GEMM {g.get('gemm_gflops',0):.1f} GFLOP/s in {g.get('gemm_time_s',0):.3f}s")
    else:
        if "nvidia_smi" in results["gpu"]:
            print("GPU: detected via nvidia-smi, CUDA libs not available for benchmarking")
        else:
            print("GPU: not available or CUDA not detected")

    if args.json_path:
        try:
            with open(args.json_path, "w", encoding="utf-8") as f:
                json.dump(results, f, indent=2)
        except Exception as e:
            print(f"Failed to write JSON: {e}", file=sys.stderr)

    # Also print raw JSON for programmatic consumption
    print("\nRAW_JSON_BEGIN")
    print(json.dumps(results))
    print("RAW_JSON_END")


if __name__ == "__main__":
    main()

