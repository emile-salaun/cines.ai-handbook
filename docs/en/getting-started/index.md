# Getting started

Discovering the Adastra GPU environment.

## What you need

- An Adastra login and a project with GPU hours (`myproject -l` lists your
  projects).
- An SSH connection to a login node: `ssh <login>@adastra.cines.fr`.

## Steps

<div class="cines-steps" markdown>

1. [Adastra at a glance](adastra.md): node types, storage areas, what runs where.
2. [Set up](setup.md): clone the repository, set your Slurm project once,
   activate the AI environment, download a test model.
3. [First job](first-job.md): one GPU, environment check.
4. [Job templates](templates.md): which template for which job, MI250X overrides.
5. [Interactive session](interactive.md): work on a compute node, look into a
   running job.
6. [GPU and communication checks](checks.md): GPUs seen by each process and
   RCCL, from one GPU to several nodes.

</div>

!!! cines "MI300A by default"
    Every command targets MI300A nodes. For MI250X, each page gives the
    override in a second tab.
