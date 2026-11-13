#!/bin/bash
# diagnostics/check_dist.sh - Ready-to-run job: process placement and RCCL all_reduce,
# all GPUs of a node.
# Usage: sbatch diagnostics/check_dist.sh
#        sbatch --constraint=MI250 --gpus-per-node=8 diagnostics/check_dist.sh   # MI250X
# Ref: https://dci.dci-gitlab.cines.fr/webextranet/software_stack/libraries/index.html
#SBATCH --account=<project>
#SBATCH --constraint=MI300
#SBATCH --nodes=1
#SBATCH --gpus-per-node=4
#SBATCH --exclusive
#SBATCH --time=00:10:00
#SBATCH --job-name=check_dist
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.out

set -euo pipefail
source env.sh

cores="$(lscpu --parse=CORE | grep -v '^#' | sort -u | wc -l)"
export OMP_NUM_THREADS=$((cores / SLURM_GPUS_ON_NODE))

run torchrun --standalone --nproc_per_node="${SLURM_GPUS_ON_NODE}" diagnostics/check_dist.py