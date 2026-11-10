# shellcheck shell=bash
# =============================================================================
# env.sh - Handbook environment: Slurm project, Python environment (prebuilt
# or uv), Hugging Face cache, job variables and log helpers.
#
# Source it from the repository root, on a login node and in every job
# (the Slurm templates do it for you):
#   source env.sh
#
# Settings ("User settings" block), from highest to lowest priority:
#   1. variables given on the command line:
#        ACCOUNT=<other_project> source env.sh
#   2. env.local.sh at the repository root (ignored by git), set once:
#        echo 'ACCOUNT=<project>' > env.local.sh
#   3. the defaults below.
# A variable already set in your shell counts as a command-line value: the
# [env] summary shows the values in use. After editing env.local.sh, open a
# new shell.
#
# Python environment (AI_ENV):
#   prebuilt  Adastra's prebuilt AI environment (default), created on first use.
#   uv        the handbook's uv environment (pyproject.toml + uv.lock), .venv
#             in the repository, created on a login node with:
#               module load python && uv sync --locked [--group <group>]
#   none      variables only, no environment activated (used by the setup scripts).
#
# Functions for the job templates:
#   run <command>   runs it between [job] start / end lines (elapsed time, exit code)
#   env_summary     prints the [env] lines
#
# MI300A / MI250X: nothing differs here; the node type is chosen per job
# (--constraint).
#
# Ref: Adastra doc, Data storage and transfers (storage areas):
#      https://dci.dci-gitlab.cines.fr/webextranet/data_storage_and_transfers/index.html
#      Software stack, libraries (MIOpen cache, Hugging Face offline mode):
#      https://dci.dci-gitlab.cines.fr/webextranet/software_stack/libraries/index.html
# =============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "[env] ERROR: source this file, do not execute it: source env.sh" >&2
    exit 1
fi

if [[ -z "${WORKDIR:-}" || -z "${SCRATCHDIR:-}" ]]; then
    echo "[env] ERROR: WORKDIR or SCRATCHDIR is not set: run on Adastra." >&2
    return 1
fi

_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- User settings ------------------------------------------------------------
_settings=(ACCOUNT AI_ENV AI_MODULE AI_VENV_PATH AI_UV_VENV_PATH UV_CACHE_DIR
    HF_HOME HF_DATASETS_CACHE HF_TOKEN_PATH DATA_DIR OUTPUT_DIR)

# 1 > 2: keep the values set before sourcing, apply env.local.sh, restore them.
_cli=()
for _v in "${_settings[@]}"; do
    if [[ -n "${!_v:-}" ]]; then _cli+=("${_v}=${!_v}"); fi
done
if [[ -f "${_root}/env.local.sh" ]]; then
    # shellcheck source=/dev/null
    source "${_root}/env.local.sh"
fi
for _kv in "${_cli[@]}"; do export "${_kv?}"; done
unset _v _kv _cli

# 3: defaults.
ACCOUNT="${ACCOUNT:-}"                                   # Slurm project (myproject -l)
AI_ENV="${AI_ENV:-prebuilt}"                             # prebuilt | uv | none
# Prebuilt AI environment: module, and the user's overlay venv (one per module version).
AI_MODULE="${AI_MODULE:-venv/0.8.0+torch2.11.0+rocm7.2.0}"
_module_dir="${AI_MODULE//\//-}"
AI_VENV_PATH="${AI_VENV_PATH:-${WORKDIR}/envs/${_module_dir//+/-}}"
unset _module_dir
# uv environment (`uv sync` in the repository): venv and download cache.
AI_UV_VENV_PATH="${AI_UV_VENV_PATH:-${_root}/.venv}"
UV_CACHE_DIR="${UV_CACHE_DIR:-${SCRATCHDIR}/uv-cache}"  # regenerable
# Hugging Face.
HF_HOME="${HF_HOME:-${WORKDIR}/hf}"                      # models (not purged)
HF_DATASETS_CACHE="${HF_DATASETS_CACHE:-${SCRATCHDIR}/hf/datasets}"  # regenerable
HF_TOKEN_PATH="${HF_TOKEN_PATH:-${HOME}/.cache/huggingface/token}"   # private, even if HF_HOME is shared
DATA_DIR="${DATA_DIR:-${WORKDIR}/handbook/datasets}"     # datasets, loaded by path
OUTPUT_DIR="${OUTPUT_DIR:-${SCRATCHDIR}/handbook}"       # job outputs
# declare -gx, not export: with `VAR=value source env.sh`, bash would restore
# VAR to its previous value when env.sh returns.
for _v in "${_settings[@]}"; do declare -gx "${_v}=${!_v}"; done
unset _v _settings

# uv: copies instead of hard links (the cache is on another file system).
export UV_LINK_MODE=copy

# --- Slurm: project for sbatch / srun / salloc ---------------------------------
# These variables override the "#SBATCH --account=<project>" line of the templates.
if [[ -n "${ACCOUNT}" ]]; then
    export SBATCH_ACCOUNT="${ACCOUNT}" SLURM_ACCOUNT="${ACCOUNT}" SALLOC_ACCOUNT="${ACCOUNT}"
elif [[ -z "${SLURM_JOB_ID:-}" ]]; then
    echo "[env] WARNING: ACCOUNT is empty: jobs will be rejected." >&2
    echo "[env]   List your projects with: myproject -l" >&2
    echo "[env]   Then set yours once: echo 'ACCOUNT=<project>' > ${_root}/env.local.sh" >&2
fi

# --- Python environment ----------------------------------------------------------
# Module and activation scripts are not `set -u` safe.
if [[ $- == *u* ]]; then _nounset=1; else _nounset=0; fi
set +u

case "${AI_ENV}" in
    prebuilt)
        if [[ ! -f "${AI_VENV_PATH}/bin/activate.poverlay" ]]; then
            if type module >/dev/null 2>&1; then
                echo "[env] Creating the AI environment (${AI_MODULE}): ${AI_VENV_PATH}"
                mkdir -p "$(dirname "${AI_VENV_PATH}")"
                module purge
                module load develop
                module load AI-develop
                module load "${AI_MODULE}"
            else
                echo "[env] ERROR: 'module' command not found; cannot set up the AI environment." >&2
            fi
        fi
        if [[ -f "${AI_VENV_PATH}/bin/activate.poverlay" ]]; then
            # shellcheck source=/dev/null
            source "${AI_VENV_PATH}/bin/activate.poverlay"
        else
            echo "[env] ERROR: no AI environment in ${AI_VENV_PATH} (see the module messages above)." >&2
        fi
        ;;
    uv)
        if [[ -f "${AI_UV_VENV_PATH}/bin/activate" ]]; then
            # shellcheck source=/dev/null
            source "${AI_UV_VENV_PATH}/bin/activate"
            # The PyTorch wheel ships its own ROCm libraries: system ROCm
            # libraries first in LD_LIBRARY_PATH may be loaded instead.
            if [[ "${LD_LIBRARY_PATH:-}" == *rocm* ]]; then
                echo "[env] WARNING: LD_LIBRARY_PATH contains ROCm libraries (loaded modules?);" \
                    "they may conflict with the PyTorch wheel. Try: module purge" >&2
            fi
            # Packages from PYTHONPATH would be imported before the environment's.
            if [[ -n "${PYTHONPATH:-}" ]]; then
                echo "[env] WARNING: PYTHONPATH is set (${PYTHONPATH});" \
                    "its packages may shadow the uv environment's." >&2
            fi
        else
            echo "[env] ERROR: no uv environment in ${AI_UV_VENV_PATH}." >&2
            echo "[env]   Create it on a login node, from ${_root}:" >&2
            echo "[env]   module load python && uv sync --locked" >&2
        fi
        ;;
    none) ;;
    *)
        echo "[env] ERROR: AI_ENV must be prebuilt, uv or none (got '${AI_ENV}')." >&2
        ;;
esac

if ((_nounset)); then set -u; fi
unset _nounset

# --- Job settings (compute nodes) ---------------------------------------------
if [[ -n "${SLURM_JOB_ID:-}" ]]; then
    # Compute nodes have no internet access: models must be in HF_HOME already.
    export HF_HUB_OFFLINE=1 UV_OFFLINE=1
    # MIOpen cache in node-local /tmp, one per job (Adastra doc, MIOpen section).
    # Random name: on shared nodes, another user cannot create it in advance.
    # run creates it (mode 700) and removes it at the end of the job.
    _rand="$(od -An -N8 -tx1 /dev/urandom | tr -d ' \n')"
    export MIOPEN_USER_DB_PATH="/tmp/${USER}-miopen-${SLURM_JOB_ID}-${_rand}"
    export MIOPEN_CUSTOM_CACHE_DIR="${MIOPEN_USER_DB_PATH}"
    unset _rand
fi

# --- Log helpers -----------------------------------------------------------------
env_summary() {
    echo "[env] ACCOUNT=${ACCOUNT:-<unset>}"
    echo "[env] Python environment (${AI_ENV}): ${VIRTUAL_ENV:-<none>}"
    echo "[env] HF_HOME=${HF_HOME}"
    echo "[env] DATA_DIR=${DATA_DIR}"
    echo "[env] OUTPUT_DIR=${OUTPUT_DIR}"
    if [[ -n "${SLURM_JOB_ID:-}" ]]; then
        echo "[env] HF_HUB_OFFLINE=${HF_HUB_OFFLINE}  MIOPEN_USER_DB_PATH=${MIOPEN_USER_DB_PATH}"
    fi
}

# Runs a command between a start and an end line (date, elapsed time, exit code).
#   run python script.py --arg 1
run() {
    local start=${SECONDS} rc=0
    echo "[job] ${SLURM_JOB_NAME:-job} ${SLURM_JOB_ID:-} started at $(date '+%F %T')"
    echo "[job] nodes: ${SLURM_JOB_NODELIST:-$(hostname)} (${SLURM_NNODES:-1}), GPUs per node: ${SLURM_GPUS_ON_NODE:-0}"
    env_summary
    # No -p: fails if the directory already exists (not created by this job).
    if [[ -n "${MIOPEN_USER_DB_PATH:-}" ]] && ! mkdir -m 700 "${MIOPEN_USER_DB_PATH}"; then
        echo "[job] ERROR: cannot create ${MIOPEN_USER_DB_PATH}" >&2
        return 1
    fi
    echo "[run] $*"
    "$@" || rc=$?
    if [[ -n "${MIOPEN_USER_DB_PATH:-}" ]]; then
        if ((${SLURM_NNODES:-1} > 1)); then
            srun --ntasks-per-node=1 --overlap rm -rf "${MIOPEN_USER_DB_PATH}" || true
        else
            rm -rf "${MIOPEN_USER_DB_PATH}"
        fi
    fi
    echo "[job] ended at $(date '+%F %T'), elapsed $(date -u -d "@$((SECONDS - start))" +%T), exit code ${rc}"
    return "${rc}"
}

# Summary when sourced by hand (batch jobs print it through run).
if [[ -z "${SLURM_JOB_ID:-}" || -t 1 ]]; then
    env_summary
fi
unset _root

# --- RCCL debug (uncomment to check that Slingshot is used) ---------------------
# Expected in the logs: "NET/OFI Selected Provider is cxi".
# export NCCL_DEBUG=INFO
# export NCCL_DEBUG_SUBSYS=INIT,NET