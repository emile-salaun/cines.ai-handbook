# Download a model

**Goal:** put a model from the Hugging Face Hub in your cache (`$HF_HOME`), so
that jobs can load it offline.

**Before you start:** a login shell in the repository, after `source env.sh`
(see [Set up your environment](../getting-started/setup.md)).

## Command

On a login node, from the repository root, after `source env.sh` (it sets
`HF_HOME` and activates the environment that provides `hf`):

```bash
hf download Qwen/Qwen2.5-1.5B
```

Useful options:

```bash
hf download Qwen/Qwen2.5-1.5B --exclude "*.bin"       # skip PyTorch pickle weights
hf download Qwen/Qwen2.5-1.5B --revision <commit>     # a fixed version
```

The handbook loads weights with `use_safetensors=True`: `*.bin` files are not
needed when the model also has `*.safetensors` files.

## What to look at

The last line printed by `hf download` is the model path. It must start with
your `$HF_HOME` (`<WORKDIR>/hf/hub/models--Qwen--Qwen2.5-1.5B/snapshots/<hash>`).

```bash
hf cache ls                       # models in the cache, with their size
du -sh $HF_HOME/hub/models--*     # size of each model
```

`hf cache ls` is `hf cache scan` with older versions of `huggingface_hub`.

In your code, load the model by its id: it is read from `$HF_HOME`.

```python
model = AutoModelForCausalLM.from_pretrained("Qwen/Qwen2.5-1.5B", use_safetensors=True)
```

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

The token is stored in `HF_TOKEN_PATH`, outside `$HF_HOME`: see
[Hugging Face token](../getting-started/setup.md#override-with-command-line-variables).

## A model from elsewhere

A model that is not on the Hub (your own checkpoint, for example): copy its
directory to `$WORKDIR/models/<name>` (see
[from your computer](datasets.md#from-your-computer)) and load it by path:
`from_pretrained(f"{os.environ['WORKDIR']}/models/<name>")`.

## Disk space

`$WORKDIR` has a quota per project (15 TiB, 250,000 files): check it with
`myproject -s <project>`. Remove a model you no longer use:

```bash
hf cache rm model/Qwen/Qwen2.5-1.5B
```

To share one cache within the project, see
[Override with command-line variables](../getting-started/setup.md#override-with-command-line-variables)
(`HF_HOME=$SHAREDWORKDIR/hf`).

## The handbook examples

`bash setup/download_assets.sh` downloads the models and the dataset of the
handbook examples (see [Set up your environment](../getting-started/setup.md)).
It prints each `hf download` command before running it.