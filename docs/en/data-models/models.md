# Download a model

**Goal:** put a model from the Hugging Face Hub in your cache (`$HF_HOME`), so
that jobs can load it offline.

**Before you start:** a login shell in the repository, after `source env.sh`
(see [Set up your environment](../getting-started/setup.md)).

## Command

On a login node:

```bash
hf download Qwen/Qwen2.5-1.5B
```

Interrupted: run the same command again, it resumes.

Skip the files Transformers does not need (one `--exclude` per pattern):

```bash
hf download Qwen/Qwen2.5-1.5B --exclude "*.bin" --exclude "*.pth" --exclude "original/*"
```

The handbook loads weights with `use_safetensors=True`: PyTorch pickle
weights (`*.bin`, `*.pth`) are not needed when the model also has
`*.safetensors` files, and some models (Llama) ship a second copy of the
weights in `original/`.

A fixed version of the model: `--revision <commit>`.

## What to look at

`hf download` prints the model path
(`path: <WORKDIR>/hf/hub/models--Qwen--Qwen2.5-1.5B/snapshots/<hash>`). It
must start with your `$HF_HOME`.

```bash
hf cache ls                       # models in the cache, with their size
du -sh $HF_HOME/hub/models--*     # size of each model
```

To load it in a job: [Load a model and a dataset in a job](offline.md#in-your-own-job).

| Failure | Cause |
|---|---|
| `hf: command not found` | environment not active: `source env.sh` |
| path under `~/.cache/huggingface` | `env.sh` not sourced: `HF_HOME` is not set; download again after `source env.sh` |
| error about offline mode | command run on a compute node (in a job, or with `srun`), or `HF_HUB_OFFLINE=1` set in your shell: download from a login shell (the `salloc` shell works too) |
| `401` or `403`, `GatedRepoError` | gated model: see below |
| `Disk quota exceeded` | see [Disk space](#disk-space) |

## Gated models

Some models (Llama, Gemma, …) need an access request and a token:

1. On the model page of huggingface.co, accept the license.
2. In your Hugging Face settings, create a token with the *Read* role.
3. On the login node, with the environment active: `hf auth login`, then
   paste the token.

Jobs do not need the token: they read the files already in your cache.

!!! cines "Hugging Face token"
    `hf auth login` stores your token in `HF_TOKEN_PATH`
    (`~/.cache/huggingface/token`), not in `HF_HOME`: a model cache shared in
    the project never contains your token. Never write the token in
    `env.local.sh` or in a script.

## A model from elsewhere

A model that is not on the Hub (your own checkpoint, for example): copy its
directory to `$WORKDIR/models/<name>` (see
[from your computer](datasets.md#from-your-computer)) and load it by path:
`from_pretrained(f"{os.environ['WORKDIR']}/models/<name>")`. Check it with
`check_data.py --model $WORKDIR/models/<name>` (see
[Load a model and a dataset in a job](offline.md#command)).

## Disk space

`$WORKDIR` has a quota per project, in size and in number of files: check it
with `myproject -s <project>` (see [Adastra at a glance](../getting-started/adastra.md#storage)).
Remove a model you no longer use:

```bash
hf cache rm model/Qwen/Qwen2.5-1.5B
```

A download you stopped and will not resume leaves partial files that
`hf cache ls` does not count: `hf cache prune` removes them.

To share one cache within the project, see
[Change a setting](../getting-started/setup.md#change-a-setting)
(`HF_HOME=$SHAREDWORKDIR/hf`).

Ref: [Adastra doc, Software stack, libraries](https://dci.dci-gitlab.cines.fr/webextranet/software_stack/libraries/index.html).