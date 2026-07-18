# LeVIX

![LeVIX Dashboard](Dashboard.png)

> A handcrafted Neovim IDE built from scratch — every line written with purpose.

![Neovim](https://img.shields.io/badge/Neovim-0.12-57A143?style=for-the-badge&logo=neovim&logoColor=white)

---

## Table of Contents

- [Architecture](#architecture)
- [Languages & Toolchains](#languages--toolchains)
- [Plugins](#plugins)
- [Commands](#commands)
- [Keybindings](#keybindings)
- [Project Scaffolding](#project-scaffolding--levixnewweb)
- [Installer](#installer)
- [Dependencies](#dependencies)
- [Health Checks](#health-checks)
- [NixOS Users](#nixos-users)
- [License](#license)

---

## Architecture

### Entry Point (`init.lua`)

Loading order:

1. `core.options` — global Neovim options
2. `core.keymaps` — global keybindings
3. `config.lazy` — lazy.nvim bootstrap and plugin loading
4. `core.commands` — custom LeVIX commands and startup check

### Core Modules (`lua/core/`)

| File | Purpose |
|------|---------|
| `options.lua` | All vim.opt settings, leader key (Space), diagnostics config, translucent background, spell settings, folding disabled, theme cache restore |
| `keymaps.lua` | Global keymaps for saving, quitting, splits, buffers, terminal, telescope, gitsigns, lazygit |
| `commands.lua` | `:LeVIXUpdate`, `:LeVIXNewWeb`, startup update check |
| `levix/health.lua` | `:checkhealth levix` implementation |
| `levix/newweb.lua` | `:LeVIXNewWeb` scaffolding logic |

### Settings (`core/options.lua`)

- Leader key: Space
- Line numbers: `number` + `relativenumber`
- Clipboard: `unnamedplus` (syncs with system clipboard)
- Indentation: `tabstop=4`, `shiftwidth=4`, `expandtab`, `smartindent`
- Mouse: enabled
- Sign column: always visible
- Splits: right and below
- Termguicolors: enabled
- Undofile: enabled
- updatetime: 250ms
- timeoutlen: 300ms
- Scrolloff: 8
- Folding: disabled (`foldenable = false`)
- Background: translucent (`highlight Normal guibg=none`)
- Spell checking: enabled for markdown, text, and gitcommit (`lang: en_us`)
- Diagnostics: virtual text, signs, underline; severity-sorted; rounded float border with source
- Diagnostic signs: Nerd Font icons ( Error,  Warn,  Info,  Hint)
- Theme cache: reads `.levix_theme_cache` on startup to restore last-selected colorscheme

### Plugin Manager (`lua/config/lazy.lua`)

- lazy.nvim: bootstrapped from GitHub if not installed
- Auto-imports all plugin specs from `lua/plugins/` directory
- Default colorscheme for install phase: gruvbox
- Update checker enabled

---

## Languages & Toolchains

### Java

| Tool | Plugin |
|------|--------|
| LSP | jdtls (via `nvim-jdtls`) |
| Formatter | google-java-format (via `conform.nvim`) |
| Linter | checkstyle (via `nvim-lint`) |
| Debugger | jdtls DAP (via `nvim-jdtls`) |
| Mason packages | `jdtls`, `java-debug-adapter` (via `java-tools.lua`) |

Java configuration lives in three files:
- `lua/plugins/lsp.lua` — standard LSP servers (does NOT include jdtls)
- `lua/plugins/java-tools.lua` — ensures jdtls and java-debug-adapter are installed via Mason
- `lua/plugins/java-dap.lua` — configures nvim-jdtls: launches jdtls with project-specific workspace directory, attaches blink.cmp capabilities, sets up DAP with hot code replace

### Python

| Tool | Plugin |
|------|--------|
| LSP | pyright, ruff (both via `mason-lspconfig`) |
| Formatter | ruff_format (via `conform.nvim`) |
| Linter | ruff (via `nvim-lint`) |
| Debugger | nvim-dap-python (via `debugger.lua`) |

### C / C++

| Tool | Plugin |
|------|--------|
| LSP | clangd (via `mason-lspconfig`) |
| Formatter | clang-format (via `conform.nvim`) |
| Linter | clang-tidy (via `nvim-lint`, binary mapped via `executable_map = { clangtidy = "clang-tidy" }`) |
| Debugger | codelldb (via `mason-nvim-dap`) |

### Lua

| Tool | Plugin |
|------|--------|
| LSP | `lua_ls` (via `lazydev.nvim` for Neovim-specific annotations) |
| Formatter | stylua (via `conform.nvim`) |

### HTML

| Tool | Plugin |
|------|--------|
| LSP | html (vscode-html-language-server, via `mason-lspconfig`) |
| Formatter | prettier (via `conform.nvim`) |
| Linter | htmlhint (via `nvim-lint`) |

### CSS

| Tool | Plugin |
|------|--------|
| LSP | cssls (vscode-css-language-server, via `mason-lspconfig`) |
| Formatter | prettier (via `conform.nvim`) |
| Linter | stylelint (via `nvim-lint`) |

### JavaScript / TypeScript / JSX / TSX

| Tool | Plugin |
|------|--------|
| LSP | ts_ls (TypeScript language server, via `mason-lspconfig`) |
| Formatter | prettier (via `conform.nvim`) |
| Linter | eslint_d (via `nvim-lint`) |

### Code Runner (Competitive Programming)

The `code_runner.nvim` plugin compiles and runs code against an `input.txt` file in the same directory:

| Language | Command |
|----------|---------|
| Java | `cd $dir && javac $fileName && java $fileNameWithoutExt < input.txt` |
| Python | `python3 $file < input.txt` |
| C | `cd $dir && gcc -Wall -g $fileName -o $fileNameWithoutExt && ./$fileNameWithoutExt < input.txt` |
| C++ | `cd $dir && g++ -Wall -g -std=c++17 $fileName -o $fileNameWithoutExt && ./$fileNameWithoutExt < input.txt` |

---

## Plugins

### LSP Infrastructure

**`williamboman/mason.nvim`** — LSP/DAP/linter/formatter installer. Loaded via `:Mason` command. Rounded UI border. Custom icons for installed/pending/uninstalled.

**`williamboman/mason-lspconfig.nvim`** — Bridges Mason to lspconfig. Ensures these LSP servers are installed: pyright, clangd, ruff, html, cssls, ts_ls.

**`neovim/nvim-lspconfig`** — LSP configuration using Neovim 0.12+ native `vim.lsp.config()` and `vim.lsp.enable()`. Configures: pyright (basic type checking), ruff, clangd, html, cssls, ts_ls. Sets up `LspAttach` autocommand for buffer-local keymaps.

### Formatting

**`stevearc/conform.nvim`** — Format-on-save via `BufWritePre`. Checks formatter availability before running, shows one-time warning per formatter if missing. Falls back to LSP formatting. Manual format via `<leader>cf`.

### Linting

**`mfussenegger/nvim-lint`** — Lint-on-save via `BufWritePost` + `BufReadPost`. Checks executable availability before running, shows one-time warning per linter if missing. Manual lint via `<leader>cl`. Uses `executable_map` for linters whose binary name differs (clangtidy → clang-tidy).

### Completion

**`saghen/blink.cmp`** — Autocompletion engine. Sources: lsp, path, snippets, buffer, spell. Keymaps: Tab/S-Tab for navigation, Enter to accept, C-space to show/hide. Signature help enabled. Built with `cargo build --release` on install.

**`saghen/blink.lib`** — Native library dependency for blink.cmp.

**`L3MON4D3/LuaSnip`** — Snippet engine. Loads `friendly-snippets` from VS Code format via `lazy_load`.

**`ribru17/blink-cmp-spell`** — Spell-check completion source for blink.cmp.

### Debugging

**`mfussenegger/nvim-dap`** — Debug Adapter Protocol client. Configured adapters:
- codelldb (C/C++): server mode, port-based, executable from Mason install path
- nvim-dap-python (Python): uses `python3` executable

DAP UI (`rcarriga/nvim-dap-ui`) opens automatically on debug start, closes on termination.

**`jay-babu/mason-nvim-dap.nvim`** — Ensures `codelldb` is installed via Mason.

**`mfussenegger/nvim-dap-python`** — Python DAP adapter.

**`mfussenegger/nvim-jdtls`** — Java DAP via jdtls. Sets up DAP with hot code replace. Per-project workspace directory.

### UI

**`nvim-lualine/lualine.nvim`** — Statusline. Sections: mode, branch/diff/diagnostics, filename, encoding/filetype, progress, location. Auto theme. Nerd Font icons.

**`akinsho/bufferline.nvim`** — Tabline. Shows LSP diagnostics. Tab/S-Tab to cycle buffers. Close icons hidden.

**`stevearc/dressing.nvim`** — Replaces `vim.ui.select` and `vim.ui.input` with prettier UI. Lazy-loaded on first use via `init` hook.

**`folke/snacks.nvim`** — Dashboard with LeVIX ASCII logo. Key shortcuts: f=Find File, r=Recent Files, g=Find Text, c=Config, l=Lazy, m=Mason, q=Quit. Image support disabled. `lazy = false`, `priority = 1000`.

**`echasnovski/mini.icons`** — Icon provider.

**`nvim-tree/nvim-web-devicons`** — Icon provider (used by oil.nvim, lualine.nvim, bufferline.nvim, aerial.nvim).

### Navigation & Search

**`nvim-telescope/telescope.nvim`** — Fuzzy finder. Commands: find_files (hidden files shown, ignores node_modules/.git), live_grep, buffers, help_tags, oldfiles, colorscheme. FZF native extension with `make` build step.

**`ThePrimeagen/harpoon`** — File bookmarks. `harpoon2` branch. Quick jump via `<C-1>` through `<C-4>`.

### File Explorer

**`stevearc/oil.nvim`** — Edit filesystem as a buffer. Default file explorer. Shows hidden files. Icon column. `<leader>o` to open.

### Git

**`lewis6991/gitsigns.nvim`** — Git signs in sign column. Custom signs: ┃ add, ┃ change, _ delete, ‾ topdelete, ~ changedelete, ┆ untracked. Current line blame (500ms delay, EOL virtual text). Keymaps: ]g/[g hunk navigation, blame, preview, reset.

**Lazygit** — Integrated via toggleterm as a floating terminal. `_G.LeVIX.lazygit_toggle()` function. `<leader>gg` to toggle.

### Terminal

**`akinsho/toggleterm.nvim`** — Terminal manager. Default direction: float (rounded border). `<C-\>` mapping. Size: 20. Terminal mode keymaps: Esc to exit to normal mode, C-h/j/k/l for window navigation. Lazygit runs in a dedicated floating terminal instance.

### Sessions

**`rmagatti/auto-session`** — Session management. Auto-restore disabled by default. Suppressed dirs: `~/`, `~/Downloads`, `/`. `<leader>ss` save, `<leader>sr` restore.

### Theme Management

**`lua/plugins/themes.lua`** — Theme definitions and switcher. Available themes:
- catppuccin/nvim
- tokyonight.nvim
- gruvbox.nvim
- rose-pine/neovim
- kanagawa.nvim
- miasma.nvim
- darkvoid.nvim
- midnight.nvim

`<leader>T` opens Telescope colorscheme picker (with preview disabled) or falls back to `vim.ui.select`. Selection is saved to `.levix_theme_cache` and restored on next startup via `core/options.lua`.

### Which-Key

**`folke/which-key.nvim`** — Keybinding popup. 500ms delay. Rounded border. Defines `<leader>` group labels: f=Find/Search, g=Git, c=Code/LSP, t=Terminal, d=Debug, r=Run, m=Todos, h=Harpoon, s=Sessions.

### Treesitter

**`nvim-treesitter/nvim-treesitter`** — Syntax highlighting and text objects. `lazy = false`. Parsers installed: java, python, c, cpp, lua, bash, markdown, markdown_inline. Auto-starts Treesitter on FileType. Sets `foldexpr` and `indentexpr`.

### Zen Mode

**`folke/zen-mode.nvim`** — Distraction-free writing. `<leader>z` toggle. Width 0.99, hides signcolumn/numbers/cursorline. Disables gitsigns. Keeps tmux status line visible. Closes file tree and tagbar on open.

### Code Outline

**`stevearc/aerial.nvim`** — Code outline / tagbar. Right sidebar, width 35, shows guides. `<leader>co` toggle.

### Emmet

**`mattn/emmet-vim`** — HTML/CSS/JS abbreviation expansion. `<C-y>,` in insert mode. Filetypes: html, css, javascript, javascriptreact, typescript, typescriptreact. Loads on InsertEnter.

### Utilities

**`windwp/nvim-autopairs`** — Auto-close brackets and quotes. Checks Treesitter for context-aware behavior (skips Lua strings and Java string_literals).

**`numToStr/Comment.nvim`** — Toggle comments with `gc` (operator) / `gcc` (line).

### Visual Enhancements

**`NvChad/nvim-colorizer.lua`** — Highlights color codes in files. Supports RGB, RRGGBB, RRGGBBAA, rgb()/hsl() CSS functions. Background highlight mode.

**`folke/noice.nvim`** — Replaces Neovim UI messages with a modern command-line interface. Uses `nvim-notify` for notifications. Bottom search, command palette, long messages to split.

**`rcarriga/nvim-notify`** — Notification backend for noice.nvim. 3s timeout, compact render, deduplicates.

### Discord Rich Presence

**`vyfor/cord.nvim`** — Shows current editing activity on Discord profile. Minecraft theme, dark flavor, shows time, full view. Button links to LeVIX repository.

### WakaTime

**`wakatime/vim-wakatime`** — Automatic coding activity tracking. `lazy = false`.

### Lua Development

**`folke/lazydev.nvim`** — Provides Neovim Lua API type annotations and completion for `vim.*`, `require()`, etc. Filetype-restricted to Lua buffers.

---

## Commands

### `:LeVIXUpdate`

Runs three operations sequentially:

1. `lazy.sync({ wait = true })` — updates all lazy.nvim plugins
2. `nvim-treesitter.install.update({ with_sync = true })` — updates Treesitter parsers
3. `git pull origin main` — pulls latest LeVIX core from GitHub

### `:LeVIXNewWeb <project-name>`

Creates a frontend project scaffold. Implementation in `lua/core/levix/newweb.lua`. Steps:

1. Creates `<project-name>/` directory in current working directory
2. Copies template files from `templates/frontend/` in the LeVIX config directory:
   - Starter files: `index.html`, `style.css`, `script.js`
   - Config files: `package.json`, `.prettierrc.json`, `.eslintrc.json`, `.stylelintrc.json`, `.gitignore`
3. Validates all JSON files with `vim.fn.json_decode`
4. Validates `index.html` contains a `<!DOCTYPE>` declaration
5. Checks if `stylelint-config-standard` is installed globally (npm), warns if missing
6. Switches Neovim cwd to the new project
7. Opens Oil file explorer at the project directory
8. Prints a summary with available LeVIX features (Emmet, format, lint, LSP)

The repo's `templates/` directory is structured for future expansion:

```
templates/
├── frontend/       # Current — HTML/CSS/JS starter projects
├── backend/        # Placeholder for future backend templates
└── systems/        # Placeholder for future systems templates
```

Template contents for `templates/frontend/`:

**`index.html`** — HTML5 template with `<!DOCTYPE html>`, linked style.css and script.js, empty `<title>`.

**`style.css`** — Empty.

**`script.js`** — Empty.

**`package.json`** — Declares devDependencies: typescript, eslint, prettier, stylelint, stylelint-config-standard (all `"latest"`).

**`.prettierrc.json`** — semi=true, trailingComma=es5, singleQuote=false, printWidth=100, tabWidth=2, useTabs=false, arrowParens=always, endOfLine=lf.

**`.eslintrc.json`** — env: browser/es2021/node, extends eslint:recommended, ecmaVersion latest, sourceType module, rules: indent=2, linebreak-style=unix, quotes=double, semi=always, no-unused-vars=warn.

**`.stylelintrc.json`** — extends stylelint-config-standard.

**`.gitignore`** — node_modules/, .DS_Store, dist/, build/, *.log, .env, .env.local, .vscode/, .idea/.

### Startup Update Check

2 seconds after startup, LeVIX runs `git fetch origin main` in the config directory. If the local branch is behind, a notification is shown: `"✨ New updates available for LeVIX! Run :LeVIXUpdate to pull changes."`

---

## Keybindings

### Global Keymaps (`lua/core/keymaps.lua`)

| Key | Action | Description |
|-----|--------|-------------|
| `<leader>w` | `:write` | Save file |
| `<leader>q` | `:quit` | Quit |
| `<C-h>` | `<C-w>h` | Move to left split |
| `<C-l>` | `<C-w>l` | Move to right split |
| `<C-j>` | `<C-w>j` | Move to bottom split |
| `<C-k>` | `<C-w>k` | Move to top split |
| `<C-Up>` | `:resize -2` | Decrease window height |
| `<C-Down>` | `:resize +2` | Increase window height |
| `<C-Left>` | `:vertical resize -2` | Decrease window width |
| `<C-Right>` | `:vertical resize +2` | Increase window width |
| `J` (visual) | `:m '>+1` | Move selected line down |
| `K` (visual) | `:m '<-2` | Move selected line up |
| `p` (visual) | `"_dP` | Paste without yanking deleted text |
| `<S-l>` | `:bnext` | Next buffer |
| `<S-h>` | `:bprevious` | Previous buffer |
| `<leader>x` | `:bdelete` | Close current buffer |
| `<Esc>` | `:nohlsearch` | Clear search highlight |
| `<leader>gg` | `lua LeVIX.lazygit_toggle()` | Toggle Lazygit (floating) |

### Terminal Keymaps

| Key | Context | Description |
|-----|---------|-------------|
| `<C-\>` | Global | Toggle terminal |
| `<leader>th` | Normal | Terminal horizontal |
| `<leader>tv` | Normal | Terminal vertical (size 60) |
| `<leader>tf` | Normal | Terminal float |
| `<Esc>` | Terminal | Exit to normal mode |
| `<C-h>` | Terminal | Move to left window |
| `<C-j>` | Terminal | Move to bottom window |
| `<C-k>` | Terminal | Move to top window |
| `<C-l>` | Terminal | Move to right window |

### LSP Keymaps (set per-buffer via `LspAttach`)

| Key | Action | Description |
|-----|--------|-------------|
| `gd` | `vim.lsp.buf.definition` | Go to definition |
| `gr` | `vim.lsp.buf.references` | Go to references |
| `K` | `vim.lsp.buf.hover` | Hover documentation |
| `<leader>cr` | `vim.lsp.buf.rename` | Rename symbol |
| `<leader>ca` | `vim.lsp.buf.code_action` | Code action |
| `[d` | `vim.diagnostic.jump({ count = -1, float = true })` | Previous diagnostic |
| `]d` | `vim.diagnostic.jump({ count = 1, float = true })` | Next diagnostic |

### Find / Search (Telescope)

| Key | Description |
|-----|-------------|
| `<leader>ff` | Find files (includes hidden, excludes node_modules/.git) |
| `<leader>fs` | Live grep (search text) |
| `<leader>fb` | Find buffers |
| `<leader>fh` | Find help tags |
| `<leader>fo` | Recent files (oldfiles) |

### Git

| Key | Description |
|-----|-------------|
| `]g` | Next git hunk |
| `[g` | Previous git hunk |
| `<leader>gl` | Blame line |
| `<leader>gp` | Preview hunk diff |
| `<leader>gr` | Reset hunk |

### Code / LSP

| Key | Description |
|-----|-------------|
| `<leader>cf` | Format file (conform.nvim) |
| `<leader>cl` | Lint file (nvim-lint) |
| `<leader>co` | Toggle code outline (aerial.nvim) |

### Debug

| Key | Description |
|-----|-------------|
| `<F5>` | Continue debugger |
| `<F10>` | Step over |
| `<F11>` | Step into |
| `<F12>` | Step out |
| `<leader>db` | Toggle breakpoint |
| `<leader>du` | Toggle debug UI |

### Run

| Key | Description |
|-----|-------------|
| `<leader>rc` | Run code (code_runner.nvim) |
| `<leader>rf` | Run file |
| `<leader>ri` | Open input.txt |

### Harpoon

| Key | Description |
|-----|-------------|
| `<leader>ha` | Add file to harpoon list |
| `<leader>hh` | Show harpoon menu |
| `<C-1>` | Go to file 1 |
| `<C-2>` | Go to file 2 |
| `<C-3>` | Go to file 3 |
| `<C-4>` | Go to file 4 |

### Sessions

| Key | Description |
|-----|-------------|
| `<leader>ss` | Save session |
| `<leader>sr` | Restore session |

### Todos

| Key | Description |
|-----|-------------|
| `<leader>mt` | Search project todos (Telescope) |
| `<leader>ml` | List local todos (quickfix list) |

### Theme

| Key | Description |
|-----|-------------|
| `<leader>T` | Switch theme (Telescope picker or vim.ui.select) |

### Navigation

| Key | Description |
|-----|-------------|
| `<leader>o` | Open Oil file explorer |
| `<leader>z` | Toggle zen mode |
| `<Tab>` | Next buffer (bufferline) |
| `<S-Tab>` | Previous buffer (bufferline) |

### Emmet (Insert Mode)

| Key | Description |
|-----|-------------|
| `<C-y>,` | Expand Emmet abbreviation |

### Which-Key Group Labels

| Prefix | Group Name |
|--------|------------|
| `<leader>f` | Find/Search |
| `<leader>g` | Git Engine |
| `<leader>c` | Code/LSP |
| `<leader>t` | Terminal Management |
| `<leader>d` | Debug |
| `<leader>r` | Run |
| `<leader>m` | Todo Tags |
| `<leader>h` | Harpoon Jump |
| `<leader>s` | Sessions Management |

---

## Installer

`install.sh` is a standalone shell script that handles fresh installation and upgrades.

### Upgrade Mode

If `~/.config/nvim/.git` exists, the script runs:
1. `git pull origin main`
2. `nvim --headless "+Lazy! sync" +qa`
Then exits without reinstalling.

### Fresh Install Mode

**Distro Detection**

| Distro | Package Manager |
|--------|----------------|
| Arch Linux | `sudo pacman -Sy --needed --noconfirm` |
| Debian / Ubuntu | `sudo apt update; sudo apt install -y` |
| Fedora | `sudo dnf install -y` |
| Void Linux | `sudo xbps-install -S -y` |
| Unrecognized | Falls back to AppImage |

**Neovim Installation**

1. Checks if `nvim` is in PATH
2. If not found or version < 0.12.0, installs via distro package manager
3. For Debian/Ubuntu: uses the official Neovim PPA (`ppa:neovim-ppa/stable`); if PPA build is still < 0.12, falls back to AppImage
4. For Fedora, Arch, Void: uses distro package directly
5. AppImage fallback: downloads from GitHub releases, installs to `/usr/local/bin/nvim`

**Core Dependencies**

All installed via distro package manager if missing:

| Binary | Package Name |
|--------|-------------|
| git | git |
| make | make |
| unzip | unzip |
| curl | curl |
| rg | ripgrep |
| fd | fd-find (Debian/Fedora/Void), fd (Arch) |
| node | nodejs |
| python3 | python3 (Debian/Fedora/Void), python (Arch) |
| cargo | cargo |

**Optional Language Tooling**

The installer prompts interactively for each language:

| Language | Tools Installed |
|----------|----------------|
| Java | JDK 21 (distro-specific package), jdtls/checkstyle/google-java-format install automatically via Mason on first launch |
| Python | ruff (via distro package manager or `pip install --user`) |
| C/C++ | clang-tools-extra (distro-specific: clang-tidy, clang-format) |
| Web Dev | prettier, htmlhint, stylelint, eslint_d (via `npm install -g`) |

**Backup**

Existing `~/.config/nvim` is moved to `~/.config/nvim.bak.<timestamp>` before cloning.

---

## Dependencies

### Required System Tools

| Tool | Purpose |
|------|---------|
| Neovim >= 0.12 | Core editor |
| git | lazy.nvim plugin manager, LeVIX updates |
| ripgrep (rg) | Telescope live grep |
| fd (fd-find on Debian/Fedora/Void, fd on Arch) | Telescope file finding |
| curl | mason.nvim downloads |
| make | Treesitter parser compilation |
| cargo | blink.cmp native fuzzy matcher build |
| Nerd Font | UI icons (statusline, bufferline, signs, dashboard) |
| unzip | Mason downloads |

### Per-Language Runtime Dependencies

| Language | Runtime | Tools |
|----------|---------|-------|
| Java | JDK >= 17 | jdtls, checkstyle, google-java-format (via Mason) |
| Python | Python 3 | ruff |
| C/C++ | gcc/g++ | clang-tidy, clang-format (via system package), codelldb (via Mason) |
| JavaScript/TypeScript | Node.js / npm | prettier, htmlhint, stylelint, eslint_d (`npm install -g`) |
| Lua | | stylua (via Mason) |
| HTML | | prettier, htmlhint |
| CSS | | prettier, stylelint |

### Gitignored Files

Listed in `.gitignore`:
- `lazy-lock.json` — plugin lockfile (regenerated by lazy.nvim)
- `.levix_theme_cache` — user theme preference
- `.github/` — GitHub-specific files (copilot-instructions.md)

---

## Health Checks

Run `:checkhealth levix` (implemented in `lua/core/levix/health.lua`).

Checks four categories:

### Core Tools
- git, rg, fd, curl

### Language Tooling
- java (JDK >= 17), python3, ruff, gcc, g++, clang-tidy

### Web Development Tools
- prettier, htmlhint, stylelint, eslint_d

### Build Requirements
- cargo (blink.cmp), make (Treesitter)

### Runtime
- Neovim version >= 0.12

---

## NixOS Users

LeVIX works on NixOS, but Mason-installed binaries (LSP servers, debuggers, formatters) require `nix-ld` to function because they are dynamically linked against FHS paths that do not exist on NixOS by default.

### Required Configuration

Add to your `configuration.nix`:

```nix
{
  programs.nix-ld.enable = true;
}
```

After applying (`sudo nixos-rebuild switch`), restart your shell and launch Neovim. Mason-installed binaries (jdtls, codelldb, pyright, clangd, etc.) will then resolve their shared library dependencies.

### Troubleshooting Mason Binaries

If a Mason-installed tool fails with "cannot execute" or "no such file or directory":

1. Find the binary path (e.g., `~/.local/share/nvim/mason/bin/jdtls`)
2. Run `ldd <path>` to identify missing shared libraries
3. Use `nix-locate <library>.so` to find which Nix package provides the missing library
4. Add the required packages to `environment.systemPackages` or use `nix-ld.libraries`

---

## License

MIT — see LICENSE file.

Built with fire by Seif Amr (Ledev0)
