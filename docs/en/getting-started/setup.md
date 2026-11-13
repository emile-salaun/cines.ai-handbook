# Set up your environment

**Goal:** a login shell where `sbatch` uses your project and Python is ready
for the handbook scripts. Done once; then one command per session.

## Once

On a login node:

```bash
cd $WORKDIR
git clone https://github.com/emile-salaun/cines.ai-handbook.git
cd cines.ai-handbook
echo 'ACCOUNT=<project>' > env.local.sh   # (1)!
```

1. Your Slurm project (`myproject -l` lists them). `env.local.sh` is ignored
   by git.

The repository goes in `$WORKDIR`: not purged, and room for a Python
environment (`$HOMEDIR` is small).

Then choose your Python environment:

=== "Prebuilt"

    Adastra's prebuilt AI environment, maintained by CINES. **Recommended.**

    ```bash
    source env.sh       # (1)!
    ```

    1. The first time, it loads the AI modules and creates your environment in
       `$WORKDIR/envs/`. This takes a few minutes.

=== "uv"

    The handbook's environment, installed with [uv](https://docs.astral.sh/uv/)
    from `pyproject.toml` and `uv.lock`: the same versions for everyone,
    independent of the prebuilt environment. `uv` comes with the `python`
    module.

    ```bash
    module load python
    uv sync --locked                      # (1)!
    echo 'AI_ENV=uv' >> env.local.sh      # (2)!
    source env.sh
    ```

    1. Creates the environment in `.venv`, in the repository, with the exact
       versions of `uv.lock`: PyTorch for ROCm, Transformers, Hugging Face
       Hub. The first run downloads several GB.
    2. Every new shell and every job now uses this environment. Open a new
       shell before `source env.sh`.

    !!! warning "Not available yet"
        `uv.lock` is not published yet: `uv sync --locked` stops with
        `Unable to find lockfile`. Use the prebuilt environment for now.

    The base is enough for chapters 1 and 2. The other chapters need a
    dependency group, given in their *Requirements* block:

    ```bash
    uv sync --locked --group training
    ```

    Each `uv sync` installs the base and **only** the groups it names: groups
    of a previous run are removed. To keep several, name them all:
    `--group inference --group training`.

    ??? note "Dependency groups"
        | Group | Installs |
        |---|---|
        | `inference` (chapter 3) | `accelerate`, `diffusers` |
        | `training` (chapter 4) | `peft`, `deepspeed` |
        | `profiling` (chapter 5) | `tensorboard` |
        | `accelerate` | Accelerate |
        | `peft` | PEFT, Accelerate |
        | `deepspeed` | DeepSpeed |
        | `diffusers` | Diffusers |

        A chapter group includes its framework groups; a package in several
        groups has the same version everywhere (one `uv.lock`).

    Other versions or packages:
    [Build your own environment (uv)](../appendices/own-env.md).
    Back to the prebuilt environment: remove the `AI_ENV=uv` line from
    `env.local.sh`.

    ??? note "Good to know"
        - **Compute nodes:** no internet. Run `uv sync` on a login node only;
          in jobs, `env.sh` sets `UV_OFFLINE=1`.
        - **ROCm libraries:** the PyTorch wheel ships its own. If `env.sh` warns
          that `LD_LIBRARY_PATH` contains system ROCm libraries, run
          `module purge` before `source env.sh`.
        - **`PYTHONPATH`:** if `env.sh` warns that it is set, packages outside
          the environment may be imported first: `unset PYTHONPATH`.
        - **Disk space:** environment in the repository, in `$WORKDIR` (several
          GB); download cache in `$SCRATCHDIR/uv-cache`: free it with
          `uv cache clean`.

        Ref: [uv, Using uv with PyTorch](https://docs.astral.sh/uv/guides/integration/pytorch/).

Finally, download the models and the dataset of the handbook examples
(small models of about 1 GB each, listed in the script) into `$WORKDIR`:

```bash
bash setup/download_assets.sh
```

## Every session

```bash
cd $WORKDIR/cines.ai-handbook
source env.sh
```

## What to look at

=== "Prebuilt"

    ```text
    [env] ACCOUNT=<project>
    [env] Python environment (prebuilt): <WORKDIR>/envs/venv-0.8.0-torch2.11.0-rocm7.2.0
    [env] HF_HOME=<WORKDIR>/hf
    ```

    `ERROR: no AI environment`: read the module messages above it.

=== "uv"

    ```text
    [env] ACCOUNT=<project>
    [env] Python environment (uv): <WORKDIR>/cines.ai-handbook/.venv
    [env] HF_HOME=<WORKDIR>/hf
    ```

    `ERROR: no uv environment`: run `module load python && uv sync --locked`
    on a login node, from the repository root.

`ACCOUNT=<unset>` and a warning: `env.local.sh` is missing or empty.
Then `which python` points into your environment.

!!! cines "An environment elsewhere"
    `env.sh` looks for the environment in `AI_VENV_PATH` (prebuilt) or
    `AI_UV_VENV_PATH` (uv). If the variable is already set in your shell
    (for example in `~/.bashrc`), that value is used. To keep an existing
    environment, set it in `env.local.sh` instead. Avoid `$SCRATCHDIR`: unused
    files are purged after 30 days.

## What `env.sh` sets

| Variable | Default | Where | Change it | Without `env.sh` |
|---|---|---|---|---|
| `ACCOUNT`, exported as `SBATCH_ACCOUNT`, `SALLOC_ACCOUNT`, `SLURM_ACCOUNT` | none: warning | everywhere | `env.local.sh` | `export SBATCH_ACCOUNT=<project> SALLOC_ACCOUNT=<project> SLURM_ACCOUNT=<project>`, or `--account=<project>` |
| `AI_ENV` | `prebuilt` | everywhere | `env.local.sh` (`uv`) | activate the environment yourself (next rows) |
| `AI_MODULE` | `venv/0.8.0+torch2.11.0+rocm7.2.0` | everywhere | `env.local.sh` | first time: `module purge; module load develop AI-develop <AI_MODULE>` |
| `AI_VENV_PATH` | `$WORKDIR/envs/<module>` | everywhere | `env.local.sh` | `source <AI_VENV_PATH>/bin/activate.poverlay` |
| `AI_UV_VENV_PATH` | `<repository>/.venv` | everywhere | `env.local.sh` | `source <AI_UV_VENV_PATH>/bin/activate` |
| `UV_CACHE_DIR` | `$SCRATCHDIR/uv-cache` | everywhere | command line | `export UV_CACHE_DIR=$SCRATCHDIR/uv-cache` |
| `UV_LINK_MODE` | `copy` | everywhere | — | `export UV_LINK_MODE=copy` |
| `HF_HOME` | `$WORKDIR/hf` | everywhere | `env.local.sh` (shared cache: `$SHAREDWORKDIR/hf`), command line | `export HF_HOME=$WORKDIR/hf` |
| `HF_DATASETS_CACHE` | `$SCRATCHDIR/hf/datasets` | everywhere | command line | `export HF_DATASETS_CACHE=$SCRATCHDIR/hf/datasets` |
| `HF_TOKEN_PATH` | `~/.cache/huggingface/token` | everywhere | — (keep it in `$HOME`) | `export HF_TOKEN_PATH=$HOME/.cache/huggingface/token` |
| `SLURM_EXPORT_ENV` | `ALL,HF_HUB_OFFLINE=1,UV_OFFLINE=1` | `salloc` shell | — | `srun --export=ALL,HF_HUB_OFFLINE=1,UV_OFFLINE=1 <command>` |
| `HF_HUB_OFFLINE`, `UV_OFFLINE` | `1` | compute nodes | — | in the job script: `export HF_HUB_OFFLINE=1 UV_OFFLINE=1` |
| `MIOPEN_USER_DB_PATH`, `MIOPEN_CUSTOM_CACHE_DIR` | `/tmp/$USER-miopen-<jobid>-<random>` | compute nodes | — | in the job script: `export MIOPEN_USER_DB_PATH=$(mktemp -d /tmp/$USER-miopen-XXXXXX) MIOPEN_CUSTOM_CACHE_DIR=$MIOPEN_USER_DB_PATH`, `rm -rf` it at the end |
| `run <command>` (function) | — | job scripts | — | run the command itself |
| `env_summary` (function) | — | everywhere | — | `echo $SBATCH_ACCOUNT $VIRTUAL_ENV $HF_HOME` |

- **Where:** *everywhere* is the login node, the `salloc` shell and the
  compute nodes. *Compute nodes* are batch scripts and commands started with
  `srun` (Slurm sets `SLURMD_NODENAME` there). The `salloc` shell stays on
  the login node: online, but its `srun` commands run offline.
- **`env.local.sh`** holds your own settings, kept for every shell and job:
  `ACCOUNT`, `AI_ENV`, a shared `HF_HOME`. No data or output paths.
- **Command line:** one session only, see below.

## Override with command-line variables

Variables given before `source env.sh` win over `env.local.sh`, which wins
over the defaults of `env.sh`:

```bash
ACCOUNT=<other_project> source env.sh       # another project
HF_HOME=$SHAREDWORKDIR/hf source env.sh     # model cache shared in the project
```

Settings: `ACCOUNT`, `AI_ENV`, `AI_MODULE`, `AI_VENV_PATH`, `AI_UV_VENV_PATH`,
`UV_CACHE_DIR`, `HF_HOME`, `HF_DATASETS_CACHE`, `HF_TOKEN_PATH` (see
[What `env.sh` sets](#what-envsh-sets)).
A variable already set in your shell counts as a command-line value: check the
`[env]` lines. After editing `env.local.sh`, open a new shell.

!!! cines "Hugging Face token"
    `hf auth login` stores your token in `HF_TOKEN_PATH`
    (`~/.cache/huggingface/token`), not in `HF_HOME`: a model cache shared in
    the project never contains your token. Never write the token in
    `env.local.sh` or in a script.