# Adastra en bref

**Objectif :** savoir quel type de nœud demander et où ranger vos fichiers.

## Types de nœuds

Le type de nœud se choisit avec `--constraint`. Tous les modèles de jobs du
guide utilisent `--constraint=MI300`.

| Contrainte | Nœud | GPU vus par PyTorch | Mémoire GPU | Mémoire CPU | Cœurs CPU |
|---|---|---|---|---|---|
| `MI300` (défaut) | 4 × APU AMD MI300A (`gfx942`) | 4 | 128 Gio HBM3 par APU | la même HBM3 (unifiée avec le GPU) | 96 (24 par APU) |
| `MI250` | 4 × AMD MI250X = 8 GCD (`gfx90a`) + 1 × AMD EPYC 7A53 | 8 | 64 Gio HBM2e par GCD | 256 Gio DDR4 | 64 (8 par GCD) |
| `GENOA` | 2 × AMD EPYC 9654, sans GPU | 0 | — | 768 Gio DDR5 | 192 |

Sur MI250X, chaque GCD est un GPU indépendant : un nœud en compte 8.
Sur MI300A, CPU et GPU partagent la même mémoire : pas de copie hôte ↔ GPU,
mais les processus CPU et le GPU se partagent les mêmes 128 Gio par APU.

Réf. : [documentation Adastra, Architecture](https://dci.dci-gitlab.cines.fr/webextranet/architecture/index.html).

## Nœuds de connexion et de calcul

| | Nœuds de connexion | Nœuds de calcul |
|---|---|---|
| Internet | filtré | aucun |
| Usage | éditer, télécharger les modèles, soumettre les jobs | exécuter les jobs (`sbatch`, `salloc`, `srun`) |
| Apptainer | non | oui |

Tout ce dont un job a besoin (modèles, jeux de données, paquets Python) doit
être sur disque avant son démarrage. Les jobs du guide tournent avec
`HF_HUB_OFFLINE=1`.

## Stockage

| Variable | Usage dans le guide | Purge |
|---|---|---|
| `$HOMEDIR` | le dépôt (`cines.ai-handbook/`), petits fichiers de configuration | jamais |
| `$WORKDIR` | environnement IA, modèles Hugging Face (`$HF_HOME`), jeux de données (`$HANDBOOK_DATA`) | jamais |
| `$SCRATCHDIR` | sorties des jobs (`$HANDBOOK_OUTPUT`), cache des jeux de données, checkpoints | fichiers inutilisés depuis 30 jours |
| `$SHAREDWORKDIR`, `$SHAREDSCRATCHDIR` | idem, partagés dans le projet | comme ci-dessus |

Vérifiez vos quotas avec `myproject -s <projet>`.

Réf. : [documentation Adastra, Data storage and transfers](https://dci.dci-gitlab.cines.fr/webextranet/data_storage_and_transfers/index.html).
