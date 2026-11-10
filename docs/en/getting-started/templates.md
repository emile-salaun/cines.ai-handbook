# Write your job script

**Goal:** write the batch script of your own job, starting from a template.

The handbook examples come with ready-to-run scripts (`diagnostics/*.sh`).
For your own work, copy a template from `slurm/` and adapt it: every line to
check is marked `EDIT`.

## Pick a template

| Template | Runs | Node | Use it for |
|---|---|---|---|
| `slurm/single_gpu.sh` | `python` on 1 GPU | shared | first tests, inference, small fine-tuning |
| `slurm/single_node.sh` | `torchrun`, one process per GPU | whole node | DDP / FSDP on one node |

```bash
mkdir -p jobs
cp slurm/single_gpu.sh jobs/my_job.sh
```

`jobs/` is ignored by git: your scripts stay out of the handbook's files.
Submit from the repository root: the script sources `env.sh` and writes to
`logs/`, both relative to it.

## Adapt the EDIT lines

| Line | What to set | MI300A | MI250X |
|---|---|---|---|
| `--constraint` | node type | `MI300` | `MI250` |
| `--cpus-per-task` (`single_gpu`) | CPU cores of one GPU | `24` | `8` |
| `--gpus-per-node` (`single_node`) | all GPUs of the node | `4` | `8` |
| `--time` | maximum run time, `HH:MM:SS`; the job is stopped after it | | |
| `--job-name` | job name, also the log name `logs/<name>_<job id>.out` | | |
| `run python ...` | your script and its arguments | | |

The other lines stay as they are:

- `#SBATCH --account=<project>`: `env.sh` replaces it with your project
  (`SBATCH_ACCOUNT`). Without `source env.sh`, the submission fails with
  `Invalid account`.
- `--gpus-per-node=1` (`single_gpu`): on shared nodes, a job must ask for at
  least one GPU.
- `source env.sh`: project, Python environment, offline mode, MIOpen cache.
- `run`: prints a start and an end line in the log, with the elapsed time and
  the exit code.

## Before submitting

- [ ] `source env.sh` done in this shell, `[env] ACCOUNT=` shows your project.
- [ ] `--constraint` and the CPU/GPU counts match the same node type.
- [ ] `--time` covers the run, with a margin: a short time starts sooner.
- [ ] The models and data are on disk: compute nodes have no internet.
- [ ] The script runs in a few seconds in an [interactive session](interactive.md)
      (`srun python my_script.py`).

## Submit and follow

```bash
sbatch jobs/my_job.sh        # prints the job id
squeue --me                  # state: PD (pending), R (running)
tail -f logs/<name>_<jobid>.out
scancel <jobid>              # stop it
```

Options on the `sbatch` command line win over the `#SBATCH` lines, for a
one-off change: `sbatch --time=01:00:00 jobs/my_job.sh`.

Ref: [Adastra doc, Job submission](https://dci.dci-gitlab.cines.fr/webextranet/user_support/index.html).