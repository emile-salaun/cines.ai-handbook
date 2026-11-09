# Premier job

**Objectif :** exécuter un script Python sur un GPU et vérifier l'environnement.

## Commande

Depuis la racine du dépôt, après `source env.sh` :

=== "MI300A"

    ```bash
    sbatch slurm/single_gpu.slurm diagnostics/check_env.py --model Qwen/Qwen2.5-0.5B
    ```

=== "MI250X"

    ```bash
    sbatch --constraint=MI250 --cpus-per-task=8 \
        slurm/single_gpu.slurm diagnostics/check_env.py --model Qwen/Qwen2.5-0.5B
    ```

Suivez le job avec `squeue --me`, puis lisez le journal :

```bash
cat logs/single_gpu_<jobid>.out
```

## Ce qu'il faut regarder

Chaque journal commence et se termine de la même façon :

```text
[job] single_gpu <jobid> started at <date>
[job] nodes: <node> (1), GPUs per node: 1
[env] HANDBOOK_ACCOUNT=<project>
[env] AI environment: <WORKDIR>/envs/venv-0.8.0-torch2.11.0-rocm7.2.0
[env] HF_HOME=<WORKDIR>/hf
[env] HF_HUB_OFFLINE=1  MIOPEN_USER_DB_PATH=/tmp/<user>-miopen-cache-<jobid>
[run] python diagnostics/check_env.py --model Qwen/Qwen2.5-0.5B
...
[job] ended at <date>, elapsed <hh:mm:ss>, exit code 0
```

Entre les deux, la sortie de `check_env.py` :

- Une ligne `[OK]` par vérification, et `All checks passed.` à la fin.
- `GPU 0 matmul` : l'architecture est `gfx942` sur MI300A, `gfx90a` sur MI250X.
- `offline load of Qwen/Qwen2.5-0.5B` : le modèle est lu depuis votre cache,
  sans internet.
- `[WARN] aws-ofi-rccl plugin not found` : sans effet sur un nœud, bloquant
  pour les jobs multi-nœuds (voir [vérifications](checks.md)).

| Échec | Cause |
|---|---|
| `Invalid account` à la soumission | `env.sh` non sourcé, ou `HANDBOOK_ACCOUNT` non défini : voir [Installation](setup.md) |
| `offline load` échoue | modèle non téléchargé : `bash setup/download_assets.sh` sur un nœud de connexion |
| pas de fichier journal | job soumis hors de la racine du dépôt (`logs/` introuvable) |

## Résultat de référence

La valeur `elapsed` de la dernière ligne du journal.

| Partition | Durée | Statut |
|---|---|---|
| MI300A | — | à mesurer |
| MI250X | — | à mesurer |
