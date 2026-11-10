# cines.ai-handbook

Reference guide for AI on **Adastra** (CINES): the documentation and the
ready-to-run scripts it describes, in one repository. MI300A nodes by default,
MI250X through command-line overrides.

Site: <https://emile-salaun.github.io/cines.ai-handbook/> (English) ·
<https://emile-salaun.github.io/cines.ai-handbook/fr/> (français)

> **Work in progress.** This handbook is under development. It covers running AI
> workloads on Adastra and is written for users new to the machine. For everything
> else, and for the best use of Adastra, the reference is the
> [official Adastra documentation](https://dci.dci-gitlab.cines.fr/webextranet/).

## Requirements

- An Adastra account and a project with GPU hours (`myproject -l`).
- The prebuilt AI environment of Adastra (loaded by `env.sh`), or the handbook's
  uv environment (`uv` from `module load python`).
- To preview the site only: Python ≥ 3.10 and `pip install -r docs/requirements.txt`, on any machine.

## Installation (Adastra login node)

```bash
cd $WORKDIR
git clone https://github.com/emile-salaun/cines.ai-handbook.git
cd cines.ai-handbook
echo 'ACCOUNT=<project>' > env.local.sh            # your Slurm project, once
source env.sh                                      # every session
bash setup/download_assets.sh                      # test model into your cache
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
├── env.sh             # Slurm project, Python environment, HF cache, job variables
├── env.local.sh       # your settings (not in git): ACCOUNT=<project>
├── pyproject.toml     # handbook uv environment: base + dependency groups (uv.lock, .python-version)
├── setup/             # login node: models and datasets
├── slurm/             # job script templates to copy (EDIT lines)
├── diagnostics/       # environment, GPU and RCCL checks, with their ready-to-run .sh
├── jobs/              # your own job scripts (not in git)
├── inference/         # chapter 3
├── training/          # chapter 4
├── profiling/         # chapter 5
├── logs/              # job logs (kept empty in git)
├── docs/en/, docs/fr/ # site pages, same file names in both languages
├── docs/requirements.txt  # site build dependency (pinned Zensical)
├── overrides/         # CINES branding: CSS, fonts, logos, home page
├── zensical.toml      # EN site (default) -> site/
├── zensical.fr.toml   # FR site           -> site/fr/
└── .github/           # docs.yml: builds EN then FR, publishes on GitHub Pages
```

Folders are by topic; the reading order comes from the site navigation.

## Site preview

```bash
pip install -r docs/requirements.txt
zensical serve                                        # EN: http://localhost:8000
zensical serve -f zensical.fr.toml -a localhost:8001  # FR: http://localhost:8001
```

Full build, as in CI (EN first: its build wipes `site/`):

```bash
zensical build && zensical build -f zensical.fr.toml
```

The CINES logos go in `overrides/assets/logo/` (`cines-logo-inverse.svg`,
`favicon.svg`, `cines-logo-baseline-inverse.svg`), unchanged.

## Status

| # | Chapter | Status |
|---|---|---|
| 1 | Getting started | written, to be tested on Adastra |
| 2 | Data & models | planned |
| 3 | Inference | planned |
| 4 | Training & fine-tuning | planned |
| 5 | Profiling | planned |
| A | Appendices | "Build your own environment (uv)" written; others planned |

## Contributing

`main` is stable; work in `feature/*`, `fix/*` or `docs/*` branches.
Everything is in English except `docs/fr/`. A chapter is done when its EN and
FR pages exist, its scripts are tested on MI300A and MI250X, and its reference
results are measured.

## License

Apache License 2.0, see [LICENSE](LICENSE) and [NOTICE](NOTICE).