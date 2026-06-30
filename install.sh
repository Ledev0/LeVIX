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
    PM="sudo pacman -Sy --needed --noconfirm"
elif [ -f /etc/debian_version ]; then
    PM="sudo apt update && sudo apt install -y"
elif [ -f /etc/fedora-release ]; then
    PM="sudo dnf install -y"
else
    PM=""
fi

verify_checksum() {
    local file_path="$1"
    local checksum_url="$2"
    local file_name
    file_name=$(basename "$file_path")

    echo -e "${CYAN}  Verifying checksum for ${file_name}...${RESET}"

    if ! curl -sL -o /tmp/nvim.sha256sum "$checksum_url"; then
        echo -e "${RED}  ✗ Could not download checksum file. Aborting for safety.${RESET}"
        rm -f "$file_path"
        return 1
    fi

    local expected actual
    expected=$(grep "$file_name" /tmp/nvim.sha256sum | awk '{print $1}')
    if [ -z "$expected" ]; then
        echo -e "${RED}  ✗ No checksum entry found for ${file_name}. Aborting for safety.${RESET}"
        rm -f "$file_path" /tmp/nvim.sha256sum
        return 1
    fi

    actual=$(sha256sum "$file_path" | awk '{print $1}')
    rm -f /tmp/nvim.sha256sum

    if [ "$expected" != "$actual" ]; then
        echo -e "${RED}  ✗ Checksum mismatch! Expected ${expected}, got ${actual}.${RESET}"
        echo -e "${RED}    The download may be corrupted or tampered with. Aborting.${RESET}"
        rm -f "$file_path"
        return 1
    fi

    echo -e "${GREEN}  ✓ Checksum verified.${RESET}"
    return 0
}

download_verified_appimage() {
    local appimage_url="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage"
    local checksum_url="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage.sha256sum"

    if ! curl -Lo /tmp/nvim.appimage "$appimage_url"; then
        echo -e "${RED}  ✗ Failed to download Neovim AppImage.${RESET}"
        return 1
    fi

    if ! verify_checksum /tmp/nvim.appimage "$checksum_url"; then
        return 1
    fi

    chmod u+x /tmp/nvim.appimage
    sudo mv /tmp/nvim.appimage /usr/local/bin/nvim
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
            sudo apt update
            sudo apt install -y software-properties-common
        fi
        sudo add-apt-repository -y ppa:neovim-ppa/stable
        sudo apt update
        sudo apt install -y neovim

        # Fallback if the PPA build still doesn't meet the version requirement
        if command -v nvim &> /dev/null; then
            CHECK_VERSION=$(nvim --version | head -n 1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
            CHECK_MINOR=$(echo "$CHECK_VERSION" | cut -d. -f2)
            if [ "$CHECK_MINOR" -lt 12 ]; then
                echo -e "${YELLOW}  PPA build still outdated, falling back to verified AppImage...${RESET}"
                download_verified_appimage
            fi
        else
            download_verified_appimage
        fi

    else
        echo -e "${YELLOW}  Unrecognized distro, installing verified AppImage...${RESET}"
        download_verified_appimage
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
    ["fd"]="fd-find"
    ["fzf"]="fzf"
    ["node"]="nodejs"
    ["python3"]="python3"
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
        echo -e "${RED}❌ Unsupported package manager. Please install them manually.${RESET}"
        exit 1
    fi

    echo -e "${CYAN}Installing missing dependencies...${RESET}"
    eval "$PM ${missing_deps[*]}"
else
    echo -e "${GREEN}✅ All core dependencies are perfectly satisfied!${RESET}\n"
fi


echo -e "${CYAN}[3/5] Optional language tooling${RESET}"
echo -e "${YELLOW}LeVIX has full LSP/lint/format/debug support for Java, Python, and C/C++.${RESET}"
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
                else
                    echo -e "  ${RED}✗${RESET} Please install clang-tidy manually."
                fi
            else
                echo -e "  ${GREEN}✓${RESET} clang-tidy already installed."
            fi
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
