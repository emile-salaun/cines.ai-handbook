# shellcheck shell=bash
# =============================================================================
# env.sh - Handbook environment: Slurm project, prebuilt AI environment,
# Hugging Face cache, job variables and log helpers.
#
# Source it from the repository root, on a login node and in every job
# (the Slurm templates do it for you):
#   source env.sh
#
# Settings ("User settings" block), from highest to lowest priority:
#   1. variables given on the command line:
#        HANDBOOK_ACCOUNT=<other_project> source env.sh
#   2. env.local.sh at the repository root (ignored by git), set once:
#        echo 'HANDBOOK_ACCOUNT=<project>' > env.local.sh
#   3. the defaults below.
# After editing env.local.sh, open a new shell: values already exported in
# the current shell count as command-line values.
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

HANDBOOK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export HANDBOOK_ROOT

# --- User settings ------------------------------------------------------------
_handbook_settings=(HANDBOOK_ACCOUNT AI_MODULE AI_VENV_PATH HF_HOME HF_DATASETS_CACHE
    HANDBOOK_DATA HANDBOOK_OUTPUT)

# 1 > 2: keep the values set before sourcing, apply env.local.sh, restore them.
_handbook_cli=()
for _v in "${_handbook_settings[@]}"; do
    if [[ -n "${!_v:-}" ]]; then _handbook_cli+=("${_v}=${!_v}"); fi
done
if [[ -f "${HANDBOOK_ROOT}/env.local.sh" ]]; then
    # shellcheck source=/dev/null
    source "${HANDBOOK_ROOT}/env.local.sh"
fi
for _kv in "${_handbook_cli[@]}"; do export "${_kv?}"; done
unset _v _kv _handbook_cli

# 3: defaults.
HANDBOOK_ACCOUNT="${HANDBOOK_ACCOUNT:-}"                # Slurm project (myproject -l)
AI_MODULE="${AI_MODULE:-venv/0.8.0+torch2.11.0+rocm7.2.0}"  # prebuilt AI environment
_module_dir="${AI_MODULE//\//-}"                         # one venv per module version
AI_VENV_PATH="${AI_VENV_PATH:-${WORKDIR}/envs/${_module_dir//+/-}}"
unset _module_dir
HF_HOME="${HF_HOME:-${WORKDIR}/hf}"                      # models (not purged)
HF_DATASETS_CACHE="${HF_DATASETS_CACHE:-${SCRATCHDIR}/hf/datasets}"  # regenerable
HANDBOOK_DATA="${HANDBOOK_DATA:-${WORKDIR}/handbook/datasets}"       # datasets, by path
HANDBOOK_OUTPUT="${HANDBOOK_OUTPUT:-${SCRATCHDIR}/handbook}"         # job outputs
# declare -gx, not export: with `VAR=value source env.sh`, bash would restore
# VAR to its previous value when env.sh returns.
for _v in "${_handbook_settings[@]}"; do declare -gx "${_v}=${!_v}"; done
unset _v

# --- Slurm: project for sbatch / srun / salloc ---------------------------------
# These variables override the "#SBATCH --account=<project>" line of the templates.
if [[ -n "${HANDBOOK_ACCOUNT}" ]]; then
    export SBATCH_ACCOUNT="${HANDBOOK_ACCOUNT}" SLURM_ACCOUNT="${HANDBOOK_ACCOUNT}" \
        SALLOC_ACCOUNT="${HANDBOOK_ACCOUNT}"
elif [[ -z "${SLURM_JOB_ID:-}" ]]; then
    echo "[env] WARNING: HANDBOOK_ACCOUNT is empty: jobs will be rejected." >&2
    echo "[env]   List your projects with: myproject -l" >&2
    echo "[env]   Then set yours once: echo 'HANDBOOK_ACCOUNT=<project>' > ${HANDBOOK_ROOT}/env.local.sh" >&2
fi

# --- Prebuilt AI environment ----------------------------------------------------
# Module and activation scripts are not `set -u` safe.
if [[ $- == *u* ]]; then _nounset=1; else _nounset=0; fi
set +u

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

if ((_nounset)); then set -u; fi
unset _nounset

# --- Job settings (compute nodes) ---------------------------------------------
if [[ -n "${SLURM_JOB_ID:-}" ]]; then
    # Compute nodes have no internet access: models must be in HF_HOME already.
    export HF_HUB_OFFLINE=1
    # MIOpen cache in node-local /tmp, one per job (Adastra doc, MIOpen section).
    export MIOPEN_USER_DB_PATH="/tmp/${USER}-miopen-cache-${SLURM_JOB_ID}"
    export MIOPEN_CUSTOM_CACHE_DIR="${MIOPEN_USER_DB_PATH}"
fi

# --- Log helpers -----------------------------------------------------------------
handbook_env_summary() {
    echo "[env] HANDBOOK_ACCOUNT=${HANDBOOK_ACCOUNT:-<unset>}"
    echo "[env] AI environment: ${VIRTUAL_ENV:-<none>}"
    echo "[env] HF_HOME=${HF_HOME}"
    if [[ -n "${SLURM_JOB_ID:-}" ]]; then
        echo "[env] HF_HUB_OFFLINE=${HF_HUB_OFFLINE}  MIOPEN_USER_DB_PATH=${MIOPEN_USER_DB_PATH}"
    fi
}

# Runs a command between a start and an end line (date, elapsed time, exit code).
#   handbook_run python script.py --arg 1
handbook_run() {
    local start=${SECONDS} rc=0
    echo "[job] ${SLURM_JOB_NAME:-job} ${SLURM_JOB_ID:-} started at $(date '+%F %T')"
    echo "[job] nodes: ${SLURM_JOB_NODELIST:-$(hostname)} (${SLURM_NNODES:-1}), GPUs per node: ${SLURM_GPUS_ON_NODE:-0}"
    handbook_env_summary
    echo "[run] $*"
    "$@" || rc=$?
    echo "[job] ended at $(date '+%F %T'), elapsed $(date -u -d "@$((SECONDS - start))" +%T), exit code ${rc}"
    return "${rc}"
}

# Summary when sourced by hand (batch jobs print it through handbook_run).
if [[ -z "${SLURM_JOB_ID:-}" || -t 1 ]]; then
    handbook_env_summary
fi

# --- RCCL debug (uncomment to check that Slingshot is used) ---------------------
# Expected in the logs: "NET/OFI Selected Provider is cxi".
# export NCCL_DEBUG=INFO
# export NCCL_DEBUG_SUBSYS=INIT,NET
