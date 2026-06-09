# Phi-4 Mini loader, ChatML prompt builder, and safe generation wrapper.

from llama_cpp import Llama
import os
import logging

logger = logging.getLogger("finsight.ai")
MODEL_PATH = os.getenv("MODEL_PATH","../models/Phi-4-mini-instruct-Q4_K_M.gguf")
_llm = None # lazy singleton — model loads only on first request

def get_llm() -> Llama:
    global _llm
    if _llm is None:
        logger.info(f"Loading Phi-4 Mini from {MODEL_PATH} ...")
        _llm = Llama(
            model_path=
            MODEL_PATH,
            # n_ctx=4096: context window. Each token ~4 chars.
            # Reduce to 2048 if your machine has less than 6 GB free RAM.
            n_ctx   = int(os.getenv("N_CTX", "4096")),
            # n_threads: set to your physical CPU core count (NOT hyperthreads).
            # Check with: nproc --all on Linux
            n_threads    = int(os.getenv("N_THREADS", "4")),
            n_batch      = 256,
            n_gpu_layers = 0,      # CPU-only: no GPU required
            f16_kv       = True,   # half-precision KV cache: halves KV memory
            use_mmap     = True,   # memory-map the model file
            use_mlock    = False,  # do NOT lock in RAM on 8 GB machines
            verbose      = False,
        )
        logger.info("Phi-4 Mini ready.")
    return _llm

def build_prompt(system: str, user: str,
                 history: list[dict] | None = None) -> str:
    """
    Build a Phi-4 Mini ChatML prompt.

    Format:
        <|system|>
        {system}<|end|>
        <|user|>
        {turn}<|end|>     <- for each history turn
        <|assistant|>
        {response}<|end|>
        <|user|>
        {user}<|end|>
        <|assistant|>
        <- model generates here
    """
    parts = ["<|system|>\n", system, "<|end|>\n"]
    if history:
        for turn in history:
            tag = "<|user|>" if turn["role"] == "user" else "<|assistant|>"
            parts += [f"{tag}\n", turn["content"], "<|end|>\n"]
    parts += ["<|user|>\n", user, "<|end|>\n", "<|assistant|>\n"]
    return "".join(parts)

def generate(prompt: str, max_tokens: int = 512, temperature: float = 0.2) -> str:
    """Run inference and return stripped output text."""
    result =get_llm()(
        prompt,
        max_tokens      = max_tokens,
        temperature = temperature,
        stop            = ["<|end|>", "<|user|>"],
        echo            =False,
    )
    return result["choices"][0]["text"].strip()

def generate_safe(prompt: str, max_tokens: int = 512, temperature: float = 0.2, retries: int = 2) -> str:
    """
    Retry wrapper: on empty output, bumps temperature slightly and retries.
    Catches MemoryError (context too large) with a helpful message.
    """
    for attempt in range(retries):
        try:
            out = generate(prompt, max_tokens, temperature + attempt * 0.1)
            if out.strip():
                return out
            logger.warning(f"Empty response - attempt {attempt + 1}")
        except MemoryError:
            raise RuntimeError(
                "Out of memory during inference. "
                "Try reducing N_CTX to 2048 in your .env file."
            )
        except Exception as exc: 
            logger.error(f"Inference error attempt {attempt + 1}: {exc}")
            if attempt == retries - 1:
                raise
    return "I could not generate a response. Please rephrase and try again."
