#!/usr/bin/env bash
# =============================================================================
# setup/download_assets.sh - Download models and datasets into your own cache,
# on a login node (compute nodes have no internet access).
#
#   models   -> ${HF_HOME}/hub, loaded by id:
#               from_pretrained("Qwen/Qwen2.5-0.5B")
#   datasets -> ${DATA_DIR}/<name>, loaded by path:
#               load_dataset("$DATA_DIR/wikitext", "wikitext-2-raw-v1")
# Jobs then run with HF_HUB_OFFLINE=1 (set by env.sh). Locations: see the
# "User settings" block of env.sh.
# Gated models need a token: `hf auth login` (environment active) or HF_TOKEN.
# The token is stored in HF_TOKEN_PATH ($HOME/.cache/huggingface/token, set by
# env.sh), never in HF_HOME, which may be shared within the project.
# Same assets for MI300A and MI250X.
#
# Usage (from anywhere, on a login node):
#   bash setup/download_assets.sh                     # all handbook assets below
#   bash setup/download_assets.sh <repo_id> [hf download options]   # one asset
# Example:
#   bash setup/download_assets.sh Qwen/Qwen2.5-1.5B
# Ref: Adastra doc, Software stack, libraries (offline Hugging Face):
#      https://dci.dci-gitlab.cines.fr/webextranet/software_stack/libraries/index.html
# =============================================================================
set -euo pipefail

if [[ -n "${SLURM_JOB_ID:-}" ]]; then
    echo "[download_assets] ERROR: run on a login node (no internet on compute nodes)." >&2
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
    Qwen/Qwen2.5-0.5B               # 1 getting started (check_env --model)
)
DATASETS=(                          # "<repo_id> <local dir name in DATA_DIR>"
    "Salesforce/wikitext wikitext"
)

echo "[download_assets] HF_HOME=${HF_HOME}  DATA_DIR=${DATA_DIR}"
mkdir -p "${HF_HOME}" "${DATA_DIR}"

if (($# > 0)); then
    hf download "$@"
else
    for model in "${MODELS[@]}"; do
        hf download "${model}"
    done
    for entry in "${DATASETS[@]}"; do
        read -r repo_id name <<<"${entry}"
        hf download "${repo_id}" --repo-type dataset --local-dir "${DATA_DIR}/${name}"
    done
fi

echo "[download_assets] done. Disk usage:"
du -sh "${HF_HOME}/hub" "${DATA_DIR}" 2>/dev/null || true