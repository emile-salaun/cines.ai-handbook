#!/bin/bash
# diagnostics/check_data.sh - Ready-to-run job: offline load of the handbook model and
# dataset, one GPU.
# Usage: sbatch diagnostics/check_data.sh
#        sbatch --constraint=MI250 --cpus-per-task=8 diagnostics/check_data.sh   # MI250X
# Ref: https://dci.dci-gitlab.cines.fr/webextranet/data_storage_and_transfers/index.html
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