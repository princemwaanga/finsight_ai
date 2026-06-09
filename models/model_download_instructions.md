# Instructions: Downloading and Running Phi-4-mini-instruct-Q4_K_M

This file contains instructions to quickly download and execute the quantized **Phi-4-mini-instruct-Q4_K_M** GGUF model (3.8 Billion parameters) locally on your hardware.

---

## Method 1: The Quickest Way (Using Ollama)

[Ollama](https://ollama.com/) automates the download, caching, and serving of the `Q4_K_M` quantization profile directly through your command line.

### 1. Install Ollama
* **macOS / Linux:** Run `curl -fsSL https://ollama.com | sh`
* **Windows:** Download the installer from the [Official Ollama Website](https://ollama.com/).

### 2. Download and Run the Model
Execute the following command in your terminal. Ollama will automatically fetch the ~2.5GB 4-bit medium quantized weights (`q4_K_M`):

```bash
ollama run phi4-mini:3.8b-q4_K_M
```

---

## Method 2: Manual Download (Using huggingface-cli)

If you intend to use custom engines like `llama.cpp`, `LM Studio`, or `Text-Generation-WebUI`, you can download the exact file directly from Hugging Face repositories.

### 1. Install Hugging Face Hub CLI
Ensure you have Python installed, then run:
```bash
pip install huggingface_hub
```

### 2. Download the Specific GGUF File
Use the CLI to pull only the specific `Q4_K_M` file rather than downloading the entire repository branch:
```bash
huggingface-cli download mmnga/Phi-4-mini-instruct-gguf Phi-4-mini-instruct-Q4_K_M.gguf --local-dir . --local-dir-use-symlinks False
```

---

## Method 3: Automated Python Script

Create a script named `download_phi.py` and paste the following Python code to automate the download using the Hugging Face API:

```python
import os
from huggingface_hub import hf_hub_download

# Configuration
REPO_ID = "mmnga/Phi-4-mini-instruct-gguf"
FILENAME = "Phi-4-mini-instruct-Q4_K_M.gguf"
SAVE_DIRECTORY = "./models"

print(f"Starting download for {FILENAME}...")

try:
    os.makedirs(SAVE_DIRECTORY, exist_ok=True)
    
    # Download specific file
    model_path = hf_hub_download(
        repo_id=REPO_ID,
        filename=FILENAME,
        local_dir=SAVE_DIRECTORY,
        local_dir_use_symlinks=False
    )
    
    print("\n[SUCCESS] Download completed!")
    print(f"Model file saved at: {os.path.abspath(model_path)}")

except Exception as e:
    print(f"\n[ERROR] Download failed: {e}")
```

### Run the Script
```bash
python download_phi.py
```

---

## How to Test the Downloaded File

Once you have downloaded the `.gguf` file manually (via Method 2 or 3), you can quickly spin up an OpenAI-compatible API server using [llama.cpp](https://github.com/ggerganov/llama.cpp):

```bash
# Install llama.cpp via homebrew (macOS/Linux) or WinGet (Windows)
brew install llama.cpp

# Run the local server pointing to your downloaded file
llama-server --model ./models/Phi-4-mini-instruct-Q4_K_M.gguf -c 4096
```