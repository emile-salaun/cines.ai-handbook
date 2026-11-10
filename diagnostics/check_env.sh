#!/bin/bash
# =============================================================================
# diagnostics/check_env.sh - Ready-to-run job: environment and GPU check on one
# GPU (diagnostics/check_env.py), with the offline load of the test model.
# Built from slurm/single_gpu.sh.
#
# Usage (from the repository root, after `source env.sh` and
# `bash setup/download_assets.sh`):
#   sbatch diagnostics/check_env.sh
# MI250X:
#   sbatch --constraint=MI250 --cpus-per-task=8 diagnostics/check_env.sh
# Log: logs/check_env_<job id>.out
# Ref: Adastra doc, Job submission (allocating a single GPU):
#      https://dci.dci-gitlab.cines.fr/webextranet/user_support/index.html
# =============================================================================
#SBATCH --account=<project>
#SBATCH --constraint=MI300
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --gpus-per-node=1
#SBATCH --cpus-per-task=24
#SBATCH --threads-per-core=1
#SBATCH --time=00:10:00
#SBATCH --job-name=check_env
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.out

set -euo pipefail
source env.sh

export OMP_NUM_THREADS="${SLURM_CPUS_PER_TASK}"
run python diagnostics/check_env.py --model Qwen/Qwen2.5-0.5B