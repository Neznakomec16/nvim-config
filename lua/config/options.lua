-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt.scrolloff = 8 -- keep more context above/below the cursor (LazyVim default is 4)

-- Every "root-scoped" feature (file picker, grep, explorer, statusline root) uses the
-- directory nvim was started in, never the LSP/.git root of the current buffer. Without
-- this, editing a file under platform/* (git submodules with their own .git) silently
-- re-roots pickers into the submodule.
vim.g.root_spec = { "cwd" }

-- VS Code config files are JSONC (comments, trailing commas); with plain `json` jsonls
-- flags every comment with "Comments are not permitted in JSON".
vim.filetype.add({
  pattern = {
    [".*/%.vscode/[^/]+%.json"] = "jsonc",
  },
})

-- basedpyright adds some Pylance-parity features on top of open-source pyright
-- (e.g. richer completions) that plain pyright doesn't implement.
vim.g.lazyvim_python_lsp = "basedpyright"

-- Heap headroom for node-based language servers (basedpyright, vtsls): the
-- monorepo pushed basedpyright past node's default ~4GB old-space ceiling —
-- lsp.log showed it dying of "JavaScript heap out of memory" every few
-- minutes, which surfaced as gd/hover intermittently returning nothing.
-- Set via vim.env (inherited by every process nvim spawns) rather than the
-- server spec's cmd_env, because venv-selector overwrites cmd_env on venv
-- activation. It is a ceiling, not an allocation — harmless for small tools.
vim.env.NODE_OPTIONS = (vim.env.NODE_OPTIONS or "") .. " --max-old-space-size=8192"
