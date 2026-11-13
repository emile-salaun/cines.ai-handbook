#!/bin/bash
# =============================================================================
# inference/generate_hf.sh - Ready-to-run job: batch text generation with
# Transformers on one GPU (inference/generate_hf.py).
# Built from slurm/single_gpu.sh.
#
# Usage (from the repository root, after `source env.sh` and
# `bash setup/download_assets.sh`):
#   sbatch inference/generate_hf.sh
# MI250X:
#   sbatch --constraint=MI250 --cpus-per-task=8 inference/generate_hf.sh
# Log: logs/generate_hf_<job id>.out; answers: $OUTPUT_DIR/generate_hf/<job id>.jsonl
# Ref: Transformers, Generation:
#      https://huggingface.co/docs/transformers/main_classes/text_generation
# =============================================================================
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
run python inference/generate_hf.py