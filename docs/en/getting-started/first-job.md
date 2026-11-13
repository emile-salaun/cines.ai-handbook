# First job

**Goal:** run a Python script on one GPU and check the environment.

**Before you start:** a login shell in the repository, after `source env.sh`,
and the handbook example assets downloaded (see [Set up your
environment](setup.md)).

`diagnostics/check_env.sh` is a ready-to-run batch script, built from the
[template](templates.md) `slurm/single_gpu.sh`. Open it: every line is
explained in the template.

## Command

From the repository root, after `source env.sh`:

=== "MI300A"

    ```bash
    sbatch diagnostics/check_env.sh
    ```

=== "MI250X"

    ```bash
    sbatch --constraint=MI250 --cpus-per-task=8 diagnostics/check_env.sh
    ```

Follow the job with `squeue --me`, then read the log:

```bash
cat logs/check_env_<jobid>.out
```

## What to look at

Every log starts and ends the same way:

```text
[job] check_env <jobid> started at <date>
[job] nodes: <node> (1), GPUs per node: 1
[env] ACCOUNT=<project>
[env] Python environment (prebuilt): <WORKDIR>/envs/venv-0.8.0-torch2.11.0-rocm7.2.0
[env] HF_HOME=<WORKDIR>/hf
[env] HF_HUB_OFFLINE=1  MIOPEN_USER_DB_PATH=/tmp/<user>-miopen-<jobid>-<random>
[run] python diagnostics/check_env.py --model Qwen/Qwen2.5-0.5B
...
[job] ended at <date>, elapsed <hh:mm:ss>, exit code 0
```

In between, the output of `check_env.py`:

- One `[OK]` line per check, and `All checks passed.` at the end.
- `GPU 0 matmul`: the architecture is `gfx942` on MI300A, `gfx90a` on MI250X.
- `offline load of Qwen/Qwen2.5-0.5B`: the model is read from your cache,
  without internet.

| Failure | Cause |
|---|---|
| `sbatch: error: Batch job submission failed: Invalid account or account/partition combination specified` | `env.sh` not sourced in this shell, or `ACCOUNT` not set: see [Set up your environment](setup.md) |
| `offline load` fails | model not downloaded: `bash setup/download_assets.sh` on a login node |
| no log file | submitted outside the repository root (`logs/` not found) |

## Reference result

The `elapsed` value of the last log line.

| Partition | Elapsed | Status |
|---|---|---|
| MI300A | — | to be measured |
| MI250X | — | to be measured |