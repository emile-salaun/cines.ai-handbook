# Construire votre propre environnement (uv)

**Objectif :** un environnement uv à vous (autre version de PyTorch ou de
ROCm, paquets supplémentaires), utilisé avec les modèles de jobs du guide.

L'environnement uv du guide ([Configurer votre environnement](../getting-started/setup.md),
onglet uv) est fixe : les mêmes versions pour tout le monde. Construisez le
vôtre quand il vous faut autre chose. Tout ce qui suit s'exécute sur un nœud
de connexion.

## Créer le projet

```bash
cd $HOMEDIR/cines.ai-handbook
bash setup/setup_uv_env.sh --uv-only                      # (1)!
source env.sh
mkdir -p $WORKDIR/myenv
cp pyproject.toml .python-version $WORKDIR/myenv/         # (2)!
cd $WORKDIR/myenv
uv sync                                                   # (3)!
```

1. Installe uv seul (version figée, SHA-256 vérifié) dans `$WORKDIR/uv/bin` ;
   `source env.sh` l'ajoute au `PATH`.
2. Part des dépendances du guide. Changez `name` dans `pyproject.toml`.
3. Crée `.venv` et `uv.lock` dans `$WORKDIR/myenv`.

## Ajouter des paquets

```bash
uv add accelerate peft      # les installe, les enregistre dans pyproject.toml et uv.lock
```

`uv.lock` fixe toutes les versions : gardez-le avec `pyproject.toml` (dans
un dépôt git à vous, par exemple) pour reconstruire plus tard le même
environnement avec `uv sync --locked`.

## Changer de version de PyTorch ou de ROCm

Dans `pyproject.toml`, l'index PyTorch fixe la version de ROCm des wheels,
et la ligne `torch` la version de PyTorch :

```toml
dependencies = [
    "torch==2.11.*",                                  # version de PyTorch
    ...
]

[[tool.uv.index]]
name = "pytorch-rocm"
url = "https://download.pytorch.org/whl/rocm7.2"      # version de ROCm
explicit = true
```

Puis `uv lock --upgrade-package torch` et `uv sync`.

Le wheel embarque ses propres bibliothèques ROCm, mais elles doivent
fonctionner avec le pilote GPU des nœuds : consultez la
[matrice de compatibilité ROCm](https://rocm.docs.amd.com/en/latest/compatibility/compatibility-matrix.html).
Le test fiable reste `check_env.py` sur les deux types de nœuds (ci-dessous).

## L'utiliser avec les modèles du guide

Dans le `env.local.sh` du guide :

```bash
AI_ENV=uv
AI_UV_VENV_PATH=$WORKDIR/myenv/.venv
```

Ouvrez un nouveau shell, `source env.sh` : la ligne
`[env] Python environment (uv)` affiche votre environnement, et tous les
modèles de jobs l'utilisent.

## Compiler des extensions

Les paquets compilés pour le GPU à l'installation (flash-attention, par
exemple) ont besoin des compilateurs ROCm du système, dans la même version que
le wheel (`python -c "import torch; print(torch.version.hip)"`) :

```bash
module load rocm/<version>                   # (1)!
export PYTORCH_ROCM_ARCH="gfx942;gfx90a"     # (2)!
export MAX_JOBS=8                            # (3)!
uv add --no-build-isolation <paquet>
module purge
```

1. `module avail rocm` liste les versions disponibles sur Adastra.
2. Compile pour MI300A (`gfx942`) et MI250X (`gfx90a`).
3. Limite la compilation parallèle sur le nœud de connexion partagé.

## Vérifier

=== "MI300A"

    ```bash
    sbatch slurm/single_gpu.slurm diagnostics/check_env.py --model Qwen/Qwen2.5-0.5B
    ```

=== "MI250X"

    ```bash
    sbatch --constraint=MI250 --cpus-per-task=8 \
        slurm/single_gpu.slurm diagnostics/check_env.py --model Qwen/Qwen2.5-0.5B
    ```

`All checks passed.`, avec `gfx942` (MI300A) ou `gfx90a` (MI250X) sur la
ligne `GPU 0 matmul`. Une erreur HIP à la première opération GPU signale en
général une version de ROCm que le pilote du nœud ne prend pas en charge.

## Pièges

| Symptôme | Cause, solution |
|---|---|
| `[env] WARNING: LD_LIBRARY_PATH contains ROCm` | Modules ROCm du système chargés : `module purge` avant `source env.sh`. |
| `GPU 0 matmul` échoue, architecture absente | Le wheel n'est pas compilé pour le GPU du nœud : autre version de PyTorch ou de ROCm. |
| Quota disque dépassé (inodes) | Un environnement compte des dizaines de milliers de fichiers : `du -sh --inodes $WORKDIR/*`, supprimez les environnements inutilisés. |
| `$SCRATCHDIR` plein | Cache de téléchargement : `uv cache clean`. |
| Environnement cassé après quelques semaines | Il était dans `$SCRATCHDIR` (purgé) : gardez les environnements dans `$WORKDIR`. |

Réf. : [uv, Using uv with PyTorch](https://docs.astral.sh/uv/guides/integration/pytorch/).