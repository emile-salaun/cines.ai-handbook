#!/bin/bash
# diagnostics/check_env.sh - Ready-to-run job: environment and GPU check on one GPU,
# offline model load.
# Usage: sbatch diagnostics/check_env.sh
#        sbatch --constraint=MI250 --cpus-per-task=8 diagnostics/check_env.sh   # MI250X
# Ref: https://dci.dci-gitlab.cines.fr/webextranet/user_support/index.html
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
python diagnostics/check_env.py --model Qwen/Qwen2.5-0.5B