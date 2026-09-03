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
            exclude = { ".git", "__pycache__" },
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
