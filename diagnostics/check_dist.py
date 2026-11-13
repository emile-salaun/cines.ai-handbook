#!/usr/bin/env python3
"""Process placement and RCCL all_reduce check, one process per GPU (torchrun).

Usage: sbatch diagnostics/check_dist.sh   (MI250X: --constraint=MI250 --gpus-per-node=8)
Ref: https://dci.dci-gitlab.cines.fr/webextranet/software_stack/libraries/index.html
"""

import os
import socket
import sys

import torch
import torch.distributed as dist

# MI300A: slow bf16 GEMMs with hipBLASLt; TORCH_BLAS_PREFER_HIPBLASLT=0 is not enough.
torch.backends.cuda.preferred_blas_library("cublas")


def placement(rank, local_rank):
    device = local_rank % torch.cuda.device_count()
    visible = os.environ.get("ROCR_VISIBLE_DEVICES", "")
    gpu = visible.split(",")[device] if visible else str(device)
    arch = torch.cuda.get_device_properties(device).gcnArchName.split(":")[0]
    cores = len(os.sched_getaffinity(0))
    threads = os.environ.get("OMP_NUM_THREADS", "<unset>")
    host = socket.gethostname()
    return f"host={host} rank={rank} gpu={gpu} ({arch}) cores={cores} omp={threads}"


def main():
    if "WORLD_SIZE" not in os.environ:  # single process, no torchrun
        print(placement(0, 0))
        return

    local_rank = int(os.environ["LOCAL_RANK"])
    torch.cuda.set_device(local_rank % torch.cuda.device_count())
    dist.init_process_group(backend="nccl")  # RCCL on ROCm
    rank, world = dist.get_rank(), dist.get_world_size()

    lines = [None] * world
    dist.all_gather_object(lines, placement(rank, local_rank))

    value = torch.tensor([rank + 1.0], device="cuda")
    dist.all_reduce(value)
    ok = value.item() == world * (world + 1) / 2

    if rank == 0:
        print("\n".join(lines))
        print(f"{'OK' if ok else 'FAIL'}: all_reduce over {world} processes = {value.item():.0f}")
    dist.destroy_process_group()
    if not ok:
        sys.exit(1)


if __name__ == "__main__":
    main()