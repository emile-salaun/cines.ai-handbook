# Data & models

Compute nodes have no internet access. Models and datasets are downloaded on a
login node, then read offline by the jobs.

## Requirements

=== "Prebuilt"

    Nothing to add: the prebuilt environment has `hf`, Transformers and
    Datasets.

=== "uv"

    The base environment is enough (no group). On a login node, from the
    repository root:

    ```bash
    module load python
    uv sync --locked
    ```

## Where data goes

| What | Variable | Default | Purge |
|---|---|---|---|
| Hugging Face models | `$HF_HOME` | `$WORKDIR/hf` | never |
| Your datasets | `$DATA_DIR` | `$WORKDIR/handbook/datasets` | never |
| Public datasets provided by CINES | `$DSDIR` | set by Adastra | — |
| Dataset cache (Arrow files, regenerated when missing) | `$HF_DATASETS_CACHE` | `$SCRATCHDIR/hf/datasets` | 30 days unused |
| Job outputs, checkpoints | `$OUTPUT_DIR` | `$SCRATCHDIR/handbook` | 30 days unused |

The defaults come from `env.sh`; to change them, see
[Set up your environment](../getting-started/setup.md#override-with-command-line-variables).

## Steps

<div class="cines-steps" markdown>

1. [Download a model](models.md): from the Hugging Face Hub into `$HF_HOME`,
   gated models included.
2. [Get a dataset](datasets.md): from `$DSDIR`, from the Hub, or from your
   own computer.
3. [Use them in a job](offline.md): offline load, sizes and load times.

</div>