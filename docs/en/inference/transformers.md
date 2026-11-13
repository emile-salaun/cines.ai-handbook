# Batch generation with Transformers

**Goal:** generate answers to a list of prompts with Transformers on one GPU,
and measure the throughput.

**Before you start:** a login shell in the repository, after `source env.sh`
(see [Set up your environment](../getting-started/setup.md)); the model
downloaded ([Download a model](../data-models/models.md)).

Transformers runs any model of the Hub with a few lines of Python: the
simplest way to test a model, compute outputs for an evaluation, or check a
checkpoint after training. For large amounts of text, [vLLM](index.md) is
faster.

## Command

`inference/generate_hf.sh` is built from the [template](../getting-started/templates.md)
`slurm/single_gpu.sh`. It runs `inference/generate_hf.py` on
`Qwen/Qwen2.5-0.5B-Instruct`, downloaded by `bash setup/download_assets.sh`:
64 prompts, 16 per batch, up to 128 new tokens each.

From the repository root, after `source env.sh`:

=== "MI300A"

    ```bash
    sbatch inference/generate_hf.sh
    ```

=== "MI250X"

    ```bash
    sbatch --constraint=MI250 --cpus-per-task=8 inference/generate_hf.sh
    ```

Another model or other settings, in an [interactive session](../getting-started/interactive.md):

```bash
srun python inference/generate_hf.py --model <repo_id> --batch-size 32 --max-new-tokens 256
```

## What to look at

```text
model=Qwen/Qwen2.5-0.5B-Instruct prompts=64 batch_size=16 max_new_tokens=128 device=cuda
load: <t> s
example: 'Explain what a GPU is in two sentences.' -> '<answer>'
generation: 64 prompts, <n> tokens, <t> s
throughput: <n> tokens/s, <n> prompts/s
answers: <SCRATCHDIR>/handbook/generate_hf/<jobid>.jsonl
```

- `throughput`: generated tokens per second, model loading excluded.
- `answers`: one line per prompt, `{"prompt": ..., "answer": ...}`.
- A larger `--batch-size` raises the throughput until the GPU is full; a
  batch waits for its longest answer.

| Failure | Cause |
|---|---|
| `LocalEntryNotFoundError` | model not downloaded: `hf download <repo_id>` on a login node (see [Download a model](../data-models/models.md)) |
| `out of memory` | batch or model too large for the GPU: lower `--batch-size`; on MI250X, a GCD has 64 GB |
| `device=cpu` and `[WARN] no GPU visible` | run with `srun` inside an allocation, or in a job |
| `sbatch: error: Batch job submission failed: Invalid account or account/partition combination specified` | `env.sh` not sourced in this shell, or `ACCOUNT` not set: see [Set up your environment](../getting-started/setup.md) |

## Reference result

| Partition | Model | Load | Throughput | Status |
|---|---|---|---|---|
| MI300A | Qwen2.5-0.5B-Instruct | — | — | to be measured |
| MI250X | Qwen2.5-0.5B-Instruct | — | — | to be measured |