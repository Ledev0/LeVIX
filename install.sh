#!/bin/bash

GREEN="\033[1;32m"
RED="\033[1;31m"
YELLOW="\033[1;33m"
CYAN="\033[1;36m"
RESET="\033[0m"


clear
echo -e "${CYAN}"
echo "    __         _    _______  __"
echo "   / /   ___  | |  / /  _/ |/ /"
echo "  / /   / _ \ | | / // / |   / "
echo " / /___/  __/ | |/ // / /   |  "
echo "/_____/\___/  |___/___/_/|_|_| "
echo -e "${RESET}"
echo -e "${YELLOW}===> Welcome to the LeVIX Installer <===${RESET}\n"


echo -e "${CYAN}[1/4] Checking Neovim installation...${RESET}"
if ! command -v nvim &> /dev/null; then
    echo -e "${RED}❌ Neovim is not installed! Please install Neovim (0.9+) first.${RESET}"
    exit 1
fi

NVIM_VERSION=$(nvim --version | head -n 1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
echo -e "${GREEN}✅ Neovim found (Version: $NVIM_VERSION)${RESET}\n"


echo -e "${CYAN}[2/4] Checking system dependencies...${RESET}"
declare -A deps=(
    ["git"]="git"
    ["make"]="make"
    ["unzip"]="unzip"
    ["curl"]="curl"
    ["rg"]="ripgrep"
    ["fzf"]="fzf"
    ["node"]="nodejs"
    ["python3"]="python3"
    ["rust"]="rust"
    ["cargo"]="cargo"
)

missing_deps=()

for cmd in "${!deps[@]}"; do
    if ! command -v "$cmd" &> /dev/null; then
        echo -e "  ${RED}✗${RESET} $cmd is missing."
        missing_deps+=("${deps[$cmd]}")
    else
        echo -e "  ${GREEN}✓${RESET} $cmd is ready."
    fi
done


if [ ${#missing_deps[@]} -ne 0 ]; then
    echo -e "\n${YELLOW}⚠️ Missing required packages: ${missing_deps[*]}${RESET}"
    
    if [ -f /etc/arch-release ]; then
        PM="sudo pacman -Sy --needed --noconfirm"
    elif [ -f /etc/debian_version ]; then
        PM="sudo apt update && sudo apt install -y"
    elif [ -f /etc/fedora-release ]; then
        PM="sudo dnf install -y"
    else
        echo -e "${RED}❌ Unsupported package manager. Please install them manually.${RESET}"
        exit 1
    fi

    echo -e "${CYAN}Installing missing dependencies...${RESET}"
    eval "$PM ${missing_deps[*]}"
else
    echo -e "${GREEN}✅ All dependencies are perfectly satisfied!${RESET}\n"
fi

echo -e "${CYAN}[3/4] Preparing configuration directory...${RESET}"
if [ -d "$HOME/.config/nvim" ]; then
    echo -e "${YELLOW}   Found existing Neovim config. Backing up to ~/.config/nvim.bak...${RESET}"
    rm -rf "$HOME/.config/nvim.bak"
    mv "$HOME/.config/nvim" "$HOME/.config/nvim.bak"
fi
echo -e "${GREEN}   Directory is ready.${RESET}\n"


echo -e "${CYAN}[4/4] Cloning LeVIX from GitHub...${RESET}"
if git clone https://github.com/Ledev0/LeVIX.git "$HOME/.config/nvim"; then
    echo -e "\n${GREEN}==================================================${RESET}"
    echo -e "${GREEN}🎉 LeVIX has been successfully installed!${RESET}"
    echo -e "${YELLOW}👉 Just type 'nvim' in your terminal and enjoy!${RESET}"
    echo -e "${GREEN}==================================================${RESET}"
else
    echo -e "${RED}❌ Failed to clone the repository. Check your internet connection.${RESET}"
    exit 1
fi
