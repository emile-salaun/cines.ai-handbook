#!/bin/bash
# =============================================================================
# slurm/single_gpu.sh - Template: one Python process on one GPU (one APU on
# MI300A, one GCD on MI250X), on a shared node.
#
# Copy it, adapt the lines marked EDIT, submit from the repository root:
#   mkdir -p jobs && cp slurm/single_gpu.sh jobs/my_job.sh
#   sbatch jobs/my_job.sh
# MI250X: --constraint=MI250 and --cpus-per-task=8.
# Ref: Adastra doc, Job submission (batch scripts, allocating a single GPU):
#      https://dci.dci-gitlab.cines.fr/webextranet/user_support/index.html
# =============================================================================
#SBATCH --account=<project>           # leave as is: env.sh sets your project (SBATCH_ACCOUNT)
#SBATCH --constraint=MI300            # EDIT: node type, MI300 (MI300A) or MI250 (MI250X)
#SBATCH --nodes=1                     # one node
#SBATCH --ntasks=1                    # one process
#SBATCH --gpus-per-node=1             # one GPU; at least one is required on shared nodes
#SBATCH --cpus-per-task=24            # EDIT: CPU cores, 24 per APU (MI300A), 8 per GCD (MI250X)
#SBATCH --threads-per-core=1          # physical cores only
#SBATCH --time=00:15:00               # EDIT: maximum run time (HH:MM:SS); the job is killed after it
#SBATCH --job-name=my_job             # EDIT: name shown by squeue and used for the log file
#SBATCH --output=logs/%x_%j.out       # log file: logs/<job name>_<job id>.out
#SBATCH --error=logs/%x_%j.out        # errors in the same file

set -euo pipefail                     # stop at the first error
source env.sh                         # project, Python environment, offline mode, MIOpen cache

export OMP_NUM_THREADS="${SLURM_CPUS_PER_TASK}"    # CPU threads = allocated cores

# EDIT: your command. `run` adds start and end lines (elapsed time) to the log.
run python my_script.py --my-arg 1