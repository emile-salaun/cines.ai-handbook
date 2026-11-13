#!/usr/bin/env bash
# =============================================================================
# setup/download_assets.sh - Download the models and the dataset used by the
# handbook examples into your own cache, on a login node (compute nodes have
# no internet access).
#
# Each download is a plain `hf download` command, printed before it runs.
# Your own models and datasets: run `hf download` directly (handbook chapter
# "Data & models").
#
#   models   -> ${HF_HOME}/hub, loaded by id:
#               from_pretrained("Qwen/Qwen2.5-0.5B")
#   datasets -> ${DATA_DIR}/<name>, loaded by path:
#               load_dataset("$DATA_DIR/wikitext", "wikitext-2-raw-v1")
# Jobs then run with HF_HUB_OFFLINE=1 (set by env.sh). Locations: see the
# "User settings" block of env.sh.
# Same assets for MI300A and MI250X.
#
# Usage (from anywhere, on a login node, outside any allocation):
#   bash setup/download_assets.sh
# Ref: Adastra doc, Software stack, libraries (offline Hugging Face):
#      https://dci.dci-gitlab.cines.fr/webextranet/software_stack/libraries/index.html
# =============================================================================
set -euo pipefail

if (($# > 0)); then
    echo "[download_assets] ERROR: no arguments. Your own model or dataset:" \
        "run 'hf download <repo_id>' directly (chapter Data & models)." >&2
    exit 1
fi

if [[ -n "${SLURM_JOB_ID:-}" ]]; then
    echo "[download_assets] ERROR: run on a login node, outside any allocation" \
        "(no internet on compute nodes)." >&2
    exit 1
fi

# shellcheck source=env.sh
source "$(dirname "${BASH_SOURCE[0]}")/../env.sh"
unset HF_HUB_OFFLINE

if ! command -v hf >/dev/null 2>&1; then
    echo "[download_assets] ERROR: 'hf' command not found (AI environment not active?)." >&2
    exit 1
fi

# --- Handbook assets (add the models/datasets of new chapters here) -----------
MODELS=(
    Qwen/Qwen2.5-0.5B               # 1 getting started (check_env --model), 2 check_data
    Qwen/Qwen2.5-0.5B-Instruct      # 3 inference (generate_hf.py)
)
DATASETS=(                          # "<repo_id> <local dir name in DATA_DIR>"
    "Salesforce/wikitext wikitext"
)

# Print the command, then run it.
hf_download() {
    echo "[download_assets] hf download $*"
    hf download "$@"
}

echo "[download_assets] HF_HOME=${HF_HOME}  DATA_DIR=${DATA_DIR}"
mkdir -p "${HF_HOME}" "${DATA_DIR}"

for model in "${MODELS[@]}"; do
    hf_download "${model}"
done
for entry in "${DATASETS[@]}"; do
    read -r repo_id name <<<"${entry}"
    hf_download "${repo_id}" --repo-type dataset --local-dir "${DATA_DIR}/${name}"
done

echo "[download_assets] done. Disk usage:"
du -sh "${HF_HOME}/hub" "${DATA_DIR}" 2>/dev/null || true