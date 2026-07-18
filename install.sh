#!/bin/bash

#Check if the distro was installed , it will upgrade it to latest version
NVIM_CONFIG_DIR="$HOME/.config/nvim"

if [ -d "$NVIM_CONFIG_DIR/.git" ]; then
    echo "🌌 LeVIX detected! Initiating core system upgrade..."
    cd "$NVIM_CONFIG_DIR" || exit

     git pull origin main

     nvim --headless "+Lazy! sync" +qa

    echo "✅ LeVIX has been successfully upgraded to the latest build!"
    exit 0
fi


GREEN="\033[1;32m"
RED="\033[1;31m"
YELLOW="\033[1;33m"
CYAN="\033[1;36m"
RESET="\033[0m"


if command -v doas &> /dev/null; then
    SUDO="doas"
elif command -v sudo &> /dev/null; then
    SUDO="sudo"
else
    SUDO=""
fi


clear
echo -e "${CYAN}"
echo "    __         _    _______  __"
echo "   / /   ___  | |  / /  _/ |/ /"
echo "  / /   / _ \ | | / // / |   / "
echo " / /___/  __/ | |/ // / /   |  "
echo "/_____/\___/  |___/___/_/|_|_| "
echo -e "${RESET}"
echo -e "${YELLOW}===> Welcome to the LeVIX Installer <===${RESET}\n"


echo -e "${CYAN}[1/5] Checking Neovim installation...${RESET}"

if [ -f /etc/arch-release ]; then
    PM="$SUDO pacman -Sy --needed --ask=20"
    PKG_FD="fd"
    PKG_PYTHON3="python"
elif [ -f /etc/debian_version ]; then
    PM="$SUDO apt update; $SUDO apt install -y"
    PKG_FD="fd-find"
    PKG_PYTHON3="python3"
elif [ -f /etc/fedora-release ]; then
    PM="$SUDO dnf install -y"
    PKG_FD="fd-find"
    PKG_PYTHON3="python3"
elif [ -f /etc/void-release ] || grep -q "^ID=void" /etc/os-release 2>/dev/null; then
    PM="$SUDO xbps-install -S -y"
    PKG_FD="fd-find"
    PKG_PYTHON3="python3"
else
    PM=""
    PKG_FD="fd-find"
    PKG_PYTHON3="python3"
fi

download_appimage() {
    local appimage_url="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage"

    echo -e "${CYAN}  Downloading Neovim AppImage (latest stable)...${RESET}"

    if ! curl -Lo /tmp/nvim.appimage "$appimage_url"; then
        echo -e "${RED}  ✗ Failed to download Neovim AppImage.${RESET}"
        return 1
    fi

    chmod u+x /tmp/nvim.appimage
    $SUDO mv /tmp/nvim.appimage /usr/local/bin/nvim
    return 0
}

install_or_upgrade_nvim() {
    echo -e "${CYAN}  Installing/upgrading Neovim...${RESET}"
    if [ -f /etc/fedora-release ]; then
        # Fedora's repo package is kept reasonably current
        eval "$PM neovim"

    elif [ -f /etc/arch-release ]; then
        # Arch repos always carry the latest stable release
        eval "$PM neovim"

    elif [ -f /etc/debian_version ]; then
        # Debian/Ubuntu's default apt repos are usually far behind upstream.
        # Use the official Neovim PPA for an up-to-date build.
        if ! command -v add-apt-repository &> /dev/null; then
            $SUDO apt update
            $SUDO apt install -y software-properties-common
        fi
        $SUDO add-apt-repository -y ppa:neovim-ppa/stable
        $SUDO apt update
        $SUDO apt install -y neovim

        # Fallback if the PPA build still doesn't meet the version requirement
        if command -v nvim &> /dev/null; then
            CHECK_VERSION=$(nvim --version | head -n 1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
            CHECK_MINOR=$(echo "$CHECK_VERSION" | cut -d. -f2)
            if [ "$CHECK_MINOR" -lt 12 ]; then
                echo -e "${YELLOW}  PPA build still outdated, falling back to AppImage...${RESET}"
                download_appimage
            fi
        else
            download_appimage
        fi

    elif [ -f /etc/void-release ] || grep -q "^ID=void" /etc/os-release 2>/dev/null; then
        # Void Linux has reasonably recent packages
        eval "$PM neovim"

    else
        echo -e "${YELLOW}  Unrecognized distro, installing AppImage...${RESET}"
        download_appimage
    fi
}

if ! command -v nvim &> /dev/null; then
    echo -e "${YELLOW}⚠️ Neovim not found. Installing it now...${RESET}"
    install_or_upgrade_nvim
fi

if ! command -v nvim &> /dev/null; then
    echo -e "${RED}❌ Failed to install Neovim automatically. Please install it manually (>= 0.12.0).${RESET}"
    exit 1
fi

NVIM_VERSION=$(nvim --version | head -n 1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
NVIM_MAJOR=$(echo "$NVIM_VERSION" | cut -d. -f1)
NVIM_MINOR=$(echo "$NVIM_VERSION" | cut -d. -f2)

if [ "$NVIM_MAJOR" -eq 0 ] && [ "$NVIM_MINOR" -lt 12 ]; then
    echo -e "${YELLOW}⚠️ Neovim $NVIM_VERSION found, but LeVIX requires >= 0.12.0. Upgrading...${RESET}"
    install_or_upgrade_nvim
    NVIM_VERSION=$(nvim --version | head -n 1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
    NVIM_MAJOR=$(echo "$NVIM_VERSION" | cut -d. -f1)
    NVIM_MINOR=$(echo "$NVIM_VERSION" | cut -d. -f2)
    if [ "$NVIM_MAJOR" -eq 0 ] && [ "$NVIM_MINOR" -lt 12 ]; then
        echo -e "${RED}❌ Could not upgrade Neovim automatically. Please upgrade manually (>= 0.12.0).${RESET}"
        exit 1
    fi
fi

echo -e "${GREEN}✅ Neovim ready (Version: $NVIM_VERSION)${RESET}\n"


echo -e "${CYAN}[2/5] Checking core system dependencies...${RESET}"
declare -A deps=(
    ["git"]="git"
    ["make"]="make"
    ["unzip"]="unzip"
    ["curl"]="curl"
    ["rg"]="ripgrep"
    ["fd"]="$PKG_FD"
    ["node"]="nodejs"
    ["python3"]="$PKG_PYTHON3"
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

    if [ -z "$PM" ]; then
        echo -e "${YELLOW}⚠️  Unsupported package manager. Please install manually:${RESET}"
        echo -e "  ${YELLOW}$SUDO apt install ${missing_deps[*]}${RESET}"
        echo -e "  ${YELLOW}  (or use your distro's package manager)${RESET}"
    else
        echo -e "${CYAN}Installing missing dependencies...${RESET}"
        eval "$PM ${missing_deps[*]}"
    fi
else
    echo -e "${GREEN}✅ All core dependencies are perfectly satisfied!${RESET}\n"
fi


echo -e "${CYAN}[3/5] Optional language tooling${RESET}"
echo -e "${YELLOW}LeVIX has full LSP/lint/format/debug support for:${RESET}"
echo -e "${YELLOW}Java, Python, C/C++, HTML, CSS, JavaScript/TypeScript${RESET}"
echo -e "${YELLOW}You can install support for only the languages you actually use.${RESET}\n"

declare -a selected_langs=()

ask_lang() {
    local lang_name="$1"
    local var_name="$2"
    read -rp "$(echo -e "${CYAN}  Install ${lang_name} tooling? [y/N]: ${RESET}")" answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        selected_langs+=("$var_name")
        echo -e "  ${GREEN}✓${RESET} ${lang_name} selected.\n"
    else
        echo -e "  ${YELLOW}○${RESET} ${lang_name} skipped.\n"
    fi
}

ask_lang "Java (JDK, checkstyle, google-java-format via jdtls)" "java"
ask_lang "Python (ruff)" "python"
ask_lang "C/C++ (clang-tools-extra for clang-tidy)" "cpp"
ask_lang "Web Dev (HTML, CSS, JavaScript - prettier, ESLint, etc.)" "web"

for lang in "${selected_langs[@]}"; do
    case "$lang" in
        java)
            if ! command -v java &> /dev/null; then
                echo -e "${CYAN}  Installing JDK...${RESET}"
                if [ -n "$PM" ]; then
                    if [ -f /etc/fedora-release ]; then
                        eval "$PM java-21-openjdk java-21-openjdk-devel"
                    elif [ -f /etc/debian_version ]; then
                        eval "$PM openjdk-21-jdk"
                    elif [ -f /etc/arch-release ]; then
                        eval "$PM jdk-openjdk"
                    elif [ -f /etc/void-release ] || grep -q "^ID=void" /etc/os-release 2>/dev/null; then
                        eval "$PM openjdk21"
                    fi
                else
                    echo -e "  ${RED}✗${RESET} Please install a JDK (>= 17) manually."
                fi
            else
                echo -e "  ${GREEN}✓${RESET} Java already installed."
            fi
            echo -e "  ${YELLOW}ℹ${RESET}  jdtls, checkstyle, and google-java-format will install automatically via Mason on first launch."
            ;;
        python)
            if ! command -v ruff &> /dev/null; then
                echo -e "${CYAN}  Installing ruff...${RESET}"
                if [ -n "$PM" ]; then
                    eval "$PM ruff" || pip install --user ruff
                else
                    pip install --user ruff
                fi
            else
                echo -e "  ${GREEN}✓${RESET} ruff already installed."
            fi
            ;;
        cpp)
            if ! command -v clang-tidy &> /dev/null; then
                echo -e "${CYAN}  Installing clang-tools-extra...${RESET}"
                if [ -f /etc/fedora-release ]; then
                    eval "$PM clang-tools-extra"
                elif [ -f /etc/debian_version ]; then
                    eval "$PM clang-tidy clang-format"
                elif [ -f /etc/arch-release ]; then
                    eval "$PM clang"
                elif [ -f /etc/void-release ] || grep -q "^ID=void" /etc/os-release 2>/dev/null; then
                    eval "$PM clang-tools-extra"
                else
                    echo -e "  ${RED}✗${RESET} Please install clang-tidy manually."
                fi
            else
                echo -e "  ${GREEN}✓${RESET} clang-tidy already installed."
            fi
            ;;
        web)
            echo -e "${CYAN}  Installing web development tools via npm...${RESET}"
            if command -v npm &> /dev/null; then
                if npm install -g prettier htmlhint stylelint eslint_d; then
                    echo -e "  ${GREEN}✓${RESET} Web dev tools installed successfully."
                else
                    echo -e "  ${YELLOW}⚠${RESET}  npm install failed (may need $SUDO). Try: $SUDO npm install -g prettier htmlhint stylelint eslint_d"
                fi
            else
                echo -e "  ${RED}✗${RESET} npm not found. Please install Node.js/npm first."
            fi
            echo -e "  ${YELLOW}ℹ${RESET}  html, cssls, and ts_ls LSP servers will install automatically via Mason on first launch."
            ;;
    esac
done
echo ""


echo -e "${CYAN}[4/5] Preparing configuration directory...${RESET}"
if [ -d "$HOME/.config/nvim" ]; then
    BACKUP_DIR="$HOME/.config/nvim.bak.$(date +%Y%m%d-%H%M%S)"
    echo -e "${YELLOW}   Found existing Neovim config. Backing up to ${BACKUP_DIR}...${RESET}"
    mv "$HOME/.config/nvim" "$BACKUP_DIR"
fi
echo -e "${GREEN}   Directory is ready.${RESET}\n"


echo -e "${CYAN}[4.5/5] Important Reminders${RESET}"
echo -e "${YELLOW}📝 Please ensure the following BEFORE starting LeVIX:${RESET}"
echo -e "  1. ${YELLOW}Install a Nerd Font${RESET} in your terminal (e.g., JetBrainsMono Nerd Font)"
echo -e "     Without it, icons will appear as broken boxes."
echo -e "  2. ${YELLOW}Set your terminal font${RESET} to use the Nerd Font you installed."
echo -e "  3. ${YELLOW}After installation, run:${RESET} ${CYAN}nvim +checkhealth levix${RESET}"
echo -e "     to verify all dependencies are installed correctly.\n"

echo -e "${CYAN}[5/5] Cloning LeVIX from GitHub...${RESET}"
if git clone https://github.com/Ledev0/LeVIX.git "$HOME/.config/nvim"; then
    echo -e "\n${GREEN}==================================================${RESET}"
    echo -e "${GREEN}🎉 LeVIX has been successfully installed!${RESET}"
    echo -e "${YELLOW}👉 Just type 'nvim' in your terminal and enjoy!${RESET}"
    echo -e "${GREEN}==================================================${RESET}"
else
    echo -e "${RED}❌ Failed to clone the repository. Check your internet connection.${RESET}"
    exit 1
fi
