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


download_appimage() {
    local url="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage"

    echo -e "${CYAN}  Downloading Neovim AppImage...${RESET}"
    if curl -sSL -o /tmp/nvim.appimage "$url"; then
        chmod u+x /tmp/nvim.appimage
        if [ -w /usr/local/bin ]; then
            mv /tmp/nvim.appimage /usr/local/bin/nvim
        elif [ -n "$SUDO" ]; then
            $SUDO mv /tmp/nvim.appimage /usr/local/bin/nvim
        else
            echo -e "  ${YELLOW}⚠${RESET}  Cannot write to /usr/local/bin and no privilege escalator found."
            echo -e "  ${YELLOW}  Manually move the file:${RESET} sudo mv /tmp/nvim.appimage /usr/local/bin/nvim"
            return 1
        fi
        echo -e "  ${GREEN}✓${RESET} AppImage installed to /usr/local/bin/nvim."
        return 0
    else
        echo -e "  ${RED}✗${RESET} Failed to download AppImage."
        return 1
    fi
}

echo -e "${CYAN}[1/6] Checking Neovim installation...${RESET}"

NEEDS_NVIM=0
if ! command -v nvim &> /dev/null; then
    echo -e "  ${RED}✗${RESET} nvim is missing."
    NEEDS_NVIM=1
else
    NVIM_VERSION=$(nvim --version | head -n 1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
    NVIM_MAJOR=$(echo "$NVIM_VERSION" | cut -d. -f1)
    NVIM_MINOR=$(echo "$NVIM_VERSION" | cut -d. -f2)
    if [ "$NVIM_MAJOR" -eq 0 ] && [ "$NVIM_MINOR" -lt 12 ]; then
        echo -e "  ${RED}✗${RESET} nvim version $NVIM_VERSION (need >= 0.12)."
        NEEDS_NVIM=1
    else
        echo -e "  ${GREEN}✓${RESET} nvim (version $NVIM_VERSION)."
    fi
fi

if [ $NEEDS_NVIM -eq 1 ]; then
    read -rp "$(echo -e "${CYAN}  Download Neovim AppImage instead? [y/N]: ${RESET}")" answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        download_appimage
        if command -v nvim &> /dev/null; then
            NVIM_VERSION=$(nvim --version | head -n 1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
            NVIM_MAJOR=$(echo "$NVIM_VERSION" | cut -d. -f1)
            NVIM_MINOR=$(echo "$NVIM_VERSION" | cut -d. -f2)
            if [ "$NVIM_MAJOR" -eq 0 ] && [ "$NVIM_MINOR" -lt 12 ]; then
                echo -e "  ${YELLOW}⚠${RESET}  AppImage is still < 0.12 (version $NVIM_VERSION)."
            else
                NEEDS_NVIM=0
                echo -e "  ${GREEN}✓${RESET} nvim (version $NVIM_VERSION)."
            fi
        fi
    fi
fi


echo -e "${CYAN}[2/6] Checking core system dependencies...${RESET}"

MISSING=0
for tool in git make unzip curl rg fd node python3 cargo; do
    if ! command -v "$tool" &> /dev/null; then
        echo -e "  ${RED}✗${RESET} $tool is missing."
        MISSING=1
    else
        echo -e "  ${GREEN}✓${RESET} $tool is ready."
    fi
done


if [ $NEEDS_NVIM -eq 1 ] || [ $MISSING -eq 1 ]; then
    echo -e "\n${YELLOW}Install the missing tools with your package manager. For example:${RESET}\n"
    echo -e "  ${CYAN}Arch:${RESET}   sudo pacman -S neovim git make unzip curl ripgrep fd nodejs python cargo"
    echo -e "  ${CYAN}Debian:${RESET} sudo apt install neovim git make unzip curl ripgrep fd-find nodejs python3 cargo"
    echo -e "  ${CYAN}Fedora:${RESET} sudo dnf install neovim git make unzip curl ripgrep fd-find nodejs python3 cargo"
    echo -e "  ${CYAN}Void:${RESET}   sudo xbps-install neovim git make unzip curl ripgrep fd nodejs python3 cargo"
    echo -e "  ${CYAN}Gentoo:${RESET} sudo emerge --ask dev-vcs/git sys-devel/make app-arch/unzip net-misc/curl sys-apps/ripgrep sys-apps/fd net-libs/nodejs dev-lang/python dev-lang/rust"
    echo -e "  ${CYAN}Nix:${RESET}    nix-env -iA nixpkgs.neovim nixpkgs.git nixpkgs.make nixpkgs.unzip nixpkgs.curl nixpkgs.ripgrep nixpkgs.fd nixpkgs.nodejs nixpkgs.python3 nixpkgs.cargo"
    echo ""
    exit 1
fi

echo -e "${GREEN}✅ All dependencies satisfied.${RESET}\n"


echo -e "${CYAN}[3/6] Optional language tooling${RESET}"
echo -e "${YELLOW}LeVIX has full LSP/lint/format/debug support for:${RESET}"
echo -e "${YELLOW}Java, Python, C/C++, HTML, CSS, JavaScript/TypeScript${RESET}"
echo -e "${YELLOW}You can install support for only the languages you actually use.${RESET}\n"

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

declare -a selected_langs=()

ask_lang "Java (JDK, checkstyle, google-java-format via jdtls)" "java"
ask_lang "Python (ruff)" "python"
ask_lang "C/C++ (clang-tools-extra for clang-tidy)" "cpp"
ask_lang "Web Dev (HTML, CSS, JavaScript - prettier, ESLint, etc.)" "web"

for lang in "${selected_langs[@]}"; do
    case "$lang" in
        java)
            if command -v java &> /dev/null; then
                echo -e "  ${GREEN}✓${RESET} java is ready."
            else
                echo -e "  ${YELLOW}⚠${RESET}  JDK not found. Install with your package manager, for example:${RESET}"
                echo -e "    Arch:   sudo pacman -S jdk-openjdk"
                echo -e "    Debian: sudo apt install openjdk-21-jdk"
                echo -e "    Fedora: sudo dnf install java-21-openjdk java-21-openjdk-devel"
                echo -e "    Void:   sudo xbps-install openjdk21"
                echo -e "    Gentoo: sudo emerge --ask dev-java/openjdk:17"
            fi
            echo -e "  ${YELLOW}ℹ${RESET}  jdtls, checkstyle, and google-java-format will install automatically via Mason on first launch."
            ;;
        python)
            if command -v ruff &> /dev/null; then
                echo -e "  ${GREEN}✓${RESET} ruff is ready."
            else
                echo -e "  ${YELLOW}⚠${RESET}  ruff not found. Install it:${RESET}"
                echo -e "    pip install --user ruff"
            fi
            ;;
        cpp)
            if command -v clang-tidy &> /dev/null; then
                echo -e "  ${GREEN}✓${RESET} clang-tidy is ready."
            else
                echo -e "  ${YELLOW}⚠${RESET}  clang-tidy not found. Install with your package manager, for example:${RESET}"
                echo -e "    Arch:   sudo pacman -S clang"
                echo -e "    Debian: sudo apt install clang-tidy clang-format"
                echo -e "    Fedora: sudo dnf install clang-tools-extra"
                echo -e "    Void:   sudo xbps-install clang-tools-extra"
                echo -e "    Gentoo: sudo emerge --ask sys-devel/clang"
            fi
            ;;
        web)
            WEB_MISSING=""
            for web_tool in prettier htmlhint stylelint eslint_d; do
                if ! command -v "$web_tool" &> /dev/null; then
                    WEB_MISSING="$web_tool $WEB_MISSING"
                fi
            done
            if [ -n "$WEB_MISSING" ]; then
                echo -e "  ${YELLOW}⚠${RESET}  Some web tools not found. Install them:${RESET}"
                echo -e "    npm install -g prettier htmlhint stylelint eslint_d"
            else
                echo -e "  ${GREEN}✓${RESET} Web tools are ready."
            fi
            echo -e "  ${YELLOW}ℹ${RESET}  html, cssls, and ts_ls LSP servers will install automatically via Mason on first launch."
            ;;
    esac
done
echo ""


echo -e "${CYAN}[4/6] Preparing configuration directory...${RESET}"
if [ -d "$HOME/.config/nvim" ]; then
    BACKUP_DIR="$HOME/.config/nvim.bak.$(date +%Y%m%d-%H%M%S)"
    echo -e "${YELLOW}   Found existing Neovim config. Backing up to ${BACKUP_DIR}...${RESET}"
    mv "$HOME/.config/nvim" "$BACKUP_DIR"
fi
echo -e "${GREEN}   Directory is ready.${RESET}\n"


echo -e "${CYAN}[5/6] Important Reminders${RESET}"
echo -e "${YELLOW}📝 Please ensure the following BEFORE starting LeVIX:${RESET}"
echo -e "  1. ${YELLOW}Install a Nerd Font${RESET} in your terminal (e.g., JetBrainsMono Nerd Font)"
echo -e "     Without it, icons will appear as broken boxes."
echo -e "  2. ${YELLOW}Set your terminal font${RESET} to use the Nerd Font you installed."
echo -e "  3. ${YELLOW}After installation, run:${RESET} ${CYAN}nvim +checkhealth levix${RESET}"
echo -e "     to verify all dependencies are installed correctly.\n"

echo -e "${CYAN}[6/6] Cloning LeVIX from GitHub...${RESET}"
if git clone https://github.com/Ledev0/LeVIX.git "$HOME/.config/nvim"; then
    echo -e "\n${GREEN}==================================================${RESET}"
    echo -e "${GREEN}🎉 LeVIX has been successfully installed!${RESET}"
    echo -e "${YELLOW}👉 Just type 'nvim' in your terminal and enjoy!${RESET}"
    echo -e "${GREEN}==================================================${RESET}"
else
    echo -e "${RED}❌ Failed to clone the repository. Check your internet connection.${RESET}"
    exit 1
fi
