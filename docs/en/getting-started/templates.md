# Job templates

**Goal:** pick the right template; every handbook script runs with one of them.

All batch templates are submitted from the repository root, source `env.sh`,
write to `logs/` and take the script and its arguments on the command line:

```bash
sbatch slurm/<template> <script.py> [args]
```

| Template | Runs | Node | Use it for |
|---|---|---|---|
| `single_gpu.slurm` | `python` on 1 GPU | shared | first tests, inference, small fine-tuning |
| `single_node.slurm` | `torchrun`, one process per GPU | whole node | DDP / FSDP on one node |
| `multi_node.slurm` | `srun` + `torchrun` on N nodes | whole nodes | distributed training |
| `job_array.slurm` | one 1-GPU run per line of an arguments file | shared | sweeps (at most 128 tasks) |
| `interactive.sh` | `salloc`: an interactive allocation | shared | debugging |

On shared nodes, a job must ask for at least one GPU: the templates use
`--gpus-per-node=1`.

## Project

Each template starts with `#SBATCH --account=<project>`. You never edit it:
`env.sh` exports your project in `SBATCH_ACCOUNT` (and `SALLOC_ACCOUNT`),
which overrides that line. Without `source env.sh`, the submission fails
with `Invalid account`.

## MI250X overrides

Options on the `sbatch` command line win over the `#SBATCH` lines:

| Template | MI250X |
|---|---|
| `single_gpu.slurm`, `job_array.slurm` | `--constraint=MI250 --cpus-per-task=8` |
| `single_node.slurm`, `multi_node.slurm` | `--constraint=MI250 --gpus-per-node=8` |
| `interactive.sh` | `CONSTRAINT=MI250 bash slurm/interactive.sh 8` |

## Other common overrides

```bash
sbatch --time=01:00:00 slurm/single_gpu.slurm ...    # longer job
sbatch --nodes=4 slurm/multi_node.slurm ...          # more nodes
sbatch --array=0-9%4 slurm/job_array.slurm s.py args.txt   # 10 tasks, 4 at a time
```

Ref: [Adastra doc, Job submission](https://dci.dci-gitlab.cines.fr/webextranet/user_support/index.html).
