---
template: home.html
title: Home
hero:
  eyebrow: CINES · Adastra · AMD MI300A / MI250X
  lead: Run, train and scale AI workloads on Adastra.
  start: Get started
  start_link: getting-started/
  repo: Scripts on GitHub
hide:
  - navigation
  - toc
---

# cines.ai - Handbook

!!! warning "Work in progress"
    This handbook is under development. It covers running AI workloads on
    Adastra and is written for users new to the machine. For everything
    else, and for the best use of Adastra, the reference is the
    [official Adastra documentation](https://dci.dci-gitlab.cines.fr/webextranet/).

## Chapters

<div class="grid cards cines-modules" markdown>

-   **1 · Getting started**

    ---

    Partitions, Slurm project, storage, AI environment, first GPU job,
    GPU and communication checks.

    [:octicons-arrow-right-24: Start here](getting-started/index.md)

-   **2 · Data & models**

    ---

    Downloading on a login node, Hugging Face cache, offline mode in jobs.

    [:octicons-arrow-right-24: Data & models](data-models/index.md)

-   **3 · Inference**

    ---

    Batch inference with Transformers, LLM serving with vLLM, Diffusers.

    [:octicons-arrow-right-24: Inference](inference/index.md)

-   **4 · Training & fine-tuning**

    ---

    One GPU, DDP, LoRA/PEFT, FSDP, DeepSpeed, Accelerate, bf16.

    [:octicons-arrow-right-24: Training](training/index.md)

-   **5 · Profiling**

    ---

    PyTorch Profiler, rocprofv3.

    [:octicons-arrow-right-24: Profiling](profiling/index.md)

-   **A · Appendices**

    ---

    Build your own environment (uv), Slurm cheat sheet, MI300A vs MI250X,
    FAQ, glossary.

    [:octicons-arrow-right-24: Appendices](appendices/index.md)

</div>

## In three steps

<div class="cines-steps" markdown>

1. **Set up once** on a login node: clone the repository, set your Slurm
   project, `source env.sh`. → [Set up your environment](getting-started/setup.md)
2. **Run your first GPU job** and check the environment.
   → [First job](getting-started/first-job.md)
3. **Check GPUs and communications** before running on several GPUs.
   → [Checks](getting-started/checks.md)

</div>

!!! cines "Reference results"
    Results shown in this handbook are measured on Adastra, never estimated.
    A page marked *to be measured* has not been validated yet.