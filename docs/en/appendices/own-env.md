# Build your own environment (uv)

**Goal:** a Python environment of your own (other PyTorch or ROCm versions,
extra packages, compiled extensions), used with the handbook job scripts.

**Before you start:** a login shell in the handbook repository, for the job
scripts (see [Set up your environment](../getting-started/setup.md)).

| Environment | For |
|---|---|
| Prebuilt (Adastra) | stable versions maintained by CINES |
| Handbook uv ([Set up your environment](../getting-started/setup.md)) | recent versions, the same for everyone |
| Your own (this page) | other versions, your packages, compiled extensions |

Everything below runs on a login node. Keep environments in `$WORKDIR`: an
environment holds tens of thousands of files, too many for `$HOME`.

## A recent PyTorch

```bash
module load python                                        # (1)!
uv venv --python 3.12 $WORKDIR/myenv                      # (2)!
source $WORKDIR/myenv/bin/activate
uv pip install --extra-index-url https://stable.repo.amd.com/rocm/whl-next/ \
    "torch[device-gfx942,device-gfx90a]==2.14.0+rocm10.1.0"   # (3)!
```

1. Provides `uv`.
2. Python 3.12: the version of the handbook, and the only one of the vLLM
   ROCm wheels.
3. PyTorch built by AMD for ROCm 10.1, with the GPU code of MI300A
   (`gfx942`) and MI250X (`gfx90a`) only. The AMD index comes first, the
   other dependencies from PyPI. Other versions:
   [AMD, Install PyTorch for ROCm](https://rocm.docs.amd.com/projects/ai-ecosystem/en/latest/frameworks/pytorch/install.html).

The wheel ships its own ROCm libraries: no ROCm module, no SDK needed to run
PyTorch.

```bash
python -c "import torch; print(torch.__version__, torch.version.hip)"
```

```text
2.14.0+rocm10.1.0 10.1.<n>
```

## Add packages

```bash
uv pip install transformers datasets
uv pip freeze > $WORKDIR/myenv-requirements.txt      # (1)!
```

1. Every installed version, to build the same environment again later:
   `uv pip install --extra-index-url https://stable.repo.amd.com/rocm/whl-next/ -r $WORKDIR/myenv-requirements.txt`
   in a new environment.

## Compile extensions

Packages compiled for the GPU at install time (flash-attention, your own HIP
kernels, for example) need the ROCm SDK (compilers, headers), in the ROCm
version of the PyTorch wheel (`torch.version.hip`, here 10.1):

```bash
uv pip install --extra-index-url https://stable.repo.amd.com/rocm/whl-next/ \
    "rocm[libraries,devel,device-gfx942,device-gfx90a]==10.1.0"   # (1)!
rocm-sdk init                                                     # (2)!
rocm-sdk test
export ROCM_PATH=$(rocm-sdk path --root)
export PATH="$ROCM_PATH/bin:$PATH"
export LD_LIBRARY_PATH="$ROCM_PATH/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"   # (3)!
export LLVM_PATH="$ROCM_PATH/lib/llvm"
export HIP_DEVICE_LIB_PATH=$(echo $ROCM_PATH/lib/llvm/lib/clang/*/lib/amdgcn/bitcode)   # (4)!
export PYTORCH_ROCM_ARCH="gfx942;gfx90a"                          # (5)!
export MAX_JOBS=8                                                 # (6)!
uv pip install --no-build-isolation <package>
```

1. The ROCm SDK as Python packages, in the environment: same index, same
   version as PyTorch.
2. Unpacks the development files; `rocm-sdk test` checks the installation.
3. Prepends: the libraries already in `LD_LIBRARY_PATH` (Cray, network)
   stay.
4. The `clang/<version>` directory changes with the ROCm version.
5. Builds for MI300A (`gfx942`) and MI250X (`gfx90a`).
6. Limits parallel compilation on the shared login node.

??? note "The ROCm SDK from a tarball"
    The same SDK exists as one archive for all GPUs:

    ```bash
    cd $WORKDIR
    wget https://stable.repo.amd.com/rocm/core/tarball/therock-dist-linux-multiarch-10.1.0.tar.gz
    mkdir rocm-10.1.0 && tar -xf therock-dist-linux-multiarch-10.1.0.tar.gz -C rocm-10.1.0
    export ROCM_PATH=$WORKDIR/rocm-10.1.0
    ```

    Then the same `export` lines as above, from `PATH`. The archive has no
    install step: nothing else to run.

    Ref: [TheRock, Releases](https://github.com/ROCm/TheRock/blob/main/RELEASES.md).

## Use it with the handbook job scripts

In the handbook's `env.local.sh`:

```bash
AI_ENV=uv
AI_UV_VENV_PATH=$WORKDIR/myenv
```

Open a new shell, `source env.sh`: the `[env] Python environment (uv)` line
shows your environment, and every job script that sources `env.sh` uses it.

Jobs that compile at run time (DeepSpeed operations, for example) also need
the SDK. Add to `env.local.sh`, with the path printed by
`rocm-sdk path --root`:

```bash
export ROCM_PATH=<path printed by rocm-sdk path --root>
export PATH="$ROCM_PATH/bin:$PATH"
export LD_LIBRARY_PATH="$ROCM_PATH/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
```

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
| `[env] WARNING: LD_LIBRARY_PATH contains system ROCm libraries` | System ROCm modules loaded: `module purge` before `source env.sh`. |
| `GPU 0 matmul` fails, arch missing | The wheel has no GPU code for the node: add its `device-*` extra (`device-gfx942`, `device-gfx90a`). |
| HIP error at the first GPU operation | ROCm version too recent for the node's driver: try an older one. |
| Compilation fails, `hip` headers or symbols not found | SDK and PyTorch in different ROCm versions: compare `rocm-sdk version` and `torch.version.hip`. |
| Disk quota exceeded (inodes) | Too many files in `$WORKDIR`: `du -s --inodes $WORKDIR/*`, remove unused environments. |
| `$SCRATCHDIR` full | Download cache: `uv cache clean`. |
| Environment broken after a few weeks | It was in `$SCRATCHDIR` (purged): keep environments in `$WORKDIR`. |
| `[env] Python environment (prebuilt)` instead of `(uv)` | `AI_ENV=uv` missing from `env.local.sh`, or `env.sh` sourced before the edit: open a new shell, `source env.sh`. |

Ref: [AMD, Install PyTorch for ROCm](https://rocm.docs.amd.com/projects/ai-ecosystem/en/latest/frameworks/pytorch/install.html),
[uv, The pip interface](https://docs.astral.sh/uv/pip/).