-- Pickers respect .gitignore (no --no-ignore): venvs, caches, build outputs
-- and runtime logs are skipped via git metadata in this repo and in every
-- submodule, so no per-directory exclude list has to be maintained for them.
-- Untracked files are still searched — rg/fd only skip *ignored* paths.
-- <a-i> inside any picker toggles ignored files back on for the rare dig
-- into gitignored content; <a-h> toggles hidden files.
--
-- The explicit excludes cover what .gitignore cannot:
--  * .git itself is only reachable because hidden = true;
--  * worktree checkouts under .claude/worktrees are untracked, not ignored,
--    and appear both at the repo root and inside submodules (hence `**/`);
--  * __pycache__/.venv*/node_modules are insurance for grepping outside a
--    git repository, where rg/fd apply no ignore rules at all.
local picker_exclude = {
  ".git",
  "**/.claude/worktrees",
  "__pycache__",
  ".pytest_cache",
  ".venv*",
  "node_modules",
}

return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        sources = {
          explorer = {
            hidden = true,
            ignored = true,
            exclude = { ".git", "__pycache__", ".pytest_cache" },
            -- "." and <BS> keep the pickers' root in step with the tree:
            -- zooming also tcd-s into the directory, zooming out tcd-s back.
            -- Without this the tree and <leader><leader>/grep roots silently
            -- diverge (the stock <C-c> trap, just discovered the hard way).
            win = {
              list = {
                keys = {
                  ["."] = "explorer_focus_cd",
                  ["<BS>"] = "explorer_up_cd",
                  [","] = "explorer_back_cd",
                },
              },
            },
            actions = {
              explorer_focus_cd = function(picker)
                -- Remember where the zoom started so "," can return in one press
                -- instead of a <BS> per level (deep Java packages).
                local before = picker:cwd()
                require("snacks.explorer.actions").actions.explorer_focus(picker)
                if picker:cwd() ~= before then
                  local stack = vim.g.explorer_root_stack or {}
                  table.insert(stack, before)
                  vim.g.explorer_root_stack = stack
                end
                vim.cmd.tcd(vim.fn.fnameescape(picker:cwd()))
              end,
              explorer_up_cd = function(picker)
                require("snacks.explorer.actions").actions.explorer_up(picker)
                vim.cmd.tcd(vim.fn.fnameescape(picker:cwd()))
              end,
              explorer_back_cd = function(picker)
                local stack = vim.g.explorer_root_stack or {}
                local prev = table.remove(stack)
                vim.g.explorer_root_stack = stack
                if not prev then
                  return vim.notify("No zoom to go back from", vim.log.levels.INFO)
                end
                picker:set_cwd(prev)
                picker:find()
                vim.cmd.tcd(vim.fn.fnameescape(prev))
              end,
            },
          },
          files = {
            hidden = true,
            exclude = picker_exclude,
          },
          grep = {
            hidden = true,
            exclude = picker_exclude,
          },
        },
      },
    },
  },
}
