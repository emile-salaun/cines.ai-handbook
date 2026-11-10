# Training & fine-tuning

Train and fine-tune on 1 GPU and 1 node: DDP, LoRA/PEFT, FSDP, DeepSpeed, Accelerate, bf16 mixed precision.

## Requirements

=== "Prebuilt"

    To be documented: packages missing from the prebuilt environment.

=== "uv"

    On a login node, from the repository root:

    ```bash
    module load python
    uv sync --locked --group training
    ```

!!! cines "Planned"
    This chapter is not written yet. See the [plan](https://github.com/emile-salaun/cines.ai-handbook#status).