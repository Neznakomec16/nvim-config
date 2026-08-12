# nvim

Personal Neovim config, based on [LazyVim](https://github.com/LazyVim/LazyVim).
Lives at `~/.config/nvim` and is used on macOS and Linux.

## Requirements

- Neovim >= 0.11 (`nvim-dap-view` needs it; developed on 0.12)
- Enabled LazyVim extras are listed in `lazyvim.json`

## Layout

```
init.lua              bootstraps lua/config/lazy.lua
lazy-lock.json        pinned plugin revisions — keep it committed
lazyvim.json          enabled LazyVim extras
lua/config/           options, keymaps, autocmds, lazy bootstrap
lua/plugins/          one file per plugin override
```

## Rolling back plugin versions

`lazy-lock.json` is tracked on purpose: it is the only way back after an
unwanted plugin update.

```sh
git log --oneline -- lazy-lock.json
git checkout <sha> -- lazy-lock.json
nvim --headless "+Lazy! restore" +qa
```

Install newly added plugins with `Lazy! install`, not `Lazy! sync` — sync also
updates everything else and rewrites the lock file.

## Notes

- **Debug UI** is `nvim-dap-view` (single bottom window with winbar tabs), not
  `nvim-dap-ui`, whose left sidebar competed for screen edges with the snacks
  explorer and the overseer task list. See `lua/plugins/dap.lua`.
- **Modified F-keys** arrive in two encodings depending on how the terminal and
  tmux deliver them (`<S-F5>` or the legacy high F-numbers F17/F23/F29/F41), so
  debug mappings are registered under both.
- **Treesitter highlighting in the dap REPL** needs a one-time install on a
  fresh machine:

  ```vim
  :lua require("nvim-dap-repl-highlights").setup()
  :lua require("nvim-treesitter").install({ "dap_repl" })
  ```

- `.stignore` is committed here because Syncthing does not sync that file
  itself. `.git` is listed in it, so repository state is never synced between
  machines — use git remotes for that.
