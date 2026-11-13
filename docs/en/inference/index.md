# Inference

Batch generation with Transformers, LLM batch inference and serving with vLLM
on a whole node, and image generation with Diffusers.

## Requirements

=== "Prebuilt"

    To be documented: packages missing from the prebuilt environment.

=== "uv"

    On a login node, from the repository root:

    ```bash
    module load python
    uv sync --locked --group inference
    ```

## Steps

<div class="cines-steps" markdown>

1. [Batch generation with Transformers](transformers.md): one GPU, any model
   of the Hub, throughput.

</div>

!!! cines "In progress"
    vLLM (batch inference and serving, whole node) and Diffusers are being
    written.