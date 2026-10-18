local mappings = {
  { "<leader>ce", "expandMacro", "Rust: Expand Macro" },
  { "<leader>cu", "runnables", "Rust: Run Target" },
  { "<leader>ct", "testables", "Rust: Run Tests" },
  { "<leader>cb", "debuggables", "Rust: Debug Target" },
}

for _, mapping in ipairs(mappings) do
  vim.keymap.set("n", mapping[1], "<cmd>RustLsp " .. mapping[2] .. "<cr>", {
    buffer = true,
    desc = mapping[3],
  })
end
