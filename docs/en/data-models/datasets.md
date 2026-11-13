# Get a dataset

**Goal:** have a dataset on Adastra in a directory, and load it by its path.

**Before you start:** a login shell in the repository, after `source env.sh`
(see [Set up your environment](../getting-started/setup.md)).

## Public datasets ($DSDIR)

CINES provides public datasets in a common directory, `$DSDIR`. It is
**read-only**: you can use the datasets already there, not add your own.
Look there first: no download, no quota used.

```bash
ls -- "$DSDIR"
```

Load a dataset in place, by its path: no copy to `$WORKDIR`. The Arrow
cache of the first load goes to `$HF_DATASETS_CACHE`, not to `$DSDIR`.

Each dataset keeps the layout of its source: look at its files and its
`README.md` before loading it. `load_dataset(path, data_files="<file>")`
loads one file; check the splits and columns with `print(dataset)`.

A dataset you need is not there: ask svp@cines.fr to add it, or put your own
copy in `$WORKDIR/datasets` ([from the Hub](#from-the-hugging-face-hub) or
[from your computer](#from-your-computer)).

## From the Hugging Face Hub

On a login node (see [Download a model](models.md#command) for the options):

```bash
hf download Salesforce/wikitext --repo-type dataset --local-dir $WORKDIR/datasets/wikitext
```

The dataset is a plain directory, `$WORKDIR/datasets/wikitext`. Load it by its path:

```python
import os
from datasets import load_dataset

path = os.path.join(os.environ["WORKDIR"], "datasets", "wikitext")
dataset = load_dataset(path, "wikitext-2-raw-v1", split="train")
```

The first load writes Arrow files in `$HF_DATASETS_CACHE` (`$SCRATCHDIR`):
purged after 30 days unused, they are rebuilt at the next load.

!!! warning "To adapt"
    - **Very large dataset** (hundreds of GB): a long download on a login node
      may be stopped. Ask svp@cines.fr, who may add it to `$DSDIR`.
    - **Dataset with a loading script only** (`<name>.py`, no data files):
      `datasets` 4 and later no longer run it. Download its Parquet version
      instead, if the Hub has one: `--revision refs/convert/parquet`.

## From your computer

Start the transfer **from your computer** (Adastra cannot connect to it).
On Adastra, `echo $WORKDIR` gives the destination path.

Many small files: pack them first, then unpack them on Adastra. One file
transfers faster, and `$WORKDIR` has a quota in number of files.

=== "Linux, macOS, WSL"

    ```bash
    tar -cf my_dataset.tar my_dataset
    rsync -avP my_dataset.tar <login>@adastra.cines.fr:<WORKDIR>/datasets/
    ```

    `-P` shows the progress and resumes an interrupted transfer: run the same
    command again. A directory without packing:
    `rsync -avP my_dataset/ <login>@adastra.cines.fr:<WORKDIR>/datasets/my_dataset/`.

=== "Windows"

    In PowerShell (`tar` and `scp` come with Windows 10 and 11):

    ```powershell
    tar -cf my_dataset.tar my_dataset
    scp my_dataset.tar <login>@adastra.cines.fr:<WORKDIR>/datasets/
    ```

    `scp` does not resume an interrupted transfer: it starts again from the
    beginning. For a large dataset, use `rsync` in WSL (other tab).

Then, on Adastra:

```bash
tar -xf $WORKDIR/datasets/my_dataset.tar -C $WORKDIR/datasets/
rm $WORKDIR/datasets/my_dataset.tar
```

A directory of CSV, JSON or Parquet files loads by its path too:
`load_dataset(f"{os.environ['WORKDIR']}/datasets/my_dataset", split="train")`.

## What to look at

```bash
ls $WORKDIR/datasets
du -sh $WORKDIR/datasets/*               # size of each dataset
du -s --inodes $WORKDIR/datasets/*       # number of files of each dataset
```

| Failure | Cause |
|---|---|
| `hf: command not found` | environment not active: `source env.sh` |
| `Disk quota exceeded`, under `~/.cache/huggingface/datasets` | `env.sh` not sourced where the dataset is loaded: `HF_DATASETS_CACHE` is not set, the Arrow cache goes to your small home directory |

Ref: [Adastra doc, Data storage and transfers](https://dci.dci-gitlab.cines.fr/webextranet/data_storage_and_transfers/index.html).