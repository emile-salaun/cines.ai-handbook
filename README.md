# cines.ai-handbook

Reference guide for AI on **Adastra** (CINES): the documentation and the
ready-to-run scripts it describes, in one repository. MI300A nodes by default,
MI250X through command-line overrides.

Handbook: <https://emile-salaun.github.io/cines.ai-handbook/>

> **Work in progress.** This handbook is under development. It covers running AI
> workloads on Adastra and is written for users new to the machine. For everything
> else, and for the best use of Adastra, the reference is the
> [official Adastra documentation](https://dci.dci-gitlab.cines.fr/webextranet/).

## Requirements

- An Adastra account and a project with GPU hours (`myproject -l`).
- The prebuilt AI environment of Adastra (loaded by `env.sh`), or the handbook's
  uv environment (`uv` from `module load python`).

## Installation (Adastra login node)

```bash
cd $WORKDIR
git clone https://github.com/emile-salaun/cines.ai-handbook.git
cd cines.ai-handbook
echo 'ACCOUNT=<project>' > env.local.sh            # your Slurm project, once
source env.sh                                      # every session
bash setup/download_assets.sh                      # models and dataset of the examples
sbatch diagnostics/check_env.sh                    # first GPU job
```

Jobs are submitted from the repository root; logs go to `logs/`.
Job scripts carry `#SBATCH --account=<project>`, replaced by your project
once `env.sh` is sourced. Your own jobs: copy a template from `slurm/` and
adapt the lines marked `EDIT`.
Step by step: [Getting started](https://emile-salaun.github.io/cines.ai-handbook/getting-started/).

The handbook's uv environment instead of the prebuilt one:

```bash
module load python                  # login node, repository root
uv sync --locked                    # base; add --group <chapter> for a chapter's packages
echo 'AI_ENV=uv' >> env.local.sh    # then open a new shell
```

## Layout

```
cines.ai-handbook/
├── env.sh             # Slurm project, Python environment, HF cache; offline mode in jobs
├── env.local.sh       # your settings (not in git): ACCOUNT=<project>
├── pyproject.toml     # handbook uv environment: base + dependency groups (uv.lock)
├── setup/             # login node: download the models and dataset of the examples
├── slurm/             # job script templates to copy (EDIT lines)
├── diagnostics/       # environment, GPU, RCCL and offline data checks, with their ready-to-run .sh
├── jobs/              # your own job scripts (not in git)
├── inference/         # chapter 3
├── training/          # chapter 4
├── profiling/         # chapter 5
└── logs/              # job logs (kept empty in git)
```

Folders are by topic; the reading order is that of the chapters of the
[handbook](https://emile-salaun.github.io/cines.ai-handbook/).

## Status

| # | Chapter | Status |
|---|---|---|
| 1 | Getting started | written; tested on MI300A and MI250X (prebuilt environment), uv environment to test |
| 2 | Data & models | written; tested on MI300A and MI250X (prebuilt environment) |
| 3 | Inference | in progress: batch generation with Transformers written |
| 4 | Training & fine-tuning | planned |
| 5 | Profiling | planned |
| A | Appendices | "Build your own environment (uv)" written; others planned |

## Contributing

`main` is stable; work in `feature/*`, `fix/*` or `docs/*` branches.
Everything is in English. A chapter is done when its pages exist, its scripts
are tested on MI300A and MI250X, and its reference results are measured.

## License

Apache License 2.0, see [LICENSE](LICENSE) and [NOTICE](NOTICE), except:

- the CINES name and logos (`overrides/assets/logo/`): trademarks of CINES, not
  covered by the Apache License 2.0, all rights reserved;
- the Poppins and Lato fonts (`overrides/assets/fonts/`): SIL Open Font
  License 1.1, see [OFL.txt](overrides/assets/fonts/OFL.txt).