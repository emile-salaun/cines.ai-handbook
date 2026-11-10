# Use them in a job

**Goal:** check that a job loads the model and the dataset without internet,
and see how long it takes.

In a job, `env.sh` sets `HF_HUB_OFFLINE=1`: Transformers and Datasets read
only local files and never try the network.

## Command

`diagnostics/check_data.sh` is built from the [template](../getting-started/templates.md)
`slurm/single_gpu.sh`. It loads `Qwen/Qwen2.5-0.5B` and `$DATA_DIR/wikitext`,
downloaded by `bash setup/download_assets.sh`.

From the repository root, after `source env.sh`:

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
srun python diagnostics/check_data.py --model <repo_id> --dataset <dir> --config <name>
```

## What to look at

```text
[OK] HF_HUB_OFFLINE=1
[OK] model Qwen/Qwen2.5-0.5B in cache: <WORKDIR>/hf/hub/models--Qwen--Qwen2.5-0.5B/snapshots/<hash> (<size> GiB, <n> files)
[OK] model load (CPU): 494M parameters, <t> s
[OK] model copy to GPU 0: <t> s
[OK] dataset directory: <WORKDIR>/handbook/datasets/wikitext (<size> GiB, <n> files)
[OK] dataset load: wikitext-2-raw-v1, <rows> rows, <t> s
       Arrow cache: <SCRATCHDIR>/hf/datasets/...
[OK] tokenization: 1000 samples, <tokens> tokens, <t> s
All checks passed.
```

- `in cache`: the path shows where the model is read from.
- `Arrow cache`: written at the first load, reused by the next ones (faster
  `dataset load`).

| Failure | Cause |
|---|---|
| `LocalEntryNotFoundError` | model not downloaded, or downloaded with another `HF_HOME`: compare the `[env] HF_HOME` lines of the download and of the job |
| `FileNotFoundError` on the dataset | wrong path, or dataset not copied yet |
| `does not appear to have a file named …` | a file was left out by `--exclude` / `--include`: download again without it |
| `load_dataset("<repo_id>")` fails | datasets of the handbook are loaded by path: `load_dataset("$DATA_DIR/<name>")` |
| the model asks for `trust_remote_code=True` | it runs Python code shipped with the model: read that code before allowing it |

## Reference result

| Partition | Model load (CPU) | Copy to GPU | Dataset load | Status |
|---|---|---|---|---|
| MI300A | — | — | — | to be measured |
| MI250X | — | — | — | to be measured |