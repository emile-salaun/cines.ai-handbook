#!/usr/bin/env python3
"""Offline check: load a model and a dataset without internet, with their paths and sizes.

Usage: sbatch diagnostics/check_data.sh, or in an allocation:
    srun python diagnostics/check_data.py [--model <repo_id or dir>] [--dataset <dir>]
        [--config <name>] [--split <name>] [--column <name>]
Same on MI300A and MI250X. Exit code 1 if a check fails.
Ref: https://dci.dci-gitlab.cines.fr/webextranet/data_storage_and_transfers/index.html
"""

import argparse
import os
import sys

import torch

# MI300A: slow bf16 GEMMs with hipBLASLt; TORCH_BLAS_PREFER_HIPBLASLT=0 is not enough.
torch.backends.cuda.preferred_blas_library("cublas")

ENV_VARS = ("HF_HOME", "HF_HUB_OFFLINE", "HF_DATASETS_CACHE", "WORKDIR", "DSDIR")
NOT_CACHED = "not in HF_HOME: hf download <repo_id> on a login node, after source env.sh"
HINTS = {
    "LocalEntryNotFoundError": NOT_CACHED,
    "OfflineModeIsEnabled": NOT_CACHED,
    "FileNotFoundError": "directory or file missing: check the path, or download it first",
    "HFValidationError": "neither a Hugging Face id nor an existing directory: check --model",
}
failures = []


def check(ok, label, detail=""):
    print(f"[{'OK' if ok else 'FAIL'}] {label}" + (f": {detail}" if detail else ""), flush=True)
    if not ok:
        failures.append(label)
    return ok


def fail(label, exc):
    hint = HINTS.get(type(exc).__name__, "")
    check(False, label, f"{type(exc).__name__}: {exc}" + (f"\n       -> {hint}" if hint else ""))


def parse_args():
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument(
        "--model",
        default="Qwen/Qwen2.5-0.5B",
        help="Hugging Face model id, or a local model directory (default: %(default)s)",
    )
    parser.add_argument(
        "--dataset", help="local dataset directory (default: $WORKDIR/datasets/wikitext)"
    )
    parser.add_argument(
        "--config",
        help="dataset configuration (default: wikitext-2-raw-v1 for the default dataset, none otherwise)",
    )
    parser.add_argument("--split", default="train", help="dataset split (default: %(default)s)")
    parser.add_argument("--column", default="text", help="text column to tokenize (default: %(default)s)")
    parser.add_argument("--samples", type=int, default=1000, help="samples to tokenize")
    return parser.parse_args()


def dir_size(path):
    """Size and number of files under path (symbolic links followed: HF cache)."""
    total, count = 0, 0
    for root, _, files in os.walk(path):
        for name in files:
            total += os.path.getsize(os.path.join(root, name))
            count += 1
    return total / 2**30, count


def check_model(model_id):
    """model_id: a Hugging Face id (read from HF_HOME) or a local directory."""
    from huggingface_hub import snapshot_download
    from transformers import AutoModelForCausalLM, AutoTokenizer
    from transformers.utils import logging as hf_logging

    hf_logging.disable_progress_bar()  # keep the log readable

    try:
        if os.path.isdir(model_id):
            path, label = model_id, "model directory"
        else:
            path, label = snapshot_download(model_id, local_files_only=True), f"model {model_id} in cache"
        size, count = dir_size(path)
        check(True, label, f"{path} ({size:.2f} GiB, {count} files)")
        tokenizer = AutoTokenizer.from_pretrained(path)
        # safetensors only: no pickle (arbitrary code) when loading weights.
        model = AutoModelForCausalLM.from_pretrained(
            path, dtype=torch.bfloat16, use_safetensors=True
        )
        n_params = sum(p.numel() for p in model.parameters()) / 1e6
        check(True, "model load (CPU)", f"{n_params:.0f}M parameters")
    except Exception as exc:  # report the error as a failed check
        fail(f"model {model_id}", exc)
        return None
    if torch.cuda.is_available():
        try:
            model.to("cuda")
            torch.cuda.synchronize()
            check(True, "model copy to GPU 0")
        except Exception as exc:  # out of memory, no usable GPU
            fail("model copy to GPU 0", exc)
    else:
        print("[WARN] no GPU visible: GPU copy skipped")
    return tokenizer


def check_dataset(path, config, split, column, n_samples, tokenizer):
    from datasets import disable_progress_bars, load_dataset

    disable_progress_bars()  # readable logs

    try:
        size, count = dir_size(path)
        if count == 0:
            raise FileNotFoundError(path)
        check(True, "dataset directory", f"{path} ({size:.2f} GiB, {count} files)")
        dataset = load_dataset(path, config, split=split)
        detail = f"{config or 'default'}, split {split}, {len(dataset)} rows"
        check(True, "dataset load", detail)
        cache = dataset.cache_files[0]["filename"] if dataset.cache_files else "<in memory>"
        print(f"       Arrow cache: {cache}")
    except Exception as exc:  # report the error as a failed check
        fail("dataset load", exc)
        return
    if tokenizer is None:
        return
    if column not in dataset.column_names:
        columns = ", ".join(dataset.column_names)
        print(f"[WARN] no column '{column}' (columns: {columns}): tokenization skipped (--column <name>)")
        return
    try:
        sample = dataset.select(range(min(n_samples, len(dataset))))
        tokens = sample.map(lambda batch: tokenizer(batch[column]), batched=True)
        n_tokens = sum(len(ids) for ids in tokens["input_ids"])
        check(True, "tokenization", f"{len(sample)} samples, {n_tokens} tokens")
    except Exception as exc:  # report the error as a failed check
        fail("tokenization", exc)


def default_dataset():
    """$WORKDIR/datasets/wikitext, or None (with a [FAIL] line) without WORKDIR."""
    workdir = os.environ.get("WORKDIR")
    if workdir:
        return os.path.join(workdir, "datasets", "wikitext")
    check(False, "dataset path", "WORKDIR is not set (not on Adastra?): give --dataset <dir>")
    return None


def main():
    args = parse_args()
    for var in ENV_VARS:
        print(f"  {var}={os.environ.get(var, '<unset>')}")
    check(os.environ.get("HF_HUB_OFFLINE") == "1", "HF_HUB_OFFLINE=1")
    dataset, config = args.dataset, args.config
    if dataset is None:  # handbook example dataset
        dataset, config = default_dataset(), config or "wikitext-2-raw-v1"
    tokenizer = check_model(args.model)
    if dataset:
        check_dataset(dataset, config, args.split, args.column, args.samples, tokenizer)
    if failures:
        print(f"{len(failures)} check(s) failed: {', '.join(failures)}")
        sys.exit(1)
    print("All checks passed.")


if __name__ == "__main__":
    main()