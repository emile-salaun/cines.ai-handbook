# Session interactive

**Objectif :** exécuter des commandes sur un nœud de calcul pour déboguer un
script, et observer un job déjà en cours.

## Allocation interactive (salloc)

=== "MI300A"

    ```bash
    bash slurm/interactive.sh          # 4 APU sur un nœud, 30 min
    ```

=== "MI250X"

    ```bash
    CONSTRAINT=MI250 bash slurm/interactive.sh 8     # 8 GCD sur un nœud, 30 min
    ```

`salloc` ouvre un nouveau shell qui détient l'allocation. Session plus
longue : `TIME=01:00:00 bash slurm/interactive.sh`.

Dans ce shell, sourcez à nouveau l'environnement (mode hors ligne, cache
MIOpen), puis envoyez les commandes au nœud de calcul avec `srun` :

```bash
source env.sh
srun python diagnostics/check_env.py
```

Plusieurs GPU :

=== "MI300A"

    ```bash
    OMP_NUM_THREADS=24 srun torchrun --standalone --nproc_per_node=4 \
        diagnostics/check_dist.py
    ```

=== "MI250X"

    ```bash
    OMP_NUM_THREADS=8 srun torchrun --standalone --nproc_per_node=8 \
        diagnostics/check_dist.py
    ```

`exit` libère l'allocation. Elle consomme les heures du projet tant qu'elle
est ouverte, même inactive.

## Interagir avec un job en cours

Ouvrir un shell sur le nœud d'un job en cours d'exécution, par exemple pour
observer les GPU pendant un entraînement :

```bash
squeue --me                                  # numéro du job et nœud
srun --jobid=<jobid> --overlap --pty bash    # shell à l'intérieur du job
rocm-smi                                     # utilisation et mémoire des GPU
```

`--overlap` partage les ressources du job au lieu d'attendre qu'elles se
libèrent ; `exit` quitte le shell, le job continue.

Réf. : [documentation Adastra, Job submission (interactive jobs)](https://dci.dci-gitlab.cines.fr/webextranet/user_support/index.html).
