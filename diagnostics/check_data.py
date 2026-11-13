#!/usr/bin/env python3
"""Offline check: load a model and a dataset without internet, sizes and load times.

Usage: sbatch diagnostics/check_data.sh, or in an allocation:
    srun python diagnostics/check_data.py [--model <repo_id>] [--dataset <dir>] [--config <name>]
Same on MI300A and MI250X. Exit code 1 if a check fails.
Ref: https://dci.dci-gitlab.cines.fr/webextranet/data_storage_and_transfers/index.html
"""

import argparse
import os
import sys
import time

import torch

# MI300A: slow bf16 GEMMs with hipBLASLt; TORCH_BLAS_PREFER_HIPBLASLT=0 is not enough.
torch.backends.cuda.preferred_blas_library("cublas")

ENV_VARS = ("HF_HOME", "HF_HUB_OFFLINE", "HF_DATASETS_CACHE", "WORKDIR", "DSDIR")
NOT_CACHED = "not in HF_HOME: hf download <repo_id> on a login node, after source env.sh"
HINTS = {
    "LocalEntryNotFoundError": NOT_CACHED,
    "OfflineModeIsEnabled": NOT_CACHED,
    "FileNotFoundError": "directory or file missing: check the path, or download it first",
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
    parser.add_argument("--model", default="Qwen/Qwen2.5-0.5B", help="Hugging Face model id")
    parser.add_argument(
        "--dataset", help="local dataset directory (default: $WORKDIR/datasets/wikitext)"
    )
    parser.add_argument(
        "--config", default="wikitext-2-raw-v1", help="dataset configuration (default: %(default)s)"
    )
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


def check_model(repo_id):
    from huggingface_hub import snapshot_download
    from transformers import AutoModelForCausalLM, AutoTokenizer

    try:
        path = snapshot_download(repo_id, local_files_only=True)
        size, count = dir_size(path)
        check(True, f"model {repo_id} in cache", f"{path} ({size:.2f} GiB, {count} files)")
        start = time.perf_counter()
        tokenizer = AutoTokenizer.from_pretrained(repo_id)
        # safetensors only: no pickle (arbitrary code) when loading weights.
        model = AutoModelForCausalLM.from_pretrained(
            repo_id, dtype=torch.bfloat16, use_safetensors=True
        )
        n_params = sum(p.numel() for p in model.parameters()) / 1e6
        detail = f"{n_params:.0f}M parameters, {time.perf_counter() - start:.1f} s"
        check(True, "model load (CPU)", detail)
    except Exception as exc:  # report the error as a failed check
        fail(f"model {repo_id}", exc)
        return None
    if torch.cuda.is_available():
        start = time.perf_counter()
        model.to("cuda")
        torch.cuda.synchronize()
        check(True, "model copy to GPU 0", f"{time.perf_counter() - start:.1f} s")
    else:
        print("[WARN] no GPU visible: GPU copy skipped")
    return tokenizer


def check_dataset(path, config, n_samples, tokenizer):
    from datasets import disable_progress_bars, load_dataset

    disable_progress_bars()  # readable logs

    try:
        size, count = dir_size(path)
        if count == 0:
            raise FileNotFoundError(path)
        check(True, "dataset directory", f"{path} ({size:.2f} GiB, {count} files)")
        start = time.perf_counter()
        dataset = load_dataset(path, config, split="train")
        detail = f"{config}, {len(dataset)} rows, {time.perf_counter() - start:.1f} s"
        check(True, "dataset load", detail)
        cache = dataset.cache_files[0]["filename"] if dataset.cache_files else "<in memory>"
        print(f"       Arrow cache: {cache}")
    except Exception as exc:  # report the error as a failed check
        fail("dataset load", exc)
        return
    if tokenizer is None:
        return
    sample = dataset.select(range(min(n_samples, len(dataset))))
    start = time.perf_counter()
    tokens = sample.map(lambda batch: tokenizer(batch["text"]), batched=True)
    n_tokens = sum(len(ids) for ids in tokens["input_ids"])
    detail = f"{len(sample)} samples, {n_tokens} tokens, {time.perf_counter() - start:.1f} s"
    check(True, "tokenization", detail)


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
    dataset = args.dataset or default_dataset()
    tokenizer = check_model(args.model)
    if dataset:
        check_dataset(dataset, args.config, args.samples, tokenizer)
    if failures:
        print(f"{len(failures)} check(s) failed: {', '.join(failures)}")
        sys.exit(1)
    print("All checks passed.")


if __name__ == "__main__":
    main()