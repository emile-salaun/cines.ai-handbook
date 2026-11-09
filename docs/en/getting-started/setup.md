# Set up

**Goal:** a login shell where `sbatch` uses your project and Python is the
prebuilt AI environment. Done once; then one command per session.

## Once

On a login node:

```bash
cd $HOMEDIR
git clone https://github.com/emile-salaun/cines.ai-handbook.git
cd cines.ai-handbook
echo 'HANDBOOK_ACCOUNT=<project>' > env.local.sh   # (1)!
source env.sh                                      # (2)!
bash setup/download_assets.sh                      # (3)!
```

1. Your Slurm project (`myproject -l` lists them). `env.local.sh` is ignored
   by git.
2. The first time, it loads the AI modules and creates your environment in
   `$WORKDIR/envs/`. This takes a few minutes.
3. Downloads the test model (`Qwen/Qwen2.5-0.5B`, about 1 GB) into
   `$WORKDIR/hf`.

## Every session

```bash
cd $HOMEDIR/cines.ai-handbook
source env.sh
```

## What to look at

```text
[env] HANDBOOK_ACCOUNT=<project>
[env] AI environment: <WORKDIR>/envs/venv-0.8.0-torch2.11.0-rocm7.2.0
[env] HF_HOME=<WORKDIR>/hf
```

- `HANDBOOK_ACCOUNT=<unset>` and a warning: `env.local.sh` is missing or empty.
- `ERROR: no AI environment`: read the module messages above it.

Then `which python` points into the AI environment.

!!! cines "An environment elsewhere"
    `env.sh` looks for the environment in `AI_VENV_PATH`. If this variable
    is already set in your shell (for example in `~/.bashrc`), that value is
    used. To keep an existing environment, set it in `env.local.sh` instead:
    `AI_VENV_PATH=<path>`. Avoid `$SCRATCHDIR`: unused files are purged after
    30 days.

## Override with command-line variables

Variables given before `source env.sh` win over `env.local.sh`, which wins
over the defaults of `env.sh`:

```bash
HANDBOOK_ACCOUNT=<other_project> source env.sh   # another project
HF_HOME=$SHAREDWORKDIR/hf source env.sh          # model cache shared in the project
```

Settings: `HANDBOOK_ACCOUNT`, `AI_MODULE`, `AI_VENV_PATH`, `HF_HOME`,
`HF_DATASETS_CACHE`, `HANDBOOK_DATA`, `HANDBOOK_OUTPUT`.
After editing `env.local.sh`, open a new shell: values already set in the
current shell count as command-line values.
