#!/bin/bash
# slurm/multi_node.sh - Template: torchrun on several nodes, one srun task per node.
# Usage: mkdir -p jobs && cp slurm/multi_node.sh jobs/my_job.sh, adapt the EDIT lines,
#        sbatch jobs/my_job.sh
# MI250X: --constraint=MI250 --gpus-per-node=8
# Ref: https://dci.dci-gitlab.cines.fr/webextranet/software_stack/libraries/index.html
#SBATCH --account=<project>           # leave as is: env.sh sets your project (SBATCH_ACCOUNT)
#SBATCH --constraint=MI300            # EDIT: node type, MI300 (MI300A) or MI250 (MI250X)
#SBATCH --nodes=2                     # EDIT: number of nodes
#SBATCH --gpus-per-node=4             # EDIT: all GPUs of a node, 4 (MI300A) or 8 (MI250X)
#SBATCH --exclusive                   # whole nodes: all their cores and memory
#SBATCH --time=00:15:00               # EDIT: maximum run time (HH:MM:SS); the job is killed after it
#SBATCH --job-name=my_job             # EDIT: name shown by squeue and used for the log file
#SBATCH --output=logs/%x_%j.out       # log file: logs/<job name>_<job id>.out
#SBATCH --error=logs/%x_%j.out        # errors in the same file

set -euo pipefail                     # stop at the first error
source env.sh                         # project, Python environment, offline mode, MIOpen cache

# First node of the job: rendezvous point of torchrun.
MASTER_ADDR="$(scontrol show hostnames "${SLURM_JOB_NODELIST}" | head -n 1)"

# CPU threads per process: the node's physical cores shared between its GPUs
# (24 on MI300A, 8 on MI250X).
cores="$(lscpu --parse=CORE | grep -v '^#' | sort -u | wc -l)"
export OMP_NUM_THREADS=$((cores / SLURM_GPUS_ON_NODE))

# EDIT: your script (last line).
srun --ntasks-per-node=1 --gpus-per-task="${SLURM_GPUS_ON_NODE}" \
    --cpu-bind=none --mem-bind=none --label \
    torchrun --nnodes="${SLURM_NNODES}" --nproc_per_node="${SLURM_GPUS_ON_NODE}" \
    --rdzv-id="${SLURM_JOB_ID}" --rdzv-backend=c10d \
    --rdzv-endpoint="${MASTER_ADDR}:29400" --max-restarts=0 \
    my_script.py --my-arg 1