---
template: home.html
title: Accueil
hero:
  eyebrow: CINES · Adastra · AMD MI300A / MI250X
  lead: Exécuter, entraîner et passer à l'échelle vos calculs d'IA sur Adastra.
  start: Commencer
  start_link: getting-started/
  repo: Scripts sur GitHub
hide:
  - navigation
  - toc
---

# cines.ai - Handbook

!!! warning "En cours de rédaction"
    Ce guide est en cours de développement. Il traite de l'exécution de
    calculs d'IA sur Adastra et s'adresse aux utilisateurs qui découvrent la
    machine. Pour tout le reste, et pour utiliser Adastra au mieux, la
    référence est la [documentation officielle d'Adastra](https://dci.dci-gitlab.cines.fr/webextranet/).

## Chapitres

<div class="grid cards cines-modules" markdown>

-   **1 · Prise en main**

    ---

    Partitions, projet Slurm, stockage, environnement IA, premier job GPU,
    vérification des GPU et des communications.

    [:octicons-arrow-right-24: Commencer ici](getting-started/index.md)

-   **2 · Données et modèles**

    ---

    Téléchargement sur un nœud de connexion, cache Hugging Face, mode hors
    ligne dans les jobs.

    [:octicons-arrow-right-24: Données et modèles](data-models/index.md)

-   **3 · Inférence**

    ---

    Inférence par lots avec Transformers, service de LLM avec vLLM, Diffusers.

    [:octicons-arrow-right-24: Inférence](inference/index.md)

-   **4 · Entraînement et fine-tuning**

    ---

    Un GPU, DDP, LoRA/PEFT, FSDP, DeepSpeed, Accelerate, bf16.

    [:octicons-arrow-right-24: Entraînement](training/index.md)

-   **5 · Profilage**

    ---

    PyTorch Profiler, rocprofv3.

    [:octicons-arrow-right-24: Profilage](profiling/index.md)

-   **A · Annexes**

    ---

    Construire votre propre environnement (uv), aide-mémoire Slurm,
    MI300A vs MI250X, FAQ, glossaire.

    [:octicons-arrow-right-24: Annexes](appendices/index.md)

</div>

## En trois étapes

<div class="cines-steps" markdown>

1. **Installer une fois** sur un nœud de connexion : cloner le dépôt, définir
   votre projet Slurm, `source env.sh`. → [Configurer votre environnement](getting-started/setup.md)
2. **Lancer un premier job GPU** et vérifier l'environnement.
   → [Premier job](getting-started/first-job.md)
3. **Vérifier les GPU et les communications** avant d'utiliser plusieurs GPU.
   → [Vérifications](getting-started/checks.md)

</div>

!!! cines "Résultats de référence"
    Les résultats donnés dans ce guide sont mesurés sur Adastra, jamais
    estimés. Une page marquée *à mesurer* n'a pas encore été validée.