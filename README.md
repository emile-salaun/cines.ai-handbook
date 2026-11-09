# cines.ai-handbook

Reference guide for AI on **Adastra** (CINES): the documentation and the
ready-to-run scripts it describes, in one repository. MI300A nodes by default,
MI250X through command-line overrides.

Site: <https://emile-salaun.github.io/cines.ai-handbook/> (English) ·
<https://emile-salaun.github.io/cines.ai-handbook/fr/> (français)

## Requirements

- An Adastra account and a project with GPU hours (`myproject -l`).
- The prebuilt AI environment of Adastra (loaded by `env.sh`).
- To preview the site only: Python ≥ 3.10 and `pip install zensical`, on any machine.

## Installation (Adastra login node)

```bash
cd $HOMEDIR
git clone https://github.com/emile-salaun/cines.ai-handbook.git
cd cines.ai-handbook
echo 'HANDBOOK_ACCOUNT=<project>' > env.local.sh   # your Slurm project, once
source env.sh                                      # every session
bash setup/download_assets.sh                      # test model into your cache
sbatch slurm/single_gpu.slurm diagnostics/check_env.py --model Qwen/Qwen2.5-0.5B
```

Jobs are submitted from the repository root; logs go to `logs/`.
The templates carry `#SBATCH --account=<project>`, replaced by your project
once `env.sh` is sourced.
Step by step: [Getting started](https://emile-salaun.github.io/cines.ai-handbook/getting-started/).

## Layout

```
cines.ai-handbook/
├── env.sh             # Slurm project, AI environment, HF cache, job variables
├── env.local.sh       # your settings (not in git): HANDBOOK_ACCOUNT=<project>
├── setup/             # downloads on a login node (models, datasets)
├── slurm/             # job templates (sbatch, salloc)
├── diagnostics/       # environment, GPU and RCCL checks
├── inference/         # chapter 3
├── training/          # chapter 4
├── benchmarks/        # chapter 5
├── profiling/         # chapter 6
├── workflows/         # chapter 7
├── logs/              # job logs (kept empty in git)
├── docs/en/, docs/fr/ # site pages, same file names in both languages
├── overrides/         # CINES branding: CSS, fonts, logos, home page
├── zensical.toml      # EN site (default) -> site/
├── zensical.fr.toml   # FR site           -> site/fr/
└── .github/workflows/docs.yml   # builds EN then FR, publishes on GitHub Pages
```

Folders are by topic; the reading order comes from the site navigation.

## Site preview

```bash
pip install zensical
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
| 5 | Scaling out | planned |
| 6 | Performance & profiling | planned |
| 7 | HPC workflows | planned |
| A | Appendices | planned |

## Contributing

`main` is stable; work in `feature/*`, `fix/*` or `docs/*` branches.
Everything is in English except `docs/fr/`. A chapter is done when its EN and
FR pages exist, its scripts are tested on MI300A and MI250X, and its reference
results are measured.

## License

Apache License 2.0, see [LICENSE](LICENSE) and [NOTICE](NOTICE).
