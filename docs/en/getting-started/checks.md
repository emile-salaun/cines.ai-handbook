# GPU and communication checks

**Goal:** before any performance measurement, check that each process uses
its own GPU and that RCCL works between the GPUs of a node.

**Before you start:** a login shell in the repository, after `source env.sh`
(see [Set up your environment](setup.md)).

## One node

`diagnostics/check_dist.sh` is built from the [template](templates.md)
`slurm/single_node.sh`: torchrun, one process per GPU, the whole node.

=== "MI300A"

    ```bash
    sbatch diagnostics/check_dist.sh
    ```

=== "MI250X"

    ```bash
    sbatch --constraint=MI250 --gpus-per-node=8 diagnostics/check_dist.sh
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

| Failure | Cause |
|---|---|
| `sbatch: error: Batch job submission failed: Invalid account or account/partition combination specified` | `env.sh` not sourced in this shell, or `ACCOUNT` not set: see [Set up your environment](setup.md) |

Ref: [Adastra doc, Software stack, libraries](https://dci.dci-gitlab.cines.fr/webextranet/software_stack/libraries/index.html).

## Reference result

The `Elapsed` value of `sacct -X -j <jobid> -o Elapsed`.

| Partition | Test | Elapsed | Status |
|---|---|---|---|
| MI300A | one node | — | to be measured |
| MI250X | one node | — | to be measured |