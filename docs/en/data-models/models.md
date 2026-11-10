# Download a model

**Goal:** put a model from the Hugging Face Hub in your cache (`$HF_HOME`), so
that jobs can load it offline.

## Command

On a login node, from the repository root, after `source env.sh`:

```bash
bash setup/download_assets.sh Qwen/Qwen2.5-1.5B
```

Options after the model id go to `hf download`:

```bash
bash setup/download_assets.sh Qwen/Qwen2.5-1.5B --exclude "*.bin"       # skip PyTorch pickle weights
bash setup/download_assets.sh Qwen/Qwen2.5-1.5B --revision <commit>     # a fixed version
```

The handbook loads weights with `use_safetensors=True`: `*.bin` files are not
needed when the model also has `*.safetensors` files.

## What to look at

```bash
hf cache ls                       # models in the cache, with their size
du -sh $HF_HOME/hub/models--*     # size of each model
```

`hf cache ls` is `hf cache scan` with older versions of `huggingface_hub`.

In your code, load the model by its id: it is read from `$HF_HOME`.

```python
model = AutoModelForCausalLM.from_pretrained("Qwen/Qwen2.5-1.5B", use_safetensors=True)
```

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