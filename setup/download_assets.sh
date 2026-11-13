#!/usr/bin/env bash
# setup/download_assets.sh - Download the models and the dataset of the handbook
# examples (HF_HOME, $WORKDIR/datasets) on a login node. Your own: hf download.
# Usage: bash setup/download_assets.sh
# Ref: https://dci.dci-gitlab.cines.fr/webextranet/software_stack/libraries/index.html
set -euo pipefail

if (($# > 0)); then
    echo "[download_assets] ERROR: no arguments. Your own model or dataset:" \
        "run 'hf download <repo_id>' directly (chapter Data & models)." >&2
    exit 1
fi

# SLURMD_NODENAME: set on compute nodes only (batch scripts, srun steps).
if [[ -n "${SLURMD_NODENAME:-}" ]]; then
    echo "[download_assets] ERROR: run on a login node, not in a job or with srun" \
        "(no internet on compute nodes)." >&2
    exit 1
fi

# shellcheck source=env.sh
source "$(dirname "${BASH_SOURCE[0]}")/../env.sh"
unset HF_HUB_OFFLINE    # in case your shell has it set

if ! command -v hf >/dev/null 2>&1; then
    echo "[download_assets] ERROR: 'hf' command not found (AI environment not active?)." >&2
    exit 1
fi

# --- Handbook assets (add the models/datasets of new chapters here) -----------
MODELS=(
    Qwen/Qwen2.5-0.5B               # 1 getting started (check_env --model), 2 check_data
    Qwen/Qwen2.5-0.5B-Instruct      # 3 inference (generate_hf.py)
)
DATASETS=(                          # "<repo_id> <directory name in $WORKDIR/datasets>"
    "Salesforce/wikitext wikitext"
)
DATASETS_DIR="${WORKDIR}/datasets"  # your datasets, loaded by path

# Print the command, then run it.
hf_download() {
    echo "[download_assets] hf download $*"
    hf download "$@"
}

echo "[download_assets] HF_HOME=${HF_HOME}  datasets: ${DATASETS_DIR}"
mkdir -p "${HF_HOME}" "${DATASETS_DIR}"

for model in "${MODELS[@]}"; do
    hf_download "${model}"
done
for entry in "${DATASETS[@]}"; do
    read -r repo_id name <<<"${entry}"
    hf_download "${repo_id}" --repo-type dataset --local-dir "${DATASETS_DIR}/${name}"
done

echo "[download_assets] done. Disk usage:"
du -sh "${HF_HOME}/hub" "${DATASETS_DIR}" 2>/dev/null || true