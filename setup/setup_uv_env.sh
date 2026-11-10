#!/usr/bin/env bash
# =============================================================================
# setup/setup_uv_env.sh - Install the handbook's fixed uv environment, the
# alternative to the prebuilt AI environment. Run on a login node (downloads
# from PyPI, the PyTorch index and GitHub).
#
#   1. installs uv (pinned version, checksum verified) in $WORKDIR/uv/bin
#   2. installs Python (version in .python-version) in $WORKDIR/uv/python
#   3. installs the base environment (PyTorch for ROCm, Transformers, Hugging
#      Face Hub) and the dependency groups you name, with the exact versions
#      of uv.lock, in $AI_UV_VENV_PATH (default $WORKDIR/envs/uv-handbook)
# Groups (pyproject.toml): one per chapter (inference, training, profiling)
# and one per framework (accelerate, peft, deepspeed, diffusers). Each run
# installs exactly the base + the groups it names: groups installed by a
# previous run are removed.
# Download cache in $UV_CACHE_DIR ($SCRATCHDIR/uv-cache); free it with
# `uv cache clean`. Locations: see the "User settings" block of env.sh.
# Same environment for MI300A and MI250X.
# Other versions or packages: handbook appendix "Build your own environment
# (uv)"; --uv-only installs uv alone for that.
#
# Usage (from anywhere, on a login node):
#   bash setup/setup_uv_env.sh                                # base only
#   bash setup/setup_uv_env.sh --group training               # base + chapter 4
#   bash setup/setup_uv_env.sh --group peft --group diffusers # base + two frameworks
#   bash setup/setup_uv_env.sh --uv-only                      # uv only
# Then use the environment, once:
#   echo 'AI_ENV=uv' >> env.local.sh
# Ref: uv, Using uv with PyTorch: https://docs.astral.sh/uv/guides/integration/pytorch/
# =============================================================================
set -euo pipefail

module load python
uv --version

usage() { sed -n '/^# Usage/,/^# Then/p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 1; }

uv_only=0
groups=()
while (($# > 0)); do
    case "$1" in
        --uv-only) uv_only=1 ;;
        --group) [[ -n "${2:-}" ]] || usage; groups+=(--group "$2"); shift ;;
        *) usage ;;
    esac
    shift
done

if [[ -n "${SLURM_JOB_ID:-}" ]]; then
    echo "[setup_uv] ERROR: run on a login node (no internet on compute nodes)." >&2
    exit 1
fi

cd "$(dirname "${BASH_SOURCE[0]}")/.."
AI_ENV=none source env.sh >/dev/null

# --- 1. uv ------------------------------------------------------------------------
uv_bin="${WORKDIR}/uv/bin/uv"
if [[ -x "${uv_bin}" && "$("${uv_bin}" --version)" == "uv ${UV_VERSION}"* ]]; then
    echo "[setup_uv] uv ${UV_VERSION} already installed: ${uv_bin}"
else
    echo "[setup_uv] Installing uv ${UV_VERSION} in ${WORKDIR}/uv/bin"
    tmp="$(mktemp -d)"
    trap 'rm -rf "${tmp}"' EXIT
    curl -fsSL -o "${tmp}/${UV_WHEEL}" "${UV_URL}"
    echo "${UV_SHA256}  ${tmp}/${UV_WHEEL}" | sha256sum --check --quiet
    unzip -q -j "${tmp}/${UV_WHEEL}" "uv-${UV_VERSION}.data/scripts/uv" -d "${tmp}"
    install -D -m 755 "${tmp}/uv" "${uv_bin}"
fi
export PATH="${WORKDIR}/uv/bin:${PATH}"

if ((uv_only)); then
    echo "[setup_uv] Done: uv installed (open a new shell or source env.sh to get it on the PATH)."
    exit 0
fi

if [[ ! -f uv.lock ]]; then
    echo "[setup_uv] ERROR: uv.lock is missing: the handbook's uv environment is not available yet." >&2
    echo "[setup_uv]   Maintainers: run 'uv lock' on a login node, validate, commit uv.lock." >&2
    exit 1
fi

# --- 2. Python (version from .python-version), nothing added to ~/.local/bin --------
uv python install --no-bin

# --- 3. Base + groups: exact versions of uv.lock -------------------------------------
echo "[setup_uv] Environment: ${AI_UV_VENV_PATH}"
echo "[setup_uv] Groups: ${groups[*]:-none (base only)}"
UV_PROJECT_ENVIRONMENT="${AI_UV_VENV_PATH}" uv sync --locked "${groups[@]}"

"${AI_UV_VENV_PATH}/bin/python" -c \
    'import torch; print(f"[setup_uv] torch {torch.__version__}, HIP {torch.version.hip}")'
echo "[setup_uv] Done. To use it: echo 'AI_ENV=uv' >> env.local.sh, then open a new shell."