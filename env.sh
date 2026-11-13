# shellcheck shell=bash
# env.sh - The Adastra AI environment in one line: Slurm project, Python
# environment (prebuilt or uv), Hugging Face cache; on compute nodes, offline
# mode and a per-job MIOpen cache. Same on MI300A and MI250X.
# Usage: source env.sh   (repository root, on a login node and in every job)
# Settings: command line > env.local.sh > defaults. Every variable and its plain
# `export`: handbook page "Set up your environment", table "What env.sh sets".
# Ref: https://dci.dci-gitlab.cines.fr/webextranet/software_stack/libraries/index.html

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
    HF_HOME HF_DATASETS_CACHE HF_TOKEN_PATH)

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
elif [[ -z "${SLURMD_NODENAME:-}" ]]; then
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
            # libraries (/opt/rocm*) first in LD_LIBRARY_PATH may be loaded
            # instead. A ROCm SDK of the environment (ROCM_PATH) is fine.
            if [[ ":${LD_LIBRARY_PATH:-}:" == *:/opt/rocm* ]]; then
                echo "[env] WARNING: LD_LIBRARY_PATH contains system ROCm libraries (loaded modules?);" \
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

# --- Compute-node settings -------------------------------------------------------
# slurmd sets SLURMD_NODENAME in batch scripts and srun steps, on the compute
# node. salloc does not: its shell stays on the login node, with internet.
if [[ -n "${SLURMD_NODENAME:-}" ]]; then
    # Compute nodes have no internet access: models must be in HF_HOME already.
    export HF_HUB_OFFLINE=1 UV_OFFLINE=1
    # MIOpen cache in node-local /tmp, one per job (Adastra doc, MIOpen section).
    # Random name: on shared nodes, another user cannot create it in advance.
    # run creates it (mode 700) and removes it at the end of the job.
    _rand="$(od -An -N8 -tx1 /dev/urandom | tr -d ' \n')"
    export MIOPEN_USER_DB_PATH="/tmp/${USER}-miopen-${SLURM_JOB_ID:-step}-${_rand}"
    export MIOPEN_CUSTOM_CACHE_DIR="${MIOPEN_USER_DB_PATH}"
    unset _rand
elif [[ -n "${SLURM_JOB_ID:-}" ]]; then
    # salloc shell: it stays online (downloads work), the commands it starts
    # with srun run offline on the compute node (SLURM_EXPORT_ENV = srun --export).
    export SLURM_EXPORT_ENV="ALL,HF_HUB_OFFLINE=1,UV_OFFLINE=1"
fi

# --- Log helpers -----------------------------------------------------------------
env_summary() {
    echo "[env] ACCOUNT=${ACCOUNT:-<unset>}"
    echo "[env] Python environment (${AI_ENV}): ${VIRTUAL_ENV:-<none>}"
    echo "[env] HF_HOME=${HF_HOME}"
    if [[ -n "${SLURMD_NODENAME:-}" ]]; then
        echo "[env] HF_HUB_OFFLINE=${HF_HUB_OFFLINE}  MIOPEN_USER_DB_PATH=${MIOPEN_USER_DB_PATH}"
    elif [[ -n "${SLURM_JOB_ID:-}" ]]; then
        echo "[env] srun steps: SLURM_EXPORT_ENV=${SLURM_EXPORT_ENV}"
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
if [[ -z "${SLURMD_NODENAME:-}" || -t 1 ]]; then
    env_summary
fi
unset _root

# --- RCCL debug (uncomment to check that Slingshot is used) ---------------------
# Expected in the logs: "NET/OFI Selected Provider is cxi".
# export NCCL_DEBUG=INFO
# export NCCL_DEBUG_SUBSYS=INIT,NET