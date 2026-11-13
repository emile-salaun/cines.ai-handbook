#!/usr/bin/env python3
"""Batch text generation with Transformers on one GPU (single process).

Loads an instruct model offline from HF_HOME, generates answers to a set of
prompts in batches (greedy decoding), and prints the load time, the generation
time and the throughput in generated tokens per second. The answers are
written to a JSON Lines file. Download the model first on a login node with
setup/download_assets.sh.

MI300A and MI250X: same script; one APU or one GCD. On MI250X, a GCD has
64 GB of memory: models above ~30B parameters (bf16) do not fit.

Usage (from the repository root):
    sbatch inference/generate_hf.sh              # batch job, handbook defaults
    srun python inference/generate_hf.py [--model <repo_id>] [--prompts <n>]
        [--batch-size <n>] [--max-new-tokens <n>] [--output <file>]
Ref: Transformers, Generation:
    https://huggingface.co/docs/transformers/main_classes/text_generation
"""

import argparse
import json
import os
import sys
import time

import torch

# MI300A: slow bf16 GEMMs with hipBLASLt; TORCH_BLAS_PREFER_HIPBLASLT=0 is not enough.
torch.backends.cuda.preferred_blas_library("cublas")

from transformers import AutoModelForCausalLM, AutoTokenizer  # noqa: E402

PROMPTS = (
    "Explain what a GPU is in two sentences.",
    "Write a haiku about supercomputers.",
    "Give three tips to write clean Python code.",
    "What is the difference between a process and a thread?",
    "Summarize the water cycle for a ten-year-old.",
    "Translate 'The job finished successfully' into French.",
    "List four uses of large language models in science.",
    "Why does training a neural network need a lot of memory?",
)


def parse_args():
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    add = parser.add_argument
    add("--model", default="Qwen/Qwen2.5-0.5B-Instruct", help="Hugging Face model id")
    add("--prompts", type=int, default=64, help="number of prompts (%(default)s)")
    add("--batch-size", type=int, default=16, help="prompts per batch (%(default)s)")
    add("--max-new-tokens", type=int, default=128, help="(%(default)s)")
    add("--output", help="JSON Lines file (default: $OUTPUT_DIR/generate_hf/<job id>.jsonl)")
    return parser.parse_args()


def output_path(path):
    if path:
        return path
    job = os.environ.get("SLURM_JOB_ID", "local")
    return os.path.join(os.environ.get("OUTPUT_DIR", "."), "generate_hf", f"{job}.jsonl")


def build_inputs(tokenizer, prompts):
    """Prompts in the chat format of the model, if it has one."""
    if tokenizer.chat_template is None:
        return list(prompts)
    return [
        tokenizer.apply_chat_template(
            [{"role": "user", "content": p}], tokenize=False, add_generation_prompt=True
        )
        for p in prompts
    ]


def generated_lengths(new_tokens, eos_ids):
    """Generated tokens per sequence, up to and including the first end token."""
    lengths = []
    for row in new_tokens.tolist():
        ends = [i for i, tok in enumerate(row) if tok in eos_ids]
        lengths.append(ends[0] + 1 if ends else len(row))
    return lengths


def main():
    args = parse_args()
    if not torch.cuda.is_available():
        print("[WARN] no GPU visible: running on CPU")
    device = "cuda" if torch.cuda.is_available() else "cpu"
    print(f"model={args.model} prompts={args.prompts} batch_size={args.batch_size} "
          f"max_new_tokens={args.max_new_tokens} device={device}", flush=True)

    start = time.perf_counter()
    # Left padding: generation continues each prompt from its last token.
    tokenizer = AutoTokenizer.from_pretrained(args.model, padding_side="left")
    if tokenizer.pad_token is None:
        tokenizer.pad_token = tokenizer.eos_token
    # safetensors only: no pickle (arbitrary code) when loading weights.
    model = AutoModelForCausalLM.from_pretrained(
        args.model, dtype=torch.bfloat16, use_safetensors=True
    ).to(device)
    model.eval()
    eos = model.generation_config.eos_token_id
    eos_ids = set(eos if isinstance(eos, list) else [eos])
    print(f"load: {time.perf_counter() - start:.1f} s", flush=True)

    prompts = [PROMPTS[i % len(PROMPTS)] for i in range(args.prompts)]
    texts = build_inputs(tokenizer, prompts)
    batches = [texts[i:i + args.batch_size] for i in range(0, len(texts), args.batch_size)]

    def generate(batch):
        inputs = tokenizer(batch, return_tensors="pt", padding=True).to(device)
        with torch.inference_mode():
            out = model.generate(
                **inputs,
                max_new_tokens=args.max_new_tokens,
                do_sample=False,  # greedy: same answers at every run
                pad_token_id=tokenizer.pad_token_id,
            )
        return out[:, inputs["input_ids"].shape[1]:]

    generate(batches[0][:1])  # warm-up (GPU kernels, caches): not timed
    if device == "cuda":
        torch.cuda.synchronize()

    answers, n_tokens = [], 0
    start = time.perf_counter()
    for batch in batches:
        new_tokens = generate(batch)
        lengths = generated_lengths(new_tokens, eos_ids)
        n_tokens += sum(lengths)
        for row, length in zip(new_tokens, lengths):
            answers.append(tokenizer.decode(row[:length], skip_special_tokens=True))
    if device == "cuda":
        torch.cuda.synchronize()
    elapsed = time.perf_counter() - start

    path = output_path(args.output)
    os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
    with open(path, "w") as f:
        for prompt, answer in zip(prompts, answers):
            f.write(json.dumps({"prompt": prompt, "answer": answer}) + "\n")

    print(f"example: {prompts[0]!r} -> {answers[0][:200]!r}")
    print(f"generation: {len(prompts)} prompts, {n_tokens} tokens, {elapsed:.1f} s")
    print(f"throughput: {n_tokens / elapsed:.0f} tokens/s, {len(prompts) / elapsed:.2f} prompts/s")
    print(f"answers: {path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())