#!/bin/bash
# =============================================================================
# slurm/single_node.slurm - torchrun on all GPUs of one node (one process per
# GPU), the node is reserved for the job.
#
# <project> is replaced by your project: env.sh exports SBATCH_ACCOUNT,
# which overrides the #SBATCH --account line.
# MI250X: sbatch --constraint=MI250 --gpus-per-node=8 slurm/single_node.slurm ...
#
# Usage (from the repository root, after `source env.sh`):
#   sbatch slurm/single_node.slurm <script.py> [args]
# Example:
#   sbatch slurm/single_node.slurm diagnostics/check_dist.py
# Ref: Adastra doc, Job submission (batch scripts):
#      https://dci.dci-gitlab.cines.fr/webextranet/user_support/index.html
# =============================================================================
#SBATCH --account=<project>
#SBATCH --constraint=MI300
#SBATCH --nodes=1
#SBATCH --gpus-per-node=4             # 4 APUs on MI300A, 8 GCDs on MI250X
#SBATCH --exclusive
#SBATCH --time=00:15:00
#SBATCH --job-name=single_node
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.out       # same file as --output

set -euo pipefail
source env.sh

# OpenMP threads per process: the node's physical cores shared between its GPUs
# (24 on MI300A, 8 on MI250X).
cores="$(lscpu --parse=CORE | grep -v '^#' | sort -u | wc -l)"
export OMP_NUM_THREADS=$((cores / SLURM_GPUS_ON_NODE))

handbook_run torchrun --standalone --nproc_per_node="${SLURM_GPUS_ON_NODE}" "$@"
