-- The default cwd/workspace/file searches run fd with -HI, which drags in
-- every bazel-bin/bazel-out interpreter inside toloka-python (26 identical
-- "workspace" rows), and they only search downward, so .venv-all at the
-- toloka-python root is invisible from a file deeper in the tree.
-- One explicit search over ~/projects/work replaces them: venvs are
-- gitignored, so -HI stays, with the noise excluded by name.
return {
  "linux-cultist/venv-selector.nvim",
  opts = {
    options = {
      enable_default_searches = false,
      picker_columns = { "marker", "search_result" },
      -- "solutions/platform/toloka-python/.venv-all" instead of a truncated
      -- absolute /bin/python path
      on_telescope_result_callback = function(filename)
        local short = filename:gsub(vim.pesc(vim.fn.expand("~/projects/work") .. "/"), "")
        return (short:gsub("/bin/python$", ""))
      end,
    },
    search = {
      work = {
        command = "$FD '/bin/python$' ~/projects/work --full-path --color never -HI -a -L --max-depth 7"
          .. " -E 'bazel-*' -E node_modules -E '.claude' -E '*.egg-info'",
      },
    },
  },
}
