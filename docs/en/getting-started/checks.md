# GPU and communication checks

**Goal:** before any performance measurement, check that each process uses
its own GPU and that RCCL works between GPUs and between nodes.

## One node

=== "MI300A"

    ```bash
    sbatch slurm/single_node.slurm diagnostics/check_dist.py
    ```

=== "MI250X"

    ```bash
    sbatch --constraint=MI250 --gpus-per-node=8 slurm/single_node.slurm diagnostics/check_dist.py
    ```

### What to look at

One line per process, then the all_reduce result:

=== "MI300A"

    ```text
    host=<node> rank=0 gpu=0 (gfx942) cores=<n> omp=24
    host=<node> rank=1 gpu=1 (gfx942) cores=<n> omp=24
    host=<node> rank=2 gpu=2 (gfx942) cores=<n> omp=24
    host=<node> rank=3 gpu=3 (gfx942) cores=<n> omp=24
    OK: all_reduce over 4 processes = 10
    ```

=== "MI250X"

    ```text
    host=<node> rank=0 gpu=0 (gfx90a) cores=<n> omp=8
    ...
    host=<node> rank=7 gpu=7 (gfx90a) cores=<n> omp=8
    OK: all_reduce over 8 processes = 36
    ```

- Each rank has a different `gpu`: two ranks on the same GPU share its
  memory and compute.
- `omp`: the node's physical cores divided by its GPUs.
- `OK: all_reduce`: RCCL works between the GPUs of the node.

## Several nodes

=== "MI300A"

    ```bash
    NCCL_DEBUG=INFO NCCL_DEBUG_SUBSYS=INIT,NET \
        sbatch slurm/multi_node.slurm diagnostics/check_dist.py
    ```

=== "MI250X"

    ```bash
    NCCL_DEBUG=INFO NCCL_DEBUG_SUBSYS=INIT,NET \
        sbatch --constraint=MI250 --gpus-per-node=8 slurm/multi_node.slurm diagnostics/check_dist.py
    ```

### What to look at

- 8 placement lines on MI300A (2 nodes × 4), 16 on MI250X, on two different
  hosts, and `OK: all_reduce over 8 processes = 36` (MI300A) or
  `over 16 processes = 136` (MI250X).
- RCCL uses the Slingshot network:

    ```bash
    grep "Selected Provider is cxi" logs/multi_node_<jobid>.out
    ```

    No match: RCCL falls back to TCP sockets and multi-node jobs will be slow.
    Check the `aws-ofi-rccl plugin` line of `check_env.py`.

Ref: [Adastra doc, Software stack, libraries (Torch elastic, aws-ofi-rccl)](https://dci.dci-gitlab.cines.fr/webextranet/software_stack/libraries/index.html).

## One GPU

`sbatch slurm/single_gpu.slurm diagnostics/check_dist.py` prints a single
placement line, with `cores=24` (MI300A) or `cores=8` (MI250X).

## Reference result

| Partition | Test | Elapsed | Status |
|---|---|---|---|
| MI300A | one node, 2 nodes | — | to be measured |
| MI250X | one node, 2 nodes | — | to be measured |
