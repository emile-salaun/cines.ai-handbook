#!/bin/bash
# =============================================================================
# slurm/job_array.slurm - Independent single-GPU runs (sweeps), one per array
# task. Task i runs the script with the arguments on line i+1 of the
# arguments file (one run per line, arguments without spaces).
#
# <project> is replaced by your project: env.sh exports SBATCH_ACCOUNT,
# which overrides the #SBATCH --account line.
# Set the array size from the file on the command line (Adastra: at most 128
# tasks; add %K to run at most K tasks at once).
# MI250X: sbatch --constraint=MI250 --cpus-per-task=8 ...
# Output: logs/<job name>_<array job id>_<task id>.out
#
# Usage (from the repository root, after `source env.sh`):
#   sbatch --array=0-$(( $(wc -l < <args_file>) - 1 )) \
#       slurm/job_array.slurm <script.py> <args_file>
# Example args_file (2 lines -> --array=0-1):
#   --lr 1e-3 --seed 0
#   --lr 1e-4 --seed 0
# Ref: Adastra doc, Job submission (job array):
#      https://dci.dci-gitlab.cines.fr/webextranet/user_support/index.html
# =============================================================================
#SBATCH --account=<project>
#SBATCH --constraint=MI300
#SBATCH --array=0-3                   # default: 4 tasks; override on the command line
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --gpus-per-node=1             # You must ask for at least one GPU when using shared nodes
#SBATCH --cpus-per-task=24            # 24 per APU on MI300A, 8 per GCD on MI250X
#SBATCH --threads-per-core=1          # physical cores only (no SMT)
#SBATCH --time=00:15:00               # per task
#SBATCH --job-name=job_array
#SBATCH --output=logs/%x_%A_%a.out
#SBATCH --error=logs/%x_%A_%a.out    # same file as --output

set -euo pipefail
source env.sh

script="${1:?Usage: sbatch slurm/job_array.slurm <script.py> <args_file>}"
args_file="${2:?Usage: sbatch slurm/job_array.slurm <script.py> <args_file>}"

line="$(sed -n "$((SLURM_ARRAY_TASK_ID + 1))p" "${args_file}")"
if [[ -z "${line}" ]]; then
    echo "[job] ERROR: no line $((SLURM_ARRAY_TASK_ID + 1)) in ${args_file}" >&2
    exit 1
fi
read -ra task_args <<<"${line}"

export OMP_NUM_THREADS="${SLURM_CPUS_PER_TASK}"
handbook_run python "${script}" "${task_args[@]}"
