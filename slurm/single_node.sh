#!/bin/bash
# slurm/single_node.sh - Template: torchrun on all GPUs of one node.
# Usage: mkdir -p jobs && cp slurm/single_node.sh jobs/my_job.sh, adapt the EDIT lines,
#        sbatch jobs/my_job.sh
# MI250X: --constraint=MI250 --gpus-per-node=8
# Ref: https://dci.dci-gitlab.cines.fr/webextranet/user_support/index.html
#SBATCH --account=<project>           # leave as is: env.sh sets your project (SBATCH_ACCOUNT)
#SBATCH --constraint=MI300            # EDIT: node type, MI300 (MI300A) or MI250 (MI250X)
#SBATCH --nodes=1                     # one node
#SBATCH --gpus-per-node=4             # EDIT: all GPUs of the node, 4 (MI300A) or 8 (MI250X)
#SBATCH --exclusive                   # whole node: all its cores and memory
#SBATCH --time=00:15:00               # EDIT: maximum run time (HH:MM:SS); the job is killed after it
#SBATCH --job-name=my_job             # EDIT: name shown by squeue and used for the log file
#SBATCH --output=logs/%x_%j.out       # log file: logs/<job name>_<job id>.out
#SBATCH --error=logs/%x_%j.out        # errors in the same file

set -euo pipefail                     # stop at the first error
source env.sh                         # project, Python environment, offline mode, MIOpen cache

# CPU threads per process: the node's physical cores shared between its GPUs
# (24 on MI300A, 8 on MI250X).
cores="$(lscpu --parse=CORE | grep -v '^#' | sort -u | wc -l)"
export OMP_NUM_THREADS=$((cores / SLURM_GPUS_ON_NODE))

# EDIT: your script. torchrun starts one process per GPU of the node.
torchrun --standalone --nproc_per_node="${SLURM_GPUS_ON_NODE}" my_script.py --my-arg 1