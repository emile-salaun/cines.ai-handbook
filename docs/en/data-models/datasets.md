# Get a dataset

**Goal:** have a dataset on Adastra in a directory, and load it by its path.

## Public datasets ($DSDIR)

CINES provides public datasets in a common directory, `$DSDIR`. It is
**read-only**: you can use the datasets already there, not add your own.
Look there first: no download, no quota used.

```bash
ls -- "$DSDIR"
```

Load a dataset in place, by its path: no copy to `$DATA_DIR`. The Arrow
cache of the first load goes to `$HF_DATASETS_CACHE`, not to `$DSDIR`.

A dataset you need is not there: ask svp@cines.fr to add it, or put your own
copy in `$DATA_DIR` ([from the Hub](#from-the-hugging-face-hub) or
[from your computer](#from-your-computer)).

Ref: [Adastra doc, Data storage and transfers](https://dci.dci-gitlab.cines.fr/webextranet/data_storage_and_transfers/index.html).

## From the Hugging Face Hub

On a login node, after `source env.sh` (same rules as for
[a model](models.md#command)):

```bash
hf download Salesforce/wikitext --repo-type dataset --local-dir $DATA_DIR/wikitext
```

The dataset is a plain directory in `$DATA_DIR`. Load it by its path:

```python
import os
from datasets import load_dataset

path = os.path.join(os.environ["DATA_DIR"], "wikitext")
dataset = load_dataset(path, "wikitext-2-raw-v1", split="train")
```

The first load writes Arrow files in `$HF_DATASETS_CACHE` (`$SCRATCHDIR`):
purged after 30 days unused, they are rebuilt at the next load.

## From your computer

Start the transfer **from your computer** (Adastra cannot connect to it).
On Adastra, `echo $WORKDIR` gives the destination path.

```bash
rsync -avP my_dataset/ <login>@adastra.cines.fr:<WORKDIR>/handbook/datasets/my_dataset/
```

`-P` shows the progress and resumes an interrupted transfer: run the same
command again.

Many small files: pack them first (`tar -cf my_dataset.tar my_dataset`).
One file transfers faster, and `$WORKDIR` allows 250,000 files per project.

Ref: [Adastra doc, Data storage and transfers](https://dci.dci-gitlab.cines.fr/webextranet/data_storage_and_transfers/index.html).

## What to look at

```bash
ls $DATA_DIR
du -sh $DATA_DIR/*               # size of each dataset
du -s --inodes $DATA_DIR/*       # number of files of each dataset
```