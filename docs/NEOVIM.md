# Neovim modular architecture

## Overview

Neovim config lives in `nvim/` (modular Lua) with `nvim.local` as the
entrypoint. It sources the legacy `~/.vimrc` first (preserving old keymaps
and settings from `vimrc.local`), then bootstraps the Lua module system.

```
nvim.local                    → ~/.config/nvim/init.vim (entrypoint)
  ├── sources ~/.vimrc        → legacy vim settings + vimrc.local
  └── lua require('maxbeizer')
        └── nvim/lua/maxbeizer/
              ├── init.lua        → bootstrap lazy.nvim, load core + plugins
              ├── core/
              │   ├── options.lua   → vim options, codespace PATH guards
              │   ├── keymaps.lua   → leader mappings, telescope, nvim-tree
              │   └── autocmds.lua  → yank highlight, whitespace trim, ALE clear
              └── plugins/
                  ├── init.lua      → imports editor + lsp plugin specs
                  ├── editor.lua    → treesitter, telescope, nvim-tree, copilot, etc.
                  └── lsp.lua       → mason, nvim-lspconfig, nvim-cmp, LSP servers
```

## Plugin management

Uses [lazy.nvim](https://github.com/folke/lazy.nvim). It auto-bootstraps on
first run (clones itself into `~/.local/share/nvim/lazy/`). Plugin specs live
in `plugins/*.lua` and are imported via `{ import = 'maxbeizer.plugins' }`.

## LSP configuration (nvim 0.11+)

Uses **native `vim.lsp.config()` + `vim.lsp.enable()`** instead of the
deprecated `lspconfig[server].setup()` pattern. Servers configured:

| Server     | When enabled                                       |
|------------|----------------------------------------------------|
| lua_ls     | Always                                             |
| ts_ls      | Always                                             |
| gopls      | Always                                             |
| solargraph | `solargraph` or `bin/solargraph` is executable     |
| sorbet     | `.vscode/run-sorbet` exists (gh/gh) OR `srb` found |

### Sorbet in gh/gh codespaces

When `.vscode/run-sorbet` is detected, Sorbet LSP is configured with:
```lua
cmd = { 'env', 'SRB_SKIP_GEM_RBIS=1', '.vscode/run-sorbet', '--lsp' }
```
This skips gem RBI generation (slow) and uses the repo's wrapper script.

## Codespace-specific guards

All codespace-only behavior is **conditional** and safe to run locally:

- **Vendored Node PATH** (`options.lua`): Only activates if
  `/workspaces/github/vendor/node` exists. Ensures copilot.vim and npm
  find the modern Node (v24) instead of the system Node 10.
- **`g:copilot_node_command`**: Points copilot.vim at the vendored Node.
- **`g:copilot_npx = false`**: Uses the bundled language server instead
  of fetching from the GitHub npm registry (which needs auth).
- **ALE augroup clear** (`autocmds.lua`): The base vimrc sets up ALE
  `CursorHold` autocmds that error when ALE isn't loaded via vim-plug.
  Clearing the augroup is a no-op if ALE was never loaded.

## Colorscheme

NeoSolarized, defaults to dark. Toggle with `,bg`.

## Key mappings (Neovim-specific)

| Mapping       | Action                    |
|---------------|---------------------------|
| `,f`          | LSP format                |
| `,bg`         | Toggle dark/light         |
| `gd`          | Go to definition          |
| `K`           | Hover docs                |
| `gi`          | Go to implementation      |
| `gr`          | References                |
| `,vca`        | Code action               |
| `,vrn`        | Rename symbol             |
| `,vws`        | Workspace symbol search   |
| `Ctrl-h` (i)  | Signature help            |
| `[d` / `]d`   | Prev/next diagnostic      |
| `,vd`         | Open diagnostic float     |
| `Ctrl-p`      | Find files (telescope)    |
| `Ctrl-t`      | Buffers (telescope)       |
| `Ctrl-n`      | Toggle file tree          |

Legacy vim mappings from `vimrc.local` (pry, debugger, fugitive, etc.)
are preserved via `source ~/.vimrc` in the entrypoint.
