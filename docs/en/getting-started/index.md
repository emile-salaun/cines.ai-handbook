# Getting started

This chapter takes you from your first login to a GPU job. It covers what
you need for AI jobs; for everything else, see the
[official Adastra documentation](https://dci.dci-gitlab.cines.fr/webextranet/).

## Requirements

- An Adastra login and a project with GPU hours (`myproject -l` lists your
  projects).
- An SSH connection to a login node: `ssh <login>@adastra.cines.fr`.

## Steps

<div class="cines-steps" markdown>

1. [Adastra at a glance](adastra.md): node types, storage areas, what runs where.
2. [Set up your environment](setup.md): clone the repository, set your Slurm
   project once, choose the prebuilt AI environment or the handbook's uv
   environment, download a test model.
3. [First job](first-job.md): one GPU, environment check.
4. [Write your job script](templates.md): copy a template and adapt it.
5. [Interactive session](interactive.md): work on a compute node, look into a
   running job.
6. [GPU and communication checks](checks.md): GPUs seen by each process and
   RCCL, on one node.

</div>

!!! cines "MI300A by default"
    Every command targets MI300A nodes. For MI250X, each page gives the
    override in a second tab.