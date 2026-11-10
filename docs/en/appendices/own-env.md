# Build your own environment (uv)

**Goal:** a uv environment of your own (another PyTorch or ROCm version, extra
packages), used with the handbook job scripts.

The handbook's uv environment ([Set up your environment](../getting-started/setup.md),
uv tab) is fixed: same versions for everyone. Build your own when you need
something else. Everything below runs on a login node.

## Create the project

```bash
module load python                                        # (1)!
mkdir -p $WORKDIR/myenv
cp $WORKDIR/cines.ai-handbook/{pyproject.toml,.python-version} $WORKDIR/myenv/   # (2)!
cd $WORKDIR/myenv
uv sync                                                   # (3)!
```

1. Provides `uv` (and a Python).
2. Starts from the handbook's dependencies and groups. Change `name` in
   `pyproject.toml`.
3. Creates `.venv` and `uv.lock` in `$WORKDIR/myenv`, with the base
   dependencies; add `--group <name>` for the handbook's dependency groups.

## Add packages

```bash
uv add timm                 # installs it, records it in pyproject.toml and uv.lock
```

`uv.lock` pins every version: keep it with `pyproject.toml` (in a git
repository of your own, for example) to rebuild the same environment later
with `uv sync --locked`.

## Change the PyTorch or ROCm version

In `pyproject.toml`, the PyTorch index sets the ROCm version of the wheels,
and the `torch` line sets the PyTorch version:

```toml
dependencies = [
    "torch==2.11.*",                                  # PyTorch version
    ...
]

[[tool.uv.index]]
name = "pytorch-rocm"
url = "https://download.pytorch.org/whl/rocm7.2"      # ROCm version
explicit = true
```

Then `uv lock --upgrade-package torch` and `uv sync`.

The wheel ships its own ROCm libraries, but they must work with the GPU
driver of the nodes: check the
[ROCm compatibility matrix](https://rocm.docs.amd.com/en/latest/compatibility/compatibility-matrix.html).
The reliable test is `check_env.py` on both node types (below).

## Use it with the handbook job scripts

In the handbook's `env.local.sh`:

```bash
AI_ENV=uv
AI_UV_VENV_PATH=$WORKDIR/myenv/.venv
```

Open a new shell, `source env.sh`: the `[env] Python environment (uv)` line
shows your environment, and every job script that sources `env.sh` uses it.

## Compile extensions

Packages compiled at install time for the GPU (flash-attention, for example)
need the ROCm compilers of the system, in the same version as the wheel
(`python -c "import torch; print(torch.version.hip)"`):

```bash
module load rocm/<version>                   # (1)!
export PYTORCH_ROCM_ARCH="gfx942;gfx90a"     # (2)!
export MAX_JOBS=8                            # (3)!
uv add --no-build-isolation <package>
module purge
```

1. `module avail rocm` lists the versions available on Adastra.
2. Builds for MI300A (`gfx942`) and MI250X (`gfx90a`).
3. Limits parallel compilation on the shared login node.

## Check

=== "MI300A"

    ```bash
    sbatch diagnostics/check_env.sh
    ```

=== "MI250X"

    ```bash
    sbatch --constraint=MI250 --cpus-per-task=8 diagnostics/check_env.sh
    ```

`All checks passed.`, with `gfx942` (MI300A) or `gfx90a` (MI250X) on the
`GPU 0 matmul` line. A HIP error at the first GPU operation usually means a
ROCm version the node's driver does not support.

## Pitfalls

| Symptom | Cause, fix |
|---|---|
| `[env] WARNING: LD_LIBRARY_PATH contains ROCm` | System ROCm modules loaded: `module purge` before `source env.sh`. |
| `GPU 0 matmul` fails, arch missing | The wheel was not built for the node's GPU: another PyTorch or ROCm version. |
| Disk quota exceeded (inodes) | An environment holds tens of thousands of files: `du -sh --inodes $WORKDIR/*`, remove unused environments. |
| `$SCRATCHDIR` full | Download cache: `uv cache clean`. |
| Environment broken after a few weeks | It was in `$SCRATCHDIR` (purged): keep environments in `$WORKDIR`. |

Ref: [uv, Using uv with PyTorch](https://docs.astral.sh/uv/guides/integration/pytorch/).