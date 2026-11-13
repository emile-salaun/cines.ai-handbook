# Interactive session

**Goal:** run commands on a compute node to debug a script, and look into a
job that is already running.

**Before you start:** a login shell in the repository, and the handbook
example assets downloaded (see [Set up your environment](setup.md)).

## Interactive allocation (salloc)

From the repository root, replace `<project>` with your project:

=== "MI300A"

    ```bash
    # 1 APU, 30 min
    salloc --account=<project> --constraint=MI300 --nodes=1 --ntasks=1 --gpus-per-node=1 --cpus-per-task=24 --time=00:30:00
    # whole node (4 APUs), 30 min
    salloc --account=<project> --constraint=MI300 --nodes=1 --ntasks=1 --gpus-per-node=4 --cpus-per-task=96 --time=00:30:00
    ```

=== "MI250X"

    ```bash
    # 1 GCD, 30 min
    salloc --account=<project> --constraint=MI250 --nodes=1 --ntasks=1 --gpus-per-node=1 --cpus-per-task=8 --time=00:30:00
    # whole node (8 GCDs), 30 min
    salloc --account=<project> --constraint=MI250 --nodes=1 --ntasks=1 --gpus-per-node=8 --cpus-per-task=64 --time=00:30:00
    ```

| Option | Sets | Value |
|---|---|---|
| `--account` | project charged for the hours | your project |
| `--constraint` | node type | `MI300` (MI300A) or `MI250` (MI250X) |
| `--gpus-per-node` | GPUs | 1 to 4 (MI300A), 1 to 8 (MI250X); at least 1 on shared nodes |
| `--cpus-per-task` | CPU cores | 24 per GPU (MI300A), 8 per GPU (MI250X) |
| `--time` | maximum duration | `HH:MM:SS` |
| `--nodes` | number of nodes | `N` |
| `--ntasks` | number of tasks | `N` |

`salloc` opens a new shell that holds the allocation.

### What to look at

```text
salloc: Granted job allocation <jobid>
salloc: Nodes <node> are ready for job
```

The new shell **stays on the login node**: `hostname` shows the login node.
Only commands started with `srun` run on the allocated node:

```bash
srun hostname                            # the allocated node
echo $SLURM_JOB_NODELIST                 # the allocated node, at any time in this shell
squeue --me -O JobID,NodeList,TimeLeft   # node and time left
```

## Run commands on the node

In this shell, `source env.sh`: it activates the Python environment, and the
commands sent to the compute node with `srun` run offline (`HF_HUB_OFFLINE=1`).
The shell itself stays online: downloads work there.

```bash
source env.sh
srun python diagnostics/check_env.py
```

Several GPUs:

=== "MI300A"

    ```bash
    OMP_NUM_THREADS=24 srun torchrun --standalone --nproc_per_node=4 \
        diagnostics/check_dist.py
    ```

=== "MI250X"

    ```bash
    OMP_NUM_THREADS=8 srun torchrun --standalone --nproc_per_node=8 \
        diagnostics/check_dist.py
    ```

`exit` releases the allocation. It uses your project hours while it is open,
even when idle.

| Failure | Cause |
|---|---|
| `python: No such file or directory`, or `No module named 'torch'` | `env.sh` not sourced in the `salloc` shell: `source env.sh`, then the `srun` command again |
| `offline load` fails in `check_env.py` | model not downloaded: `bash setup/download_assets.sh` in this shell or a login shell |

## Interact with a running job

Open a shell on the node of a job that is running, for example to watch the
GPUs during a training run:

```bash
squeue --me                                  # job id and node
```

=== "srun --overlap"

    ```bash
    srun --jobid=<jobid> --overlap --pty bash    # shell inside the job
    rocm-smi                                     # GPU use and memory
    ```

    The shell runs inside the job, with its resources and environment.
    `--overlap` shares the job's resources instead of waiting for free ones;
    `exit` leaves the shell, the job continues.

=== "ssh"

    ```bash
    ssh <node>    # only on a node where you have a job
    rocm-smi      # GPU use and memory
    ```

    The shell runs on the node, outside the job context: use it to watch
    the job, not to run your scripts. `exit` leaves the shell, the job
    continues.

Ref: [Adastra doc, Job submission (interactive jobs)](https://dci.dci-gitlab.cines.fr/webextranet/user_support/index.html).