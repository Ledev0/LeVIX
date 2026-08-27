#!/usr/bin/env pwsh
# LeVIX installer for Windows (PowerShell)
# Run from PowerShell 5.1+ or PowerShell 7:
#   powershell -ExecutionPolicy Bypass -File install.ps1
# or
#   pwsh ./install.ps1

$NVIM_CONFIG_DIR = Join-Path $env:LOCALAPPDATA "nvim"

# --------------------------------------------------------------------------
# Upgrade mode: if the distro is already installed, pull + sync latest
# --------------------------------------------------------------------------
if (Test-Path (Join-Path $NVIM_CONFIG_DIR ".git")) {
    Write-Host ""
    Write-Host "[LeVIX] Detected existing install - initiating upgrade..." -ForegroundColor Cyan
    Set-Location $NVIM_CONFIG_DIR
    git pull origin main
    nvim --headless "+Lazy! sync" +qa
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[LeVIX] Sync finished with errors." -ForegroundColor Yellow
    } else {
        Write-Host "[LeVIX] Upgrade complete!" -ForegroundColor Green
    }
    exit 0
}

# --------------------------------------------------------------------------
# Helpers
# --------------------------------------------------------------------------
function Ask-YesNo {
    param([string]$Prompt)
    while ($true) {
        $answer = Read-Host -Prompt $Prompt
        if ($answer -match '^[Yy]') { return $true }
        if ($answer -match '^[Nn]' -or [string]::IsNullOrWhiteSpace($answer)) { return $false }
    }
}

function Test-Command {
    param([string]$Cmd)
    return [bool](Get-Command $Cmd -ErrorAction SilentlyContinue)
}

function Get-NvimVersion {
    $line = nvim --version 2>$null | Select-Object -First 1
    if ($line -match '(\d+)\.(\d+)\.(\d+)') {
        return @{ Major = [int]$matches[1]; Minor = [int]$matches[2] }
    }
    return @{ Major = -1; Minor = -1 }
}

Write-Host ""
Write-Host "==============================================================" -ForegroundColor Cyan
Write-Host "          Welcome to the LeVIX Installer (Windows)" -ForegroundColor Cyan
Write-Host "==============================================================" -ForegroundColor Cyan
Write-Host ""

# --------------------------------------------------------------------------
# [1/6] Neovim check (need >= 0.12)
# --------------------------------------------------------------------------
Write-Host "[1/6] Checking Neovim installation..." -ForegroundColor Cyan
$NeedsNvim = $false
if (-not (Test-Command nvim)) {
    Write-Host "  [MISSING] nvim." -ForegroundColor Red
    $NeedsNvim = $true
} else {
    $ver = Get-NvimVersion
    if ($ver.Major -eq 0 -and $ver.Minor -lt 12) {
        Write-Host "  [OLD] nvim v$($ver.Major).$($ver.Minor) found (need >= 0.12)." -ForegroundColor Red
        $NeedsNvim = $true
    } else {
        Write-Host "  [OK] nvim v$($ver.Major).$($ver.Minor)." -ForegroundColor Green
    }
}

if ($NeedsNvim) {
    Write-Host "Install Neovim with your favorite package manager:" -ForegroundColor Yellow
    Write-Host "  winget: winget install Neovim.Neovim"
    Write-Host "  scoop : scoop install neovim"
    Write-Host "  choco : choco install neovim -y" -ForegroundColor Cyan
    exit 1
}

# --------------------------------------------------------------------------
# [2/6] Core dependencies
# --------------------------------------------------------------------------
Write-Host "[2/6] Checking core system dependencies..." -ForegroundColor Cyan

$Missing = @()
foreach ($tool in @("git", "make", "rg", "fd", "node", "python", "cargo")) {
    if (Test-Command $tool) {
        Write-Host "  [OK] $tool" -ForegroundColor Green
    } else {
        Write-Host "  [MISSING] $tool" -ForegroundColor Red
        $Missing += $tool
    }
}

if ($Missing.Count -gt 0) {
    Write-Host ""
    Write-Host ("Install the missing tools with your package manager. Examples:" ) -ForegroundColor Yellow
    Write-Host "  winget: winget install Git.Git GnuWin32.Make BurntSushi.ripgrep.MSVC sharkdp.fd"
    Write-Host "          winget install OpenJS.NodeJS.LTS Python.Python.3.12 Rustlang.Rustup"
    Write-Host "  scoop : scoop install git make ripgrep fd nodejs python rust"
    Write-Host "  choco : choco install git make ripgrep fd nodejs-lts python rust -y"
    Write-Host ""
    Write-Host "  (curl and unzip/tar ship with Windows 10+; no setup needed.)"
    Write-Host ""
    exit 1
}
Write-Host "[2/6] All core dependencies satisfied." -ForegroundColor Green

# --------------------------------------------------------------------------
# [3/6] Optional language tooling
# --------------------------------------------------------------------------
Write-Host ""
Write-Host "[3/6] Optional language tooling" -ForegroundColor Cyan
Write-Host "LeVIX has full LSP/lint/format/debug support for:"
Write-Host "Java, Python, C/C++, HTML, CSS, JavaScript/TypeScript"
Write-Host "Install support only for the languages you actually use."
Write-Host ""

$selected = @()
if (Ask-YesNo "  Install Java tooling (JDK, jdtls, checkstyle, google-java-format)? [y/N]") {
    $selected += "java"
}
if (Ask-YesNo "  Install Python tooling (ruff)? [y/N]") {
    $selected += "python"
}
if (Ask-YesNo "  Install C/C++ tooling (clang-tidy)? [y/N]") {
    $selected += "cpp"
}
if (Ask-YesNo "  Install Web Dev tooling (prettier, htmlhint, stylelint, eslint_d)? [y/N]") {
    $selected += "web"
}

foreach ($lang in $selected) {
    switch ($lang) {
        "java" {
            if (Test-Command java) {
                Write-Host "  [OK] java" -ForegroundColor Green
            } else {
                Write-Host "  [WARN] JDK not found. Install it, e.g.:"
                Write-Host "    winget: winget install Microsoft.OpenJDK.21"
                Write-Host "    scoop : scoop install openjdk"
                Write-Host "    choco : choco install microsoft-openjdk21 -y"
            }
            Write-Host "  [INFO] jdtls, checkstyle, and google-java-format auto-install via Mason on first launch."
        }
        "python" {
            if (Test-Command ruff) {
                Write-Host "  [OK] ruff" -ForegroundColor Green
            } else {
                Write-Host "  [WARN] ruff not found. Install it:"
                Write-Host "    pip install ruff"
            }
        }
        "cpp" {
            if (Test-Command clang-tidy) {
                Write-Host "  [OK] clang-tidy" -ForegroundColor Green
            } else {
                Write-Host "  [WARN] clang-tidy not found. Install it, e.g.:"
                Write-Host "    winget: winget install LLVM.LLVM"
                Write-Host "    scoop : scoop install llvm"
                Write-Host "    choco : choco install llvm -y"
                Write-Host "  (Then re-launch this installer or reopen Neovim so PATH picks it up.)"
            }
        }
        "web" {
            $WebMissing = @()
            foreach ($webTool in @("prettier", "htmlhint", "stylelint", "eslint_d")) {
                if (-not (Test-Command $webTool)) { $WebMissing += $webTool }
            }
            if ($WebMissing.Count -gt 0) {
                Write-Host "  [WARN] Missing: $($WebMissing -join ', ')"
                Write-Host "    npm install -g prettier htmlhint stylelint eslint_d"
            } else {
                Write-Host "  [OK] web tools" -ForegroundColor Green
            }
            Write-Host "  [INFO] html, cssls, and ts_ls LSP servers auto-install via Mason on first launch."
        }
    }
}
Write-Host ""

# --------------------------------------------------------------------------
# [4/6] Prepare configuration directory
# --------------------------------------------------------------------------
Write-Host "[4/6] Preparing configuration directory..." -ForegroundColor Cyan
if (Test-Path $NVIM_CONFIG_DIR) {
    $backup = "$NVIM_CONFIG_DIR.bak." + (Get-Date -Format "yyyyMMdd-HHmmss")
    Write-Host "  Found existing config. Backing up to $backup ..." -ForegroundColor Yellow
    Move-Item $NVIM_CONFIG_DIR $backup
}
Write-Host "[4/6] Directory ready." -ForegroundColor Green
Write-Host ""

# --------------------------------------------------------------------------
# [5/6] Important reminders
# --------------------------------------------------------------------------
Write-Host "[5/6] Important reminders" -ForegroundColor Cyan
Write-Host "  1. Install a Nerd Font (e.g., JetBrainsMono Nerd Font):"
Write-Host "       winget install DEVCOM.JetBrainsMonoNerdFont"
Write-Host "       scoop bucket add nerd-fonts; scoop install JetBrainsMono-NF"
Write-Host "       choco install nerd-fonts-jetbrainsmono -y"
Write-Host "     Without it, icons will appear as broken boxes."
Write-Host "  2. Set your terminal font (Windows Terminal -> Settings -> Profile) to the Nerd Font."
Write-Host "  3. After installation run:  nvim +checkhealth levix"
Write-Host "     to verify all dependencies are installed correctly."
Write-Host ""

# --------------------------------------------------------------------------
# [6/6] Clone LeVIX
# --------------------------------------------------------------------------
Write-Host "[6/6] Cloning LeVIX from GitHub..." -ForegroundColor Cyan
git clone https://github.com/Ledev0/LeVIX.git $NVIM_CONFIG_DIR
if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "==============================================================" -ForegroundColor Green
    Write-Host "  LeVIX has been successfully installed!" -ForegroundColor Green
    Write-Host "  Config location: $NVIM_CONFIG_DIR"
    Write-Host "  Just type 'nvim' in your terminal and enjoy!" -ForegroundColor Yellow
    Write-Host "==============================================================" -ForegroundColor Green
} else {
    Write-Host "  Failed to clone the repository. Check your internet connection." -ForegroundColor Red
    exit 1
}