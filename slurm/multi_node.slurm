#!/bin/bash
# =============================================================================
# slurm/multi_node.slurm - torchrun on several nodes: one srun task per node,
# torchrun starts one process per GPU (c10d rendezvous on the first node).
#
# <project> is replaced by your project: env.sh exports SBATCH_ACCOUNT,
# which overrides the #SBATCH --account line.
# MI250X: sbatch --constraint=MI250 --gpus-per-node=8 slurm/multi_node.slurm ...
# To check that RCCL uses Slingshot, submit with
#   NCCL_DEBUG=INFO NCCL_DEBUG_SUBSYS=INIT,NET sbatch slurm/multi_node.slurm ...
# and look for "NET/OFI Selected Provider is cxi" in the log.
#
# Usage (from the repository root, after `source env.sh`):
#   sbatch [--nodes=N] slurm/multi_node.slurm <script.py> [args]
# Example:
#   sbatch slurm/multi_node.slurm diagnostics/check_dist.py
# Ref: Adastra doc, Software stack, libraries (Torch elastic, aws-ofi-rccl):
#      https://dci.dci-gitlab.cines.fr/webextranet/software_stack/libraries/index.html
# =============================================================================
#SBATCH --account=<project>
#SBATCH --constraint=MI300
#SBATCH --nodes=2
#SBATCH --gpus-per-node=4             # 4 APUs on MI300A, 8 GCDs on MI250X
#SBATCH --exclusive
#SBATCH --time=00:15:00
#SBATCH --job-name=multi_node
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.out       # same file as --output

set -euo pipefail
source env.sh

MASTER_ADDR="$(scontrol show hostnames "${SLURM_JOB_NODELIST}" | head -n 1)"

# OpenMP threads per process: the node's physical cores shared between its GPUs
# (24 on MI300A, 8 on MI250X).
cores="$(lscpu --parse=CORE | grep -v '^#' | sort -u | wc -l)"
export OMP_NUM_THREADS=$((cores / SLURM_GPUS_ON_NODE))

handbook_run srun --ntasks-per-node=1 --gpus-per-task="${SLURM_GPUS_ON_NODE}" \
    --cpu-bind=none --mem-bind=none --label \
    torchrun --nnodes="${SLURM_NNODES}" --nproc_per_node="${SLURM_GPUS_ON_NODE}" \
    --rdzv-id="${SLURM_JOB_ID}" --rdzv-backend=c10d \
    --rdzv-endpoint="${MASTER_ADDR}:29400" --max-restarts=0 \
    "$@"
