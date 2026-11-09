#!/usr/bin/env bash
# =============================================================================
# slurm/interactive.sh - Interactive allocation (salloc) of GPUs on one node.
#
# salloc opens a new shell holding the allocation; commands sent with `srun`
# run on the compute node. Source env.sh again in that shell (job variables:
# offline mode, MIOpen cache). `exit` releases the allocation.
# The project comes from env.sh (SALLOC_ACCOUNT).
#
# Usage (from the repository root, after `source env.sh`):
#   bash slurm/interactive.sh [n_gpus]               # default 4: one MI300A node
#   CONSTRAINT=MI250 bash slurm/interactive.sh 8     # one MI250X node
#   TIME=01:00:00 bash slurm/interactive.sh          # longer (default 30 min)
# Example, in the salloc shell:
#   source env.sh
#   srun python diagnostics/check_env.py
#   OMP_NUM_THREADS=24 srun torchrun --standalone --nproc_per_node=4 \
#       diagnostics/check_dist.py
# Ref: Adastra doc, Job submission (interactive jobs):
#      https://dci.dci-gitlab.cines.fr/webextranet/user_support/index.html
# =============================================================================
set -euo pipefail
cd "$(dirname "$0")/.."
source env.sh

CONSTRAINT="${CONSTRAINT:-MI300}"
GPUS="${1:-4}"
TIME="${TIME:-00:30:00}"
case "${CONSTRAINT}" in
    MI300) CPUS_PER_GPU=24 ;;
    MI250) CPUS_PER_GPU=8 ;;
    *) echo "[interactive] ERROR: CONSTRAINT must be MI300 or MI250." >&2; exit 1 ;;
esac

# --gpus-per-node: at least one GPU must be requested on shared nodes.
exec salloc --constraint="${CONSTRAINT}" --nodes=1 --ntasks=1 \
    --gpus-per-node="${GPUS}" --cpus-per-task=$((GPUS * CPUS_PER_GPU)) \
    --threads-per-core=1 --time="${TIME}"
