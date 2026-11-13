#!/bin/bash
# inference/generate_hf.sh - Ready-to-run job: batch generation with Transformers on
# one GPU.
# Usage: sbatch inference/generate_hf.sh
#        sbatch --constraint=MI250 --cpus-per-task=8 inference/generate_hf.sh   # MI250X
# Ref: https://huggingface.co/docs/transformers/main_classes/text_generation
#SBATCH --account=<project>
#SBATCH --constraint=MI300
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --gpus-per-node=1
#SBATCH --cpus-per-task=24
#SBATCH --threads-per-core=1
#SBATCH --time=00:10:00
#SBATCH --job-name=generate_hf
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.out

set -euo pipefail
source env.sh

export OMP_NUM_THREADS="${SLURM_CPUS_PER_TASK}"
python inference/generate_hf.py