# Installation

**Objectif :** un shell de connexion où `sbatch` utilise votre projet et où
Python est l'environnement IA préinstallé. À faire une fois ; ensuite une
commande par session.

## Une fois

Sur un nœud de connexion :

```bash
cd $HOMEDIR
git clone https://github.com/emile-salaun/cines.ai-handbook.git
cd cines.ai-handbook
echo 'HANDBOOK_ACCOUNT=<project>' > env.local.sh   # (1)!
source env.sh                                      # (2)!
bash setup/download_assets.sh                      # (3)!
```

1. Votre projet Slurm (`myproject -l` les liste). `env.local.sh` est ignoré
   par git.
2. La première fois, charge les modules IA et crée votre environnement dans
   `$WORKDIR/envs/`. Compter quelques minutes.
3. Télécharge le modèle de test (`Qwen/Qwen2.5-0.5B`, environ 1 Go) dans
   `$WORKDIR/hf`.

## À chaque session

```bash
cd $HOMEDIR/cines.ai-handbook
source env.sh
```

## Ce qu'il faut regarder

```text
[env] HANDBOOK_ACCOUNT=<project>
[env] AI environment: <WORKDIR>/envs/venv-0.8.0-torch2.11.0-rocm7.2.0
[env] HF_HOME=<WORKDIR>/hf
```

- `HANDBOOK_ACCOUNT=<unset>` et un avertissement : `env.local.sh` est absent
  ou vide.
- `ERROR: no AI environment` : lisez les messages des modules juste au-dessus.

Ensuite, `which python` pointe dans l'environnement IA.

!!! cines "Un environnement ailleurs"
    `env.sh` cherche l'environnement dans `AI_VENV_PATH`. Si cette variable
    est déjà définie dans votre shell (par exemple dans `~/.bashrc`), c'est
    cette valeur qui est utilisée. Pour garder un environnement existant,
    définissez-la plutôt dans `env.local.sh` : `AI_VENV_PATH=<chemin>`.
    Évitez `$SCRATCHDIR` : les fichiers inutilisés y sont purgés après 30 jours.

## Surcharger avec des variables en ligne de commande

Les variables données avant `source env.sh` l'emportent sur `env.local.sh`,
qui l'emporte sur les valeurs par défaut de `env.sh` :

```bash
HANDBOOK_ACCOUNT=<autre_projet> source env.sh   # un autre projet
HF_HOME=$SHAREDWORKDIR/hf source env.sh         # cache de modèles partagé dans le projet
```

Variables concernées : `HANDBOOK_ACCOUNT`, `AI_MODULE`, `AI_VENV_PATH`,
`HF_HOME`, `HF_DATASETS_CACHE`, `HANDBOOK_DATA`, `HANDBOOK_OUTPUT`.
Après avoir modifié `env.local.sh`, ouvrez un nouveau shell : les valeurs déjà
définies dans le shell courant comptent comme des valeurs en ligne de commande.
