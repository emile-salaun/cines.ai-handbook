#!/bin/bash
# =============================================================================
# diagnostics/check_data.sh - Ready-to-run job: offline load of the handbook
# model and dataset on one GPU, with sizes and load times
# (diagnostics/check_data.py).
# Built from slurm/single_gpu.sh.
#
# Usage (from the repository root, after `source env.sh` and
# `bash setup/download_assets.sh`):
#   sbatch diagnostics/check_data.sh
# MI250X:
#   sbatch --constraint=MI250 --cpus-per-task=8 diagnostics/check_data.sh
# Log: logs/check_data_<job id>.out
# Ref: Adastra doc, Data storage and transfers:
#      https://dci.dci-gitlab.cines.fr/webextranet/data_storage_and_transfers/index.html
# =============================================================================
#SBATCH --account=<project>
#SBATCH --constraint=MI300
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --gpus-per-node=1
#SBATCH --cpus-per-task=24
#SBATCH --threads-per-core=1
#SBATCH --time=00:10:00
#SBATCH --job-name=check_data
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.out

set -euo pipefail
source env.sh

export OMP_NUM_THREADS="${SLURM_CPUS_PER_TASK}"
run python diagnostics/check_data.py