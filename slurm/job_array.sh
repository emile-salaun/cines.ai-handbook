#!/bin/bash
# slurm/job_array.sh - Template: independent single-GPU runs; task i runs the
# script with the arguments of line i+1 of jobs/args.txt (at most 128 tasks).
# Usage: mkdir -p jobs && cp slurm/job_array.sh jobs/my_sweep.sh, adapt the EDIT lines,
#        sbatch --array=0-$(( $(wc -l < jobs/args.txt) - 1 )) jobs/my_sweep.sh
# MI250X: --constraint=MI250 --cpus-per-task=8
# Ref: https://dci.dci-gitlab.cines.fr/webextranet/user_support/index.html
#SBATCH --account=<project>           # leave as is: env.sh sets your project (SBATCH_ACCOUNT)
#SBATCH --constraint=MI300            # EDIT: node type, MI300 (MI300A) or MI250 (MI250X)
#SBATCH --array=0-3                   # default 4 tasks; set it on the sbatch command line
#SBATCH --nodes=1                     # one node per task
#SBATCH --ntasks=1                    # one process per task
#SBATCH --gpus-per-node=1             # one GPU per task; at least one is required on shared nodes
#SBATCH --cpus-per-task=24            # EDIT: CPU cores, 24 per APU (MI300A), 8 per GCD (MI250X)
#SBATCH --threads-per-core=1          # physical cores only
#SBATCH --time=00:15:00               # EDIT: maximum run time of one task (HH:MM:SS)
#SBATCH --job-name=my_sweep           # EDIT: name shown by squeue and used for the log files
#SBATCH --output=logs/%x_%A_%a.out    # log file: logs/<job name>_<array id>_<task id>.out
#SBATCH --error=logs/%x_%A_%a.out     # errors in the same file

set -euo pipefail                     # stop at the first error
source env.sh                         # project, Python environment, offline mode, MIOpen cache

args_file=jobs/args.txt               # EDIT: arguments file, one run per line

line="$(sed -n "$((SLURM_ARRAY_TASK_ID + 1))p" "${args_file}")"
if [[ -z "${line}" ]]; then
    echo "[job] ERROR: no line $((SLURM_ARRAY_TASK_ID + 1)) in ${args_file}" >&2
    exit 1
fi
read -ra task_args <<<"${line}"

export OMP_NUM_THREADS="${SLURM_CPUS_PER_TASK}"    # CPU threads = allocated cores

# EDIT: your script; the arguments of this task are appended.
python my_script.py "${task_args[@]}"