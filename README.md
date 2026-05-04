# 🚀 One-Click DeepSeek Reverse API

[![Platform: Windows](https://img.shields.io/badge/Platform-Windows-blue.svg)](https://github.com/chirag-gamer/one-click-deepseek-reverse)
[![Platform: macOS](https://img.shields.io/badge/Platform-macOS-silver.svg)](https://github.com/chirag-gamer/one-click-deepseek-reverse)
[![Platform: Linux](https://img.shields.io/badge/Platform-Linux-orange.svg)](https://github.com/chirag-gamer/one-click-deepseek-reverse)
[![Python 3.8+](https://img.shields.io/badge/Python-3.8+-green.svg)](https://python.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**One script. Zero hassle.** Get a local OpenAI-compatible API for DeepSeek AI running in minutes — on Windows, macOS, or Linux. No manual config, no Python headaches, no token hunting in browser devtools.

> 🔧 **Powered by:** [Wu-jiyan/deepseek-reverse-api](https://github.com/Wu-jiyan/deepseek-reverse-api) — the underlying reverse-engineered DeepSeek API server.

---

## 📋 Table of Contents

- [What This Does](#-what-this-does)
- [Quick Start](#-quick-start)
- [Platform-Specific Instructions](#-platform-specific-instructions)
  - [Windows](#windows)
  - [macOS](#macos)
  - [Linux](#linux)
- [What the Scripts Do](#-what-the-scripts-do)
- [After Installation](#-after-installation)
- [API Usage Examples](#-api-usage-examples)
- [Environment Variables](#-environment-variables)
- [Supported Models](#-supported-models)
- [Multiple Accounts](#-multiple-accounts)
- [Troubleshooting](#-troubleshooting)
- [Architecture](#-architecture)
- [Security](#-security)
- [Credits & License](#-credits--license)

---

## 🎯 What This Does

| Without this tool | With this tool |
|---|---|
| Manually install Python | ✅ Script auto-detects & installs |
| Manually clone the repo | ✅ Script clones/downloads repo |
| Manually `pip install` deps | ✅ Script installs everything |
| Hunt for token in browser DevTools | ✅ Script logs in with email/password |
| Manually write `.env` file | ✅ Script auto-generates config |
| Manually start server | ✅ Script launches server immediately |
| One account at a time | ✅ Unlimited multi-account support |

**Result:** A running server at `http://localhost:8000` that speaks the OpenAI API protocol.

---

## ⚡ Quick Start

### Windows
```batch
REM 1. Download or clone this repo
REM 2. Right-click install.bat → "Run as Administrator"
REM 3. Follow the prompts
```

### macOS / Linux
```bash
# 1. Download or clone this repo
git clone https://github.com/chirag-gamer/one-click-deepseek-reverse.git
cd one-click-deepseek-reverse

# 2. Make the script executable
chmod +x install.sh

# 3. Run it
./install.sh
```

**That's it.** The script handles everything — Python, dependencies, login, config, and launch.

---

## 🖥️ Platform-Specific Instructions

### Windows

| Requirement | How It's Handled |
|---|---|
| Python 3.8+ | Installed via `winget` if missing; manual fallback guided |
| Git | Not required (PowerShell zip download fallback) |
| Admin rights | Warned about; needed only for Python install |

**Run:**
```batch
install.bat
```
> 💡 If Python auto-install fails, the script gives you a direct link to python.org with clear instructions.

### macOS

| Requirement | How It's Handled |
|---|---|
| Python 3.8+ | Installed via `brew` (auto-installs brew if missing) |
| Homebrew | Auto-installed if not present |
| Virtual Env | Creates `.venv` for clean isolation |

**Run:**
```bash
chmod +x install.sh
./install.sh
```

> 💡 Use `./install.sh --no-start` to configure without launching the server.

### Linux

| Distribution | Package Manager | Status |
|---|---|---|
| Ubuntu / Debian | `apt-get` | ✅ Supported |
| Fedora / RHEL | `dnf` | ✅ Supported |
| Arch Linux | `pacman` | ✅ Supported |
| openSUSE | `zypper` | ✅ Supported |
| Alpine | `apk` | ✅ Supported |

**Run:**
```bash
chmod +x install.sh
./install.sh
```

> 💡 The script auto-detects your distro and uses the correct package manager.

---

## 🔧 What the Scripts Do

Both scripts follow the same 5-step pipeline:

```
STEP 1: Python Check & Install
  - Detects existing Python 3.8+
  - Installs via package manager if missing
  - Verifies pip is available

STEP 2: Repository Setup
  - Clones deepseek-reverse-api via git
  - Falls back to curl/wget if git unavailable

STEP 3: Dependency Installation
  - Creates Python virtual environment (Unix)
  - pip install -r requirements.txt

STEP 4: Account Configuration
  - Prompts for email + password (masked)
  - Logs into DeepSeek API, fetches token
  - Supports multiple accounts (round-robin)
  - Auto-generates .env file

STEP 5: Server Launch
  - Starts server on http://localhost:8000
  - Displays health & API endpoints
```

---

## 🏃 After Installation

Once the server is running:

| Endpoint | URL |
|---|---|
| **Health Check** | `http://localhost:8000/health` |
| **Chat Completions** | `http://localhost:8000/v1/chat/completions` |
| **List Models** | `http://localhost:8000/v1/models` |
| **Proxy Stats** | `http://localhost:8000/v1/proxy/stats` |

### Restarting the Server

**Windows:** Re-run `install.bat` (it skips already-installed steps)

**macOS/Linux:**
```bash
./start.sh
```

---

## 📡 API Usage Examples

### cURL

```bash
curl -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "deepseek-v4-flash",
    "messages": [{"role": "user", "content": "Hello, how are you?"}]
  }'
```

> **Note:** No `Authorization` header needed — your tokens are already configured in `.env`.

### Python

```python
import requests

response = requests.post(
    "http://localhost:8000/v1/chat/completions",
    json={
        "model": "deepseek-v4-flash",
        "messages": [{"role": "user", "content": "Explain quantum computing"}]
    }
)
print(response.json()["choices"][0]["message"]["content"])
```

### OpenAI SDK (Drop-in Replacement)

```python
from openai import OpenAI

client = OpenAI(
    base_url="http://localhost:8000/v1",
    api_key="any-value"  # Not used — tokens are in .env
)

response = client.chat.completions.create(
    model="deepseek-v4-flash",
    messages=[{"role": "user", "content": "Hello!"}]
)
print(response.choices[0].message.content)
```

### Streaming

```python
response = client.chat.completions.create(
    model="deepseek-v4-pro-think",
    messages=[{"role": "user", "content": "Solve: x² + 5x + 6 = 0"}],
    stream=True
)
for chunk in response:
    if chunk.choices[0].delta.content:
        print(chunk.choices[0].delta.content, end="")
```

---

## ⚙️ Environment Variables

The script auto-generates `.env` inside `deepseek-reverse-api/`. You can edit it manually:

```env
# Your tokens (comma-separated for multiple accounts)
DEEPSEEK_TOKENS=token1,token2,token3

# Server settings
PORT=8000
HOST=0.0.0.0

# Auto-delete chat sessions after completion
AUTO_DELETE_SESSION=false

# Token selection: round_robin, random, least_used
TOKEN_STRATEGY=round_robin

# Logging level
LOG_LEVEL=INFO

# Optional: HTTP proxy
# HTTP_PROXY=http://proxy.example.com:8080
# HTTPS_PROXY=http://proxy.example.com:8080
```

---

## 🎯 Supported Models

| Model | Type | Thinking | Speed |
|---|---|---|---|
| `deepseek-v4-flash` | Default | No | ⚡ Fast |
| `deepseek-v4-flash-think` | Default | Yes | Normal |
| `deepseek-v4-flash-fast` | Default | No | ⚡⚡ Fastest |
| `deepseek-v4-pro` | Expert | Yes | Normal |
| `deepseek-v4-pro-think` | Expert | Yes | Normal |
| `deepseek-v4-pro-fast` | Expert | No | ⚡ Fast |

**Model suffix meaning:**
- `-think` → Enables reasoning/thinking (shows thought process)
- `-fast` → Disables thinking for faster responses
- No suffix → Auto-selects based on model type

---

## 👥 Multiple Accounts

The scripts natively support multiple DeepSeek accounts. Benefits:

- **Higher Rate Limits** — bypass per-account throttling
- **Load Balancing** — round-robin token selection
- **Failover** — if one account has issues, others keep working

Just answer `y` when asked *"Add another DeepSeek account?"* during setup. All tokens are comma-joined in `DEEPSEEK_TOKENS`.

---

## 🔧 Troubleshooting

| Problem | Solution |
|---|---|
| **Python not found after install** | Restart terminal or re-login (PATH refresh) |
| **`pip install` fails** | Try: `python -m pip install --upgrade pip` |
| **Login fails** | Check email/password at [chat.deepseek.com](https://chat.deepseek.com) |
| **`wasmtime` install fails** | Windows: requires Visual C++ Redistributable |
| **Port 8000 already in use** | Edit `.env` → change `PORT=8001` → restart |
| **Permission denied (Unix)** | Run: `chmod +x install.sh && ./install.sh` |
| **Brew not found (macOS)** | Install manually via Homebrew website |

### Getting a DeepSeek Account

If you don't have a DeepSeek account:
1. Go to [chat.deepseek.com](https://chat.deepseek.com)
2. Click "Sign Up" and register with your email
3. Use that email and password in the installer

---

## 📁 Architecture

```
one-click-deepseek-reverse/
├── install.bat              # Windows one-click installer
├── install.sh               # macOS/Linux one-click installer
├── start.sh                 # macOS/Linux server launcher (auto-generated)
├── README.md                # This file
├── LICENSE                  # MIT License
└── deepseek-reverse-api/    # Cloned during installation
    ├── server.py            # Main Flask API server
    ├── start_server.py      # Uvicorn entry point
    ├── requirements.txt     # Python dependencies
    ├── .env                 # Your tokens & config (generated)
    └── deepseek_ai/         # Core SDK
        ├── account_register.py  # Email/password → token
        ├── client.py            # OpenAI-compatible client
        ├── adapter.py           # API request adapter
        ├── stream_handler.py    # SSE streaming
        ├── pow_solver.py        # Proof-of-Work (WASM)
        ├── proxy_adapter.py     # Vless/HTTP proxy support
        ├── subscription.py      # Subscription manager
        ├── node_storage.py      # Node persistence
        ├── node_tester.py       # Node health checks
        ├── vless_proxy.py       # Vless protocol
        └── tool_parser.py       # Function calling parser
```

---

## 🔒 Security

- **Passwords are never stored.** They're used once to obtain a token, then discarded.
- **Tokens are stored locally** in `.env` inside the `deepseek-reverse-api/` directory.
- **Add `.env` to `.gitignore`** if you're forking the repo — it's auto-ignored by the original repo's gitignore.
- The script uses **masked password input** (PowerShell `Read-Host -AsSecureString` on Windows, `stty -echo` on Unix).
- No data is sent anywhere except DeepSeek's official API at `chat.deepseek.com`.

---

## 🙏 Credits & License

- **Original Reverse API:** [Wu-jiyan/deepseek-reverse-api](https://github.com/Wu-jiyan/deepseek-reverse-api) — the core server and SDK
- **One-Click Installer:** This project — install scripts and documentation

**License:** [MIT License](LICENSE)

---

<div align="center">

**⭐ Don't forget to star the repo if this helped you! ⭐**

[Report a Bug](https://github.com/chirag-gamer/one-click-deepseek-reverse/issues) · [Request a Feature](https://github.com/chirag-gamer/one-click-deepseek-reverse/issues)

</div>
