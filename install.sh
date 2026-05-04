#!/usr/bin/env bash
# ============================================================
#  One-Click DeepSeek Reverse API Installer - macOS & Linux
#  https://github.com/chirag-gamer/one-click-deepseek-reverse
# ============================================================
set -o pipefail

# ── ANSI Colors ─────────────────────────────────────────────
BOLD='\033[1m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
RESET='\033[0m'

# ── Global State ────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="${SCRIPT_DIR}/deepseek-reverse-api"
VENV_DIR="${REPO_DIR}/.venv"
TOKEN_LIST=""
ACCOUNT_COUNT=0
PYTHON_CMD=""
PIP_CMD=""
INSTALL_PKG=""  # filled by detect_pkg_manager

# ── Help ────────────────────────────────────────────────────
show_help() {
    cat << EOF
${BOLD}One-Click DeepSeek Reverse API Installer${RESET}

${GREEN}Usage:${RESET}  ./install.sh [OPTIONS]

${CYAN}Options:${RESET}
  --help       Show this help message and exit
  --no-start   Install and configure but don't start the server

${CYAN}Description:${RESET}
  This script automatically:
   1. Detects your OS and installs Python 3.8+ if needed
   2. Clones the DeepSeek Reverse API repository
   3. Creates a Python virtual environment
   4. Installs all required dependencies
   5. Prompts for DeepSeek account credentials
   6. Fetches API tokens automatically
   7. Creates .env configuration
   8. Starts the local API server on http://localhost:8000

${CYAN}Supported OS:${RESET} macOS (brew), Ubuntu/Debian (apt), Fedora (dnf),
              Arch (pacman), openSUSE (zypper), Alpine (apk)

${CYAN}Repository:${RESET} https://github.com/chirag-gamer/one-click-deepseek-reverse
EOF
    exit 0
}

# ── Error Handler ───────────────────────────────────────────
trap 'echo -e "${RED}[X] Installation failed at line $LINENO.${RESET}"; exit 1' ERR

# ── Parse Arguments ─────────────────────────────────────────
NO_START=false
for arg in "$@"; do
    case "$arg" in
        --help|-h) show_help ;;
        --no-start) NO_START=true ;;
        *) echo -e "${RED}Unknown option: $arg${RESET}"; show_help ;;
    esac
done

# ── OS & Package Manager Detection ──────────────────────────
detect_pkg_manager() {
    local os_name
    os_name="$(uname -s)"

    echo -e "${BLUE}[*] Detecting operating system...${RESET}"

    case "$os_name" in
        Darwin)
            echo -e "${GREEN}[v] macOS detected.${RESET}"
            if command -v brew >/dev/null 2>&1; then
                echo -e "${GREEN}[v] Homebrew found.${RESET}"
            else
                echo -e "${YELLOW}[!] Homebrew not found. Installing...${RESET}"
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                # Add brew to PATH for this session
                if [ -f /opt/homebrew/bin/brew ]; then
                    eval "$(/opt/homebrew/bin/brew shellenv)"
                elif [ -f /usr/local/bin/brew ]; then
                    eval "$(/usr/local/bin/brew shellenv)"
                fi
            fi
            INSTALL_PKG="brew install"
            PYTHON_PKG="python@3.12"
            ;;

        Linux)
            echo -e "${GREEN}[v] Linux detected.${RESET}"
            if [ -f /etc/os-release ]; then
                . /etc/os-release
                echo -e "${CYAN}[*] Distribution: $NAME${RESET}"
            fi

            if command -v apt-get >/dev/null 2>&1; then
                echo -e "${GREEN}[v] apt-get (Debian/Ubuntu) detected.${RESET}"
                INSTALL_PKG="sudo apt-get install -y"
                PYTHON_PKG="python3 python3-pip python3-venv"
                PYTHON_CMD="python3"
                PIP_CMD="pip3"
            elif command -v dnf >/dev/null 2>&1; then
                echo -e "${GREEN}[v] dnf (Fedora/RHEL) detected.${RESET}"
                INSTALL_PKG="sudo dnf install -y"
                PYTHON_PKG="python3 python3-pip python3-virtualenv"
                PYTHON_CMD="python3"
                PIP_CMD="pip3"
            elif command -v pacman >/dev/null 2>&1; then
                echo -e "${GREEN}[v] pacman (Arch) detected.${RESET}"
                INSTALL_PKG="sudo pacman -S --noconfirm"
                PYTHON_PKG="python python-pip python-virtualenv"
                PYTHON_CMD="python"
                PIP_CMD="pip"
            elif command -v zypper >/dev/null 2>&1; then
                echo -e "${GREEN}[v] zypper (openSUSE) detected.${RESET}"
                INSTALL_PKG="sudo zypper install -y"
                PYTHON_PKG="python3 python3-pip python3-virtualenv"
                PYTHON_CMD="python3"
                PIP_CMD="pip3"
            elif command -v apk >/dev/null 2>&1; then
                echo -e "${GREEN}[v] apk (Alpine) detected.${RESET}"
                INSTALL_PKG="sudo apk add"
                PYTHON_PKG="python3 py3-pip py3-virtualenv"
                PYTHON_CMD="python3"
                PIP_CMD="pip3"
            else
                echo -e "${RED}[X] Could not detect a supported package manager.${RESET}"
                echo -e "${RED}    Supported: apt-get, dnf, pacman, zypper, apk${RESET}"
                echo -e "${RED}    Please install Python 3.8+ manually and re-run.${RESET}"
                exit 1
            fi
            ;;

        *)
            echo -e "${RED}[X] Unsupported OS: $os_name${RESET}"
            echo -e "${RED}    This script supports macOS and Linux only.${RESET}"
            echo -e "${RED}    For Windows, use install.bat instead.${RESET}"
            exit 1
            ;;
    esac

    export INSTALL_PKG PYTHON_PKG PYTHON_CMD PIP_CMD
}

# ── Step 1: Find or Install Python ──────────────────────────
ensure_python() {
    echo -e "\n${BLUE}[Step 1/5] Checking Python installation...${RESET}"

    # If not already set by OS detection, try to find Python
    if [ -z "$PYTHON_CMD" ]; then
        if command -v python3 >/dev/null 2>&1; then
            PYTHON_CMD="python3"
            PIP_CMD="pip3"
        elif command -v python >/dev/null 2>&1; then
            PYTHON_CMD="python"
            PIP_CMD="pip"
        fi
    fi

    if [ -n "$PYTHON_CMD" ] && command -v "$PYTHON_CMD" >/dev/null 2>&1; then
        local py_ver
        py_ver="$("$PYTHON_CMD" --version 2>&1 | grep -oE '[0-9]+\.[0-9]+' | head -1)"
        local py_major py_minor
        py_major="$(echo "$py_ver" | cut -d. -f1)"
        py_minor="$(echo "$py_ver" | cut -d. -f2)"

        if [ "$py_major" -ge 3 ] && [ "$py_minor" -ge 8 ]; then
            echo -e "${GREEN}[v] Python $py_ver found at: $(command -v "$PYTHON_CMD")${RESET}"

            # Ensure pip
            if ! "$PYTHON_CMD" -m pip --version >/dev/null 2>&1; then
                echo -e "${YELLOW}[!] pip not found. Installing...${RESET}"
                "$PYTHON_CMD" -m ensurepip --upgrade 2>/dev/null || {
                    echo -e "${YELLOW}[!] ensurepip failed. Attempting via package manager...${RESET}"
                    eval "$INSTALL_PKG $PYTHON_PKG" 2>/dev/null || true
                }
            fi

            if command -v pip3 >/dev/null 2>&1; then
                PIP_CMD="pip3"
            elif command -v pip >/dev/null 2>&1; then
                PIP_CMD="pip"
            else
                PIP_CMD="$PYTHON_CMD -m pip"
            fi

            echo -e "${GREEN}[v] pip is available${RESET}"
            return 0
        else
            echo -e "${YELLOW}[!] Python $py_ver is too old (need 3.8+)${RESET}"
        fi
    else
        echo -e "${YELLOW}[!] Python 3.8+ not found. Installing...${RESET}"
    fi

    # Install Python via detected package manager
    echo -e "${CYAN}[*] Installing Python via package manager...${RESET}"
    eval "$INSTALL_PKG $PYTHON_PKG"

    # Re-detect after install
    if command -v python3 >/dev/null 2>&1; then
        PYTHON_CMD="python3"
        PIP_CMD="pip3"
    elif command -v python >/dev/null 2>&1; then
        PYTHON_CMD="python"
        PIP_CMD="pip"
    else
        echo -e "${RED}[X] Python installation failed.${RESET}"
        echo -e "${RED}    Please install Python 3.8+ manually:${RESET}"
        echo -e "${RED}    https://python.org/downloads/${RESET}"
        exit 1
    fi

    echo -e "${GREEN}[v] Python installed: $("$PYTHON_CMD" --version)${RESET}"
    export PYTHON_CMD PIP_CMD
}

# ── Step 2: Clone Repository ────────────────────────────────
clone_repo() {
    echo -e "\n${BLUE}[Step 2/5] Setting up DeepSeek Reverse API...${RESET}"

    if [ -d "${REPO_DIR}/.git" ]; then
        echo -e "${GREEN}[v] Repository already exists, skipping clone.${RESET}"
    elif [ -d "$REPO_DIR" ]; then
        echo -e "${YELLOW}[!] Directory exists but is not a git repo. Removing...${RESET}"
        rm -rf "$REPO_DIR"
    fi

    if [ ! -d "$REPO_DIR" ]; then
        if command -v git >/dev/null 2>&1; then
            echo -e "${CYAN}[*] Cloning with git...${RESET}"
            git clone https://github.com/Wu-jiyan/deepseek-reverse-api.git "$REPO_DIR"
        else
            echo -e "${YELLOW}[!] Git not found. Downloading with curl...${RESET}"
            local zip_url="https://github.com/Wu-jiyan/deepseek-reverse-api/archive/refs/heads/main.zip"
            local tmp_zip="/tmp/deepseek-main-$$.zip"
            local tmp_dir="/tmp/deepseek-extract-$$"

            if command -v curl >/dev/null 2>&1; then
                curl -L -o "$tmp_zip" "$zip_url"
            elif command -v wget >/dev/null 2>&1; then
                wget -O "$tmp_zip" "$zip_url"
            else
                echo -e "${RED}[X] Neither git, curl, nor wget found. Please install one.${RESET}"
                exit 1
            fi

            mkdir -p "$tmp_dir"
            unzip -q "$tmp_zip" -d "$tmp_dir"
            mv "$tmp_dir"/deepseek-reverse-api-main "$REPO_DIR"
            rm -f "$tmp_zip"
            rm -rf "$tmp_dir"
        fi
    fi

    echo -e "${GREEN}[v] Repository ready at: $REPO_DIR${RESET}"
}

# ── Step 3: Install Dependencies ────────────────────────────
install_deps() {
    echo -e "\n${BLUE}[Step 3/5] Installing Python dependencies...${RESET}"

    if [ ! -f "${REPO_DIR}/requirements.txt" ]; then
        echo -e "${RED}[X] requirements.txt not found! Repository may be incomplete.${RESET}"
        exit 1
    fi

    cd "$REPO_DIR" || exit 1

    # Create virtual environment
    if [ ! -d "$VENV_DIR" ]; then
        echo -e "${CYAN}[*] Creating virtual environment...${RESET}"
        "$PYTHON_CMD" -m venv "$VENV_DIR"
    else
        echo -e "${GREEN}[v] Virtual environment already exists.${RESET}"
    fi

    # Activate
    if [ -f "${VENV_DIR}/bin/activate" ]; then
        # shellcheck disable=SC1091
        source "${VENV_DIR}/bin/activate"
    elif [ -f "${VENV_DIR}/Scripts/activate" ]; then
        # Windows/WSL fallback
        # shellcheck disable=SC1091
        source "${VENV_DIR}/Scripts/activate"
    else
        echo -e "${RED}[X] Could not find virtual environment activate script.${RESET}"
        exit 1
    fi

    echo -e "${GREEN}[v] Virtual environment activated.${RESET}"

    # Upgrade pip
    pip install --upgrade pip >/dev/null 2>&1 || true

    # Install dependencies
    echo -e "${CYAN}[*] Installing packages (this may take a few minutes)...${RESET}"
    pip install -r requirements.txt

    echo -e "${GREEN}[v] All dependencies installed successfully.${RESET}"

    deactivate 2>/dev/null || true
}

# ── Password Prompt (secure, hides input) ───────────────────
prompt_password() {
    local prompt="$1"
    local var_name="$2"
    local pw=""

    echo -n -e "$prompt"
    stty -echo 2>/dev/null || true
    read -r pw
    stty echo 2>/dev/null || true
    echo ""

    printf -v "$var_name" '%s' "$pw"
}

# ── Step 4: Configure Accounts ──────────────────────────────
configure_accounts() {
    echo -e "\n${BLUE}[Step 4/5] Configuring DeepSeek accounts...${RESET}"
    echo ""
    echo -e "${YELLOW}Please provide your DeepSeek account credentials.${RESET}"
    echo -e "${YELLOW}(Email and password used at https://chat.deepseek.com)${RESET}"
    echo ""

    while true; do
        ACCOUNT_COUNT=$((ACCOUNT_COUNT + 1))
        echo -e "${CYAN}============================================${RESET}"
        echo -e "${CYAN}  Account #${ACCOUNT_COUNT}${RESET}"
        echo -e "${CYAN}============================================${RESET}"

        # Get email
        local email=""
        while [ -z "$email" ]; do
            echo -n -e "${MAGENTA}Enter DeepSeek Email: ${RESET}"
            read -r email
            if [ -z "$email" ]; then
                echo -e "${RED}[X] Email cannot be empty.${RESET}"
            fi
        done

        # Get password (masked)
        local password=""
        while [ -z "$password" ]; do
            prompt_password "${MAGENTA}Enter DeepSeek Password: ${RESET}" "password"
            if [ -z "$password" ]; then
                echo -e "${RED}[X] Password cannot be empty.${RESET}"
            fi
        done

        echo ""
        echo -e "${CYAN}[*] Logging in and fetching token...${RESET}"

        # Activate venv and login
        local login_script="
import sys
sys.path.insert(0, '${REPO_DIR}')
from deepseek_ai.account_register import register_account_auto
result = register_account_auto('${email//\'/\'\\\'\'}', '${password//\'/\'\\\'\'}')
if result.success:
    print(result.token, end='')
else:
    print('', end='')
    import sys
    sys.stderr.write(result.error or 'unknown error')
"

        local new_token
        if [ -f "${VENV_DIR}/bin/activate" ]; then
            # shellcheck disable=SC1091
            source "${VENV_DIR}/bin/activate" 2>/dev/null
            new_token="$(python -c "$login_script" 2>/dev/null)"
            deactivate 2>/dev/null || true
        else
            new_token="$("$PYTHON_CMD" -c "$login_script" 2>/dev/null)"
        fi

        if [ -z "$new_token" ]; then
            echo -e "${RED}[X] Login failed. Check your email and password.${RESET}"
            echo -n -e "${YELLOW}Retry this account? (y/n): ${RESET}"
            read -r retry
            if [ "$retry" = "y" ] || [ "$retry" = "Y" ]; then
                ACCOUNT_COUNT=$((ACCOUNT_COUNT - 1))
                continue
            fi
        else
            echo -e "${GREEN}[v] Token obtained successfully for ${email}${RESET}"

            if [ -z "$TOKEN_LIST" ]; then
                TOKEN_LIST="$new_token"
            else
                TOKEN_LIST="${TOKEN_LIST},${new_token}"
            fi
        fi

        echo ""
        echo -n -e "${YELLOW}Add another DeepSeek account? (y/n): ${RESET}"
        read -r more_accounts
        if [ "$more_accounts" != "y" ] && [ "$more_accounts" != "Y" ]; then
            break
        fi
    done

    if [ -z "$TOKEN_LIST" ]; then
        echo -e "${RED}[X] No tokens obtained. Cannot continue.${RESET}"
        exit 1
    fi

    echo ""
    echo -e "${GREEN}[v] Successfully configured ${ACCOUNT_COUNT} account(s).${RESET}"
}

# ── Create .env file ────────────────────────────────────────
create_env_file() {
    echo -e "${CYAN}[*] Creating .env configuration...${RESET}"

    cat > "${REPO_DIR}/.env" << ENVEOF
# DeepSeek AI Reverse API Configuration
# Generated by one-click-deepseek-reverse installer

DEEPSEEK_TOKENS=${TOKEN_LIST}

PORT=8000
HOST=0.0.0.0

AUTO_DELETE_SESSION=false
TOKEN_STRATEGY=round_robin

LOG_LEVEL=INFO
ENVEOF

    echo -e "${GREEN}[v] .env file created at ${REPO_DIR}/.env${RESET}"
}

# ── Create start.sh launcher ────────────────────────────────
create_launcher() {
    echo -e "${CYAN}[*] Creating start.sh launcher...${RESET}"

    cat > "${SCRIPT_DIR}/start.sh" << 'LAUNCHER'
#!/usr/bin/env bash
# DeepSeek Reverse API Server Launcher
# Generated by one-click-deepseek-reverse

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="${SCRIPT_DIR}/deepseek-reverse-api"
VENV_DIR="${REPO_DIR}/.venv"

if [ ! -d "$REPO_DIR" ]; then
    echo -e "\033[0;31m[X] deepseek-reverse-api not found. Run install.sh first.\033[0m"
    exit 1
fi

if [ ! -f "${VENV_DIR}/bin/activate" ]; then
    echo -e "\033[0;31m[X] Virtual environment not found. Run install.sh first.\033[0m"
    exit 1
fi

# shellcheck disable=SC1091
source "${VENV_DIR}/bin/activate"

cd "$REPO_DIR" || exit 1

echo ""
echo -e "\033[0;32m============================================================\033[0m"
echo -e "\033[0;32m  Server starting at http://localhost:8000\033[0m"
echo -e "\033[0;32m  Health check:  http://localhost:8000/health\033[0m"
echo -e "\033[0;32m  API endpoint:  http://localhost:8000/v1/chat/completions\033[0m"
echo -e "\033[0;32m  Models list:   http://localhost:8000/v1/models\033[0m"
echo -e "\033[0;32m============================================================\033[0m"
echo ""
echo -e "\033[0;33mPress Ctrl+C to stop the server.\033[0m"
echo ""

python start_server.py

echo ""
echo -e "\033[0;33mServer stopped.\033[0m"
LAUNCHER

    chmod +x "${SCRIPT_DIR}/start.sh"
    echo -e "${GREEN}[v] Launcher created: ${SCRIPT_DIR}/start.sh${RESET}"
}

# ── Step 5: Start Server ────────────────────────────────────
start_server() {
    echo -e "\n${BLUE}[Step 5/5] Starting the DeepSeek API server...${RESET}"
    echo ""
    echo -e "${GREEN}============================================================${RESET}"
    echo -e "${GREEN}  Server starting at http://localhost:8000${RESET}"
    echo -e "${GREEN}  Health check:  http://localhost:8000/health${RESET}"
    echo -e "${GREEN}  API endpoint:  http://localhost:8000/v1/chat/completions${RESET}"
    echo -e "${GREEN}  Models list:   http://localhost:8000/v1/models${RESET}"
    echo -e "${GREEN}============================================================${RESET}"
    echo ""
    echo -e "${YELLOW}Press Ctrl+C to stop the server.${RESET}"
    echo ""
    echo -e "${CYAN}[*] To restart later, run: ${BOLD}./start.sh${RESET}"
    echo ""

    # shellcheck disable=SC1091
    source "${VENV_DIR}/bin/activate"
    cd "$REPO_DIR" || exit 1
    python start_server.py
}

# ─────────────────────────────────────────────────────────────
# Main Execution
# ─────────────────────────────────────────────────────────────
main() {
    echo ""
    echo -e "${CYAN}============================================================${RESET}"
    echo -e "${BOLD}${CYAN}   One-Click DeepSeek Reverse API Installer (macOS/Linux)${RESET}"
    echo -e "${CYAN}============================================================${RESET}"
    echo ""
    echo -e "${YELLOW}This script will:${RESET}"
    echo -e "  ${GREEN}1.${RESET} Check/install Python 3.8+"
    echo -e "  ${GREEN}2.${RESET} Clone the DeepSeek Reverse API"
    echo -e "  ${GREEN}3.${RESET} Create virtual environment & install dependencies"
    echo -e "  ${GREEN}4.${RESET} Configure your DeepSeek account(s)"
    echo -e "  ${GREEN}5.${RESET} Start the local API server"
    echo ""

    detect_pkg_manager
    ensure_python
    clone_repo
    install_deps
    configure_accounts
    create_env_file
    create_launcher

    echo ""
    echo -e "${GREEN}============================================================${RESET}"
    echo -e "${GREEN}  Installation complete!${RESET}"
    echo -e "${GREEN}  Server: http://localhost:8000${RESET}"
    echo -e "${GREEN}  Restart: ${SCRIPT_DIR}/start.sh${RESET}"
    echo -e "${GREEN}============================================================${RESET}"
    echo ""

    if [ "$NO_START" = false ]; then
        start_server
    else
        echo -e "${YELLOW}[!] --no-start flag set. Run ./start.sh to start the server.${RESET}"
    fi
}

main "$@"
