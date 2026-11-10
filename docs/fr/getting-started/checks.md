# Vérifications GPU et communications

**Objectif :** avant toute mesure de performance, vérifier que chaque
processus utilise son propre GPU et que RCCL fonctionne entre les GPU d'un
nœud.

## Un nœud

=== "MI300A"

    ```bash
    sbatch slurm/single_node.slurm diagnostics/check_dist.py
    ```

=== "MI250X"

    ```bash
    sbatch --constraint=MI250 --gpus-per-node=8 slurm/single_node.slurm diagnostics/check_dist.py
    ```

### Ce qu'il faut regarder

Une ligne par processus, puis le résultat de l'all_reduce :

=== "MI300A"

    ```text
    host=<node> rank=0 gpu=0 (gfx942) cores=<n> omp=24
    host=<node> rank=1 gpu=1 (gfx942) cores=<n> omp=24
    host=<node> rank=2 gpu=2 (gfx942) cores=<n> omp=24
    host=<node> rank=3 gpu=3 (gfx942) cores=<n> omp=24
    OK: all_reduce over 4 processes = 10
    ```

=== "MI250X"

    ```text
    host=<node> rank=0 gpu=0 (gfx90a) cores=<n> omp=8
    ...
    host=<node> rank=7 gpu=7 (gfx90a) cores=<n> omp=8
    OK: all_reduce over 8 processes = 36
    ```

- Chaque rang a un `gpu` différent : deux rangs sur le même GPU se partagent
  sa mémoire et sa puissance de calcul.
- `omp` : les cœurs physiques du nœud divisés par son nombre de GPU.
- `OK: all_reduce` : RCCL fonctionne entre les GPU du nœud.

Réf. : [documentation Adastra, Software stack, libraries](https://dci.dci-gitlab.cines.fr/webextranet/software_stack/libraries/index.html).

## Un GPU

`sbatch slurm/single_gpu.slurm diagnostics/check_dist.py` affiche une seule
ligne de placement, avec `cores=24` (MI300A) ou `cores=8` (MI250X).

## Résultat de référence

| Partition | Test | Durée | Statut |
|---|---|---|---|
| MI300A | un nœud | — | à mesurer |
| MI250X | un nœud | — | à mesurer |