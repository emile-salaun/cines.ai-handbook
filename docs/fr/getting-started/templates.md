# Modèles de jobs

**Objectif :** choisir le bon modèle ; chaque script du guide s'exécute avec
l'un d'eux.

Tous les modèles batch se soumettent depuis la racine du dépôt, sourcent
`env.sh`, écrivent dans `logs/` et prennent le script et ses arguments sur la
ligne de commande :

```bash
sbatch slurm/<modèle> <script.py> [args]
```

| Modèle | Lance | Nœud | Pour |
|---|---|---|---|
| `single_gpu.slurm` | `python` sur 1 GPU | partagé | premiers tests, inférence, petit fine-tuning |
| `single_node.slurm` | `torchrun`, un processus par GPU | nœud entier | DDP / FSDP sur un nœud |
| `interactive.sh` | `salloc` : une allocation interactive | partagé | débogage |

Sur les nœuds partagés, un job doit demander au moins un GPU : les modèles
utilisent `--gpus-per-node=1`.

## Projet

Chaque modèle commence par `#SBATCH --account=<project>`. Vous ne la modifiez
jamais : `env.sh` exporte votre projet dans `SBATCH_ACCOUNT` (et
`SALLOC_ACCOUNT`), qui remplace cette ligne. Sans `source env.sh`, la
soumission échoue avec `Invalid account`.

## Options MI250X

Les options de la ligne de commande `sbatch` l'emportent sur les lignes
`#SBATCH` :

| Modèle | MI250X |
|---|---|
| `single_gpu.slurm` | `--constraint=MI250 --cpus-per-task=8` |
| `single_node.slurm` | `--constraint=MI250 --gpus-per-node=8` |
| `interactive.sh` | `CONSTRAINT=MI250 bash slurm/interactive.sh 8` |

## Une autre option courante

```bash
sbatch --time=01:00:00 slurm/single_gpu.slurm ...    # job plus long
```

Réf. : [documentation Adastra, Job submission](https://dci.dci-gitlab.cines.fr/webextranet/user_support/index.html).