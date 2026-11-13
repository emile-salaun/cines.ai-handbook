# Load a model and a dataset in a job

**Goal:** check that a job loads the model and the dataset without internet,
and write the same loads in your own job.

**Before you start:** a login shell in the repository, after `source env.sh`
(see [Set up your environment](../getting-started/setup.md)); the model and
the dataset downloaded ([Download a model](models.md), [Get a
dataset](datasets.md)).

The [first job](../getting-started/first-job.md) checked the model; this one
adds the dataset, with the paths and sizes of both.

## Command

`diagnostics/check_data.sh` is built from the [template](../getting-started/templates.md)
`slurm/single_gpu.sh`. It loads `Qwen/Qwen2.5-0.5B` and `$WORKDIR/datasets/wikitext`,
downloaded by `bash setup/download_assets.sh`.

From the repository root:

=== "MI300A"

    ```bash
    sbatch diagnostics/check_data.sh
    ```

=== "MI250X"

    ```bash
    sbatch --constraint=MI250 --cpus-per-task=8 diagnostics/check_data.sh
    ```

Your own model and dataset, in an [interactive session](../getting-started/interactive.md):

```bash
srun python diagnostics/check_data.py --model <repo_id or dir> --dataset <dir> [--config <name>] [--split <name>] [--column <name>]
```

`--model` takes a Hugging Face id or a model directory (`$WORKDIR/models/<name>`);
`--column` is the text column to tokenize (default `text`).

## What to look at

```text
[OK] HF_HUB_OFFLINE=1
[OK] model Qwen/Qwen2.5-0.5B in cache: <WORKDIR>/hf/hub/models--Qwen--Qwen2.5-0.5B/snapshots/<hash> (<size> GiB, <n> files)
[OK] model load (CPU): 494M parameters
[OK] model copy to GPU 0
[OK] dataset directory: <WORKDIR>/datasets/wikitext (<size> GiB, <n> files)
[OK] dataset load: wikitext-2-raw-v1, split train, <rows> rows
       Arrow cache: <SCRATCHDIR>/hf/datasets/...
[OK] tokenization: 1000 samples, <tokens> tokens
All checks passed.
```

- `in cache`: the path shows where the model is read from.
- `Arrow cache`: written at the first load, reused by the next ones.

| Failure | Cause |
|---|---|
| `LocalEntryNotFoundError` | model not downloaded, or downloaded with another `HF_HOME`: compare the path printed by `hf download` with the `HF_HOME=` line of the job |
| `FileNotFoundError` on the dataset | wrong path, or dataset not copied yet |
| `BuilderConfig '<name>' not found` | wrong `--config`: the error lists the available ones |
| `Unknown split "train". Should be one of [...]` | splits come from the file names (`train*`, `test*`, …): `--split <name>`; in your code, `split="<name>"`, or `data_files="<file>"` for one file |
| `[WARN] no column 'text'` | your dataset has another text column: `--column <name>` |
| `does not appear to have a file named …` | a file was left out by `--exclude` / `--include`: download again without it |
| `load_dataset("<repo_id>")` fails | datasets of the handbook are loaded by path: `load_dataset(f"{os.environ['WORKDIR']}/datasets/<name>")` |
| `[FAIL] HF_HUB_OFFLINE=1` | script run on a login node: run it with `sbatch` or `srun` |
| `sbatch: error: Problem with your account on project <project>_mi300` | `env.sh` not sourced in this shell, or `ACCOUNT` not set: see [Set up your environment](../getting-started/setup.md) |
| the model asks for `trust_remote_code=True` | it runs Python code shipped with the model: read that code before allowing it |

## In your own job

The model by its id (read from `$HF_HOME`), the dataset by its path:

```python
import os

import torch

torch.backends.cuda.preferred_blas_library("cublas")  # MI300A: fast bf16

from datasets import load_dataset
from transformers import AutoModelForCausalLM, AutoTokenizer

model_id = "Qwen/Qwen2.5-0.5B"
tokenizer = AutoTokenizer.from_pretrained(model_id)
model = AutoModelForCausalLM.from_pretrained(
    model_id, dtype=torch.bfloat16, use_safetensors=True
).to("cuda")

path = os.path.join(os.environ["WORKDIR"], "datasets", "wikitext")
dataset = load_dataset(path, "wikitext-2-raw-v1", split="train")
```

In the job script, `source env.sh` before `python` sets `HF_HOME`,
`HF_DATASETS_CACHE` and `HF_HUB_OFFLINE=1`. Without `env.sh`: the `export`
lines of [What `env.sh` sets](../getting-started/setup.md#what-envsh-sets).

## Reference result

The `Elapsed` value of `sacct -X -j <jobid> -o Elapsed`.

| Partition | Elapsed | Status |
|---|---|---|
| MI300A | 00:00:45 | measured 2026-11-13 |
| MI250X | 00:00:48 | measured 2026-11-13 |

Ref: [Adastra doc, Software stack, libraries](https://dci.dci-gitlab.cines.fr/webextranet/software_stack/libraries/index.html).