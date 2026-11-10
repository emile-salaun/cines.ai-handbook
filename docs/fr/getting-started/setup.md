# Configurer votre environnement

**Objectif :** un shell de connexion où `sbatch` utilise votre projet et où
Python est prêt pour les scripts du guide. À faire une fois ; ensuite une
commande par session.

## Une fois

Sur un nœud de connexion :

```bash
cd $HOMEDIR
git clone https://github.com/emile-salaun/cines.ai-handbook.git
cd cines.ai-handbook
echo 'ACCOUNT=<project>' > env.local.sh   # (1)!
```

1. Votre projet Slurm (`myproject -l` les liste). `env.local.sh` est ignoré
   par git.

Choisissez ensuite votre environnement Python :

=== "Prebuilt"

    L'environnement IA préinstallé d'Adastra, maintenu par le CINES.
    **Recommandé.**

    ```bash
    source env.sh       # (1)!
    ```

    1. La première fois, charge les modules IA et crée votre environnement
       dans `$WORKDIR/envs/`. Compter quelques minutes.

=== "uv"

    L'environnement fixe du guide, installé avec
    [uv](https://docs.astral.sh/uv/) à partir de `pyproject.toml` et
    `uv.lock` : les mêmes versions pour tout le monde, indépendamment de
    l'environnement préinstallé.

    ```bash
    bash setup/setup_uv_env.sh            # (1)!
    echo 'AI_ENV=uv' >> env.local.sh      # (2)!
    source env.sh
    ```

    1. Installe uv dans `$WORKDIR/uv`, Python (version dans `.python-version`),
       puis les versions exactes de `uv.lock` dans `$WORKDIR/envs/uv-handbook` :
       PyTorch pour ROCm, Transformers, Hugging Face Hub. La première
       exécution télécharge plusieurs Go. Elle se termine par
       `[setup_uv] torch <version>+rocm7.2..., HIP <version>`.
    2. Chaque nouveau shell et chaque job utilise désormais cet environnement.
       Ouvrez un nouveau shell avant `source env.sh`.

    Autres versions ou paquets :
    [Construire votre propre environnement (uv)](../appendices/own-env.md).
    Revenir à l'environnement préinstallé : supprimez la ligne `AI_ENV=uv` de
    `env.local.sh`.

    ??? note "Bon à savoir"
        - **Nœuds de calcul :** pas d'internet. Dans les jobs, `env.sh` définit
          `UV_OFFLINE=1`.
        - **Bibliothèques ROCm :** le wheel PyTorch embarque les siennes. Si
          `env.sh` signale que `LD_LIBRARY_PATH` contient ROCm, lancez
          `module purge` avant `source env.sh`.
        - **Espace disque :** environnement dans `$WORKDIR` (plusieurs Go),
          cache de téléchargement dans `$SCRATCHDIR/uv-cache` : libérez-le avec
          `uv cache clean`.
        - **Sécurité :** `setup_uv_env.sh` installe une version figée de uv et
          vérifie son SHA-256 avant de l'utiliser.

        Réf. : [uv, Using uv with PyTorch](https://docs.astral.sh/uv/guides/integration/pytorch/).

Enfin, téléchargez le modèle de test (`Qwen/Qwen2.5-0.5B`, environ 1 Go) dans
`$WORKDIR/hf` :

```bash
bash setup/download_assets.sh
```

## À chaque session

```bash
cd $HOMEDIR/cines.ai-handbook
source env.sh
```

## Ce qu'il faut regarder

=== "Prebuilt"

    ```text
    [env] ACCOUNT=<project>
    [env] Python environment (prebuilt): <WORKDIR>/envs/venv-0.8.0-torch2.11.0-rocm7.2.0
    [env] HF_HOME=<WORKDIR>/hf
    [env] DATA_DIR=<WORKDIR>/handbook/datasets
    [env] OUTPUT_DIR=<SCRATCHDIR>/handbook
    ```

    `ERROR: no AI environment` : lisez les messages des modules juste au-dessus.

=== "uv"

    ```text
    [env] ACCOUNT=<project>
    [env] Python environment (uv): <WORKDIR>/envs/uv-handbook
    [env] HF_HOME=<WORKDIR>/hf
    [env] DATA_DIR=<WORKDIR>/handbook/datasets
    [env] OUTPUT_DIR=<SCRATCHDIR>/handbook
    ```

    `ERROR: no uv environment` : lancez `bash setup/setup_uv_env.sh` sur un
    nœud de connexion.

`ACCOUNT=<unset>` et un avertissement : `env.local.sh` est absent ou vide.
Ensuite, `which python` pointe dans votre environnement.

!!! cines "Un environnement ailleurs"
    `env.sh` cherche l'environnement dans `AI_VENV_PATH` (préinstallé) ou
    `AI_UV_VENV_PATH` (uv). Si la variable est déjà définie dans votre shell
    (par exemple dans `~/.bashrc`), c'est cette valeur qui est utilisée. Pour
    garder un environnement existant, définissez-la plutôt dans
    `env.local.sh`. Évitez `$SCRATCHDIR` : les fichiers inutilisés y sont
    purgés après 30 jours.

## Surcharger avec des variables en ligne de commande

Les variables données avant `source env.sh` l'emportent sur `env.local.sh`,
qui l'emporte sur les valeurs par défaut de `env.sh` :

```bash
ACCOUNT=<autre_projet> source env.sh        # un autre projet
HF_HOME=$SHAREDWORKDIR/hf source env.sh     # cache de modèles partagé dans le projet
```

Variables concernées : `ACCOUNT`, `AI_ENV`, `AI_MODULE`, `AI_VENV_PATH`,
`AI_UV_VENV_PATH`, `UV_CACHE_DIR`, `HF_HOME`, `HF_DATASETS_CACHE`,
`HF_TOKEN_PATH`, `DATA_DIR`, `OUTPUT_DIR`.
Une variable déjà définie dans votre shell compte comme une valeur en ligne de
commande : vérifiez les lignes `[env]`. Après avoir modifié `env.local.sh`,
ouvrez un nouveau shell.

!!! cines "Jeton Hugging Face"
    `hf auth login` enregistre votre jeton dans `HF_TOKEN_PATH`
    (`~/.cache/huggingface/token`), pas dans `HF_HOME` : un cache de modèles
    partagé dans le projet ne contient jamais votre jeton. N'écrivez jamais le
    jeton dans `env.local.sh` ni dans un script.