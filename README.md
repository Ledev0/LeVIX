# LeVIX

![LeVIX Dashboard](Dashboard.png)

> A handcrafted Neovim IDE built from scratch — every line written with purpose.

![Neovim](https://img.shields.io/badge/Neovim-0.12-57A143?style=for-the-badge&logo=neovim&logoColor=white)
![Lua](https://img.shields.io/badge/Lua-2C2D72?style=for-the-badge&logo=lua&logoColor=white)
![Java](https://img.shields.io/badge/Java-ED8B00?style=for-the-badge&logo=openjdk&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)
![C](https://img.shields.io/badge/C-00599C?style=for-the-badge&logo=c&logoColor=white)
![Git](https://img.shields.io/badge/Git-F05032?style=for-the-badge&logo=git&logoColor=white)
![WSL](https://img.shields.io/badge/WSL-0078D6?style=for-the-badge&logo=linux&logoColor=white)

---

## What is LeVIX?

LeVIX is not a distribution. It's a personal Neovim configuration built from zero — no LazyVim, no NvChad, no shortcuts. Every plugin was chosen, every keymap was set, every line was written and understood.

Built by a developer learning Java, competing in Codeforces, and refusing to use an IDE he doesn't control.

---

## Features

- **LSP** - Java (jdtls), Python (pyright), C/C++ (clangd), Lua
- **Completion** - blink.cmp with LuaSnip snippets
- **Debugger** - nvim-dap with UI for Python, C/C++, Java
- **Formatter** - conform.nvim (format on save)
- **Linter** - nvim-lint (lint on save)
- **Git** - gitsigns + lazygit integration
- **Fuzzy Finder** - Telescope with fzf
- **File Explorer** - Neo-tree
- **Terminal** - Toggleterm (float, horizontal, vertical)
- **Navigation** - Harpoon, Flash.nvim
- **Sessions** - auto-session
- **UI** - Gruvbox, lualine, bufferline, noice, indent lines, colorizer
- **Competitive Programming** - code runner for Java, Python, C, C++
- **Tag Bar** - Show code outline by sidebar
- **Zen Mode** - Code Like A Ghost  (WOOH!)
---

## Structure

```
~/.config/nvim/
├── init.lua
├── lua/
│   ├── config/lazy.lua
│   ├── core/keymaps.lua
│   └── plugins/        
│       ├── breadcrumbs, colorscheme, completion, competitive
│       ├── cosmetics, debugger, effects
│       ├── formatter, git, harpoon
│       ├── indent, java-dap, linter
│       ├── lsp, navigation, rainbow, session
│       ├── tagbar, telescope, terminal, todo
│       ├── treesitter, ui, utilities
│       └── which-key, zen
```

---

## Install

```bash
# Backup your existing config
mv ~/.config/nvim ~/.config/nvim.bak

# Clone LeVIX
git clone git@github.com:Ledev0/LeVIX.git ~/.config/nvim

# Open Neovim and let lazy.nvim install everything
nvim
```

---

## Key Bindings

| Key | Action |
|-----|--------|
| `Space+ff` | Find Files |
| `Space+fs` | Search Text |
| `Space+e` | Toggle Explorer |
| `Space+gg` | LazyGit |
| `Space+rc` | Run Code |
| `Space+rf` | Run File |
| `Space+db` | Toggle Breakpoint |
| `Space+du` | Toggle Debug UI |
| `Space+ha` | Add to Harpoon |
| `Space+hh` | Harpoon Menu |
| `Space+ss` | Save Session |
| `Space+sr` | Restore Session |
| `Space+w` | Save File |
| `Space+q` | Quit |
| `Space+co` | Code Outline |
|  `Space+z` | Zen Mode |
| `F5` | Debug Continue |
| `F10` | Step Over |
| `F11` | Step Into |
| `Tab` | Next Buffer |
| `S-Tab` | Prev Buffer |

---

## Requirements

- Neovim >= 0.11
- Git, Node.js, Java (JDK 21+), Python 3, Cargo (Rust)
- A Nerd Font

---

*Built with 🔥 by [Ledev0](https://github.com/Ledev0)*
