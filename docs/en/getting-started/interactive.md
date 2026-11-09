# Interactive session

**Goal:** run commands on a compute node to debug a script, and look into a
job that is already running.

## Interactive allocation (salloc)

=== "MI300A"

    ```bash
    bash slurm/interactive.sh          # 4 APUs on one node, 30 min
    ```

=== "MI250X"

    ```bash
    CONSTRAINT=MI250 bash slurm/interactive.sh 8     # 8 GCDs on one node, 30 min
    ```

`salloc` opens a new shell that holds the allocation. Longer session:
`TIME=01:00:00 bash slurm/interactive.sh`.

In this shell, source the environment again (offline mode, MIOpen cache),
then send commands to the compute node with `srun`:

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

## Interact with a running job

Open a shell on the node of a job that is running, for example to watch the
GPUs during a training run:

```bash
squeue --me                                  # job id and node
srun --jobid=<jobid> --overlap --pty bash    # shell inside the job
rocm-smi                                     # GPU use and memory
```

`--overlap` shares the job's resources instead of waiting for free ones;
`exit` leaves the shell, the job continues.

Ref: [Adastra doc, Job submission (interactive jobs)](https://dci.dci-gitlab.cines.fr/webextranet/user_support/index.html).
