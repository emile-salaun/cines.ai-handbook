#!/bin/bash
# =============================================================================
# slurm/single_gpu.slurm - One Python process on one GPU (one APU on MI300A,
# one GCD on MI250X), on a shared node.
#
# <project> is replaced by your project: env.sh exports SBATCH_ACCOUNT,
# which overrides the #SBATCH --account line.
# MI250X: sbatch --constraint=MI250 --cpus-per-task=8 slurm/single_gpu.slurm ...
#
# Usage (from the repository root, after `source env.sh`):
#   sbatch slurm/single_gpu.slurm <script.py> [args]
# Example:
#   sbatch slurm/single_gpu.slurm diagnostics/check_env.py --model Qwen/Qwen2.5-0.5B
# Ref: Adastra doc, Job submission (batch scripts, allocating a single GPU):
#      https://dci.dci-gitlab.cines.fr/webextranet/user_support/index.html
# =============================================================================
#SBATCH --account=<project>
#SBATCH --constraint=MI300
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --gpus-per-node=1             # You must ask for at least one GPU when using shared nodes
#SBATCH --cpus-per-task=24            # 24 per APU on MI300A, 8 per GCD on MI250X
#SBATCH --threads-per-core=1          # physical cores only (no SMT)
#SBATCH --time=00:15:00
#SBATCH --job-name=single_gpu
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.out       # same file as --output

set -euo pipefail
source env.sh

export OMP_NUM_THREADS="${SLURM_CPUS_PER_TASK}"
handbook_run python "$@"
