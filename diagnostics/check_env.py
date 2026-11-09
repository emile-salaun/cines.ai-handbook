#!/usr/bin/env python3
"""Environment and GPU check for the prebuilt AI environment (single process).

Prints the environment (Python, PyTorch/ROCm, modules, key variables), checks
the RCCL network plugin, lists the visible GPUs and runs a matmul on each one.
With --model, also loads a model offline from HF_HOME (download it first on a
login node with setup/download_assets.sh). Exits with status 1 if a check fails.

MI300A: GPUs are reported as gfx942 (one APU per GPU, 4 per node).
MI250X: GPUs are reported as gfx90a (one GCD per GPU, 8 per node).

Usage (from the repository root):
    sbatch slurm/single_gpu.slurm diagnostics/check_env.py [--model <repo_id>]
    srun python diagnostics/check_env.py          # in an interactive allocation
Example:
    sbatch slurm/single_gpu.slurm diagnostics/check_env.py --model Qwen/Qwen2.5-0.5B
Ref: Adastra doc, Software stack, libraries (PyTorch, aws-ofi-rccl, MIOpen):
    https://dci.dci-gitlab.cines.fr/webextranet/software_stack/libraries/index.html
"""

import argparse
import glob
import os
import socket
import sys

import torch

# MI300A: slow bf16 GEMMs with hipBLASLt; TORCH_BLAS_PREFER_HIPBLASLT=0 is not enough.
torch.backends.cuda.preferred_blas_library("cublas")

ENV_VARS = (
    "HANDBOOK_ACCOUNT",
    "VIRTUAL_ENV",
    "HF_HOME",
    "HF_HUB_OFFLINE",
    "HF_DATASETS_CACHE",
    "MIOPEN_USER_DB_PATH",
    "ROCR_VISIBLE_DEVICES",
    "OMP_NUM_THREADS",
    "NCCL_NET_PLUGIN",
    "NCCL_DEBUG",
)
failures = []


def check(ok, label, detail=""):
    print(f"[{'OK' if ok else 'FAIL'}] {label}" + (f": {detail}" if detail else ""), flush=True)
    if not ok:
        failures.append(label)
    return ok


def parse_args():
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument(
        "--gpus",
        type=int,
        default=int(os.environ.get("SLURM_GPUS_ON_NODE", 0)) or None,
        help="expected number of visible GPUs (default: $SLURM_GPUS_ON_NODE)",
    )
    parser.add_argument("--model", help="Hugging Face model id to load offline (on CPU)")
    return parser.parse_args()


def report_env():
    print(f"Host {socket.gethostname()}, Python {sys.version.split()[0]} ({sys.executable})")
    print(f"PyTorch {torch.__version__}, HIP {torch.version.hip}")
    modules = os.environ.get("LOADEDMODULES", "<none>").replace(":", " ")
    print(f"Modules: {modules}")
    for var in ENV_VARS:
        print(f"  {var}={os.environ.get(var, '<unset>')}")
    check(torch.version.hip is not None, "PyTorch is a ROCm build")
    # RCCL uses Slingshot through the aws-ofi-rccl plugin (librccl-net*.so).
    # Only needed for multi-node runs: reported, not counted as a failure.
    dirs = [d for d in os.environ.get("LD_LIBRARY_PATH", "").split(":") if d]
    plugins = [p for d in dirs for p in glob.glob(os.path.join(d, "librccl-net*.so"))]
    if plugins:
        print(f"[OK] aws-ofi-rccl plugin: {plugins[0]}")
    else:
        print("[WARN] aws-ofi-rccl plugin not found in LD_LIBRARY_PATH (multi-node RCCL)")


def check_gpus(n_expected):
    if not check(torch.cuda.is_available(), "GPUs visible to PyTorch"):
        return
    count = torch.cuda.device_count()
    check(n_expected in (None, count), "GPU count", f"{count} (expected {n_expected or 'any'})")
    for idx in range(count):
        props = torch.cuda.get_device_properties(idx)
        arch = props.gcnArchName.split(":")[0]
        x = torch.ones(1024, 1024, device=f"cuda:{idx}")
        ok = (x @ x)[0, 0].item() == 1024.0 and arch in torch.cuda.get_arch_list()
        detail = f"{props.name}, {arch}, {props.total_memory / 2**30:.0f} GiB"
        check(ok, f"GPU {idx} matmul", detail)
    from torch.cuda import nccl

    version = ".".join(map(str, nccl.version()))
    check(torch.distributed.is_nccl_available(), "RCCL backend", version)


def check_model(repo_id):
    check(os.environ.get("HF_HUB_OFFLINE") == "1", "HF_HUB_OFFLINE=1")
    try:
        from transformers import AutoModel

        model = AutoModel.from_pretrained(repo_id)
        n_params = sum(p.numel() for p in model.parameters()) / 1e6
        check(True, f"offline load of {repo_id}", f"{n_params:.0f}M parameters")
    except Exception as exc:  # report the error as a failed check
        check(False, f"offline load of {repo_id}", exc)


def main():
    args = parse_args()
    report_env()
    check_gpus(args.gpus)
    if args.model:
        check_model(args.model)
    if failures:
        print(f"{len(failures)} check(s) failed: {', '.join(failures)}")
        sys.exit(1)
    print("All checks passed.")


if __name__ == "__main__":
    main()
