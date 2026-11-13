# Adastra at a glance

**Goal:** know which node type to request and where to put your files.

**Before you start:** an Adastra account and a project with GPU hours
(`myproject -l` lists your projects).

## Node types

A node type is selected with `--constraint`. All handbook templates use
`--constraint=MI300`.

| Constraint | Node | GPUs seen by PyTorch | GPU memory | CPU memory | CPU cores |
|---|---|---|---|---|---|
| `MI300` (default) | 4 × AMD MI300A APU (`gfx942`) | 4 | 128 GiB HBM3 per APU | same HBM3 (unified with the GPU) | 96 (24 per APU) |
| `MI250` | 4 × AMD MI250X = 8 GCDs (`gfx90a`) + 1 × AMD EPYC 7A53 | 8 | 64 GiB HBM2e per GCD | 256 GiB DDR4 | 64 (8 per GCD) |
| `GENOA` | 2 × AMD EPYC 9654, no GPU | 0 | — | 768 GiB DDR5 | 192 |

On MI250X, each GCD is an independent GPU: a node has 8 of them.
On MI300A, CPU and GPU share the same memory: there is no host ↔ device copy,
but CPU processes and the GPU compete for the same 128 GiB per APU.

Ref: [Adastra doc, Architecture](https://dci.dci-gitlab.cines.fr/webextranet/architecture/index.html).

## Login and compute nodes

| | Login nodes | Compute nodes |
|---|---|---|
| Internet | filtered | none |
| Use | edit, download models, submit jobs | run jobs (`sbatch`, `salloc`, `srun`) |
| Apptainer | no | yes |

Everything a job needs (models, datasets, Python packages) must be on disk
before the job starts. The handbook jobs run with `HF_HUB_OFFLINE=1`.

## Storage

| Variable | Use in the handbook | Purge |
|---|---|---|
| `$HOMEDIR` | small config files (`~/.bashrc`, Hugging Face token) | never |
| `$WORKDIR` | the repository (`cines.ai-handbook/`, with its uv environment `.venv`), prebuilt AI environment, Hugging Face models (`$HF_HOME`), your datasets (`$WORKDIR/datasets/<name>`) | never |
| `$SCRATCHDIR` | job outputs (`$SCRATCHDIR/handbook/<script>/` for the examples), dataset cache, checkpoints | files unused for 30 days |
| `$SHAREDWORKDIR`, `$SHAREDSCRATCHDIR` | same, shared within the project | as above |

Check your quotas with `myproject -s <project>`.

Ref: [Adastra doc, Data storage and transfers](https://dci.dci-gitlab.cines.fr/webextranet/data_storage_and_transfers/index.html).