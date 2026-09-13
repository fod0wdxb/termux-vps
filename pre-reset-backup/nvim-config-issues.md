# Neovim Config Audit — Existing Issues Only

**Config audited:** `/root/.config/nvim` (identical to `~/livipi-nvim`, only `lazy-lock.json` differs)
**Date (UTC):** 2026-09-12
**Nvim:** `v0.13.0-dev-1596+g28ff47b8a4`
**Scope:** existing config only, checked against `:help`, Nvim nightly runtime source, and installed plugin docs in `~/.local/share/nvim/lazy/`. No new features suggested.
**Result:** startup clean (`nvim --headless -c 'qa!'` exit 0), 5 real issues + 3 low-severity notes.

---

## Summary

| # | Severity | Where | What |
|---|----------|-------|------|
| 1 | high | `lua/plugins/format.lua:35,37-49` | `FormatDisable/Enable` dead — `format_on_save` static table never checks `disable_autoformat` |
| 2 | medium | `lua/config/keymaps.lua:38-39` | deprecated `vim.diagnostic.goto_prev/next`, duplicates built-in `[d`/`]d` |
| 3 | medium | `lua/plugins/git.lua:19-20` | deprecated `gitsigns.next_hunk/prev_hunk`, should be `nav_hunk()` |
| 4 | medium | `lua/plugins/harpoon.lua:8` | `opts.menu.width` dead — harpoon2 has no `menu` key (harpoon1 leftover) |
| 5 | high | `lua/plugins/dap.lua:12` | `ensure_installed={"js-debug-adapter"}` never installs — expects DAP name `"js"` |
| N1 | low | `lua/config/autocmds.lua:37-44` | redundant LSP maps duplicating Nvim 0.11+ defaults |
| N2 | low | `harpoon.lua:<leader>h` vs `git.lua:<leader>hs/hr/hp/hb` | bare `<leader>h` is prefix of others → `timeoutlen` delay |
| N3 | low | `lua/plugins/treesitter.lua:33` + `lua/config/options.lua:56-57` | duplicate fold setup, harmless |

---

## 1. `lua/plugins/format.lua:35` — `FormatDisable` / `FormatEnable` do nothing

**File:** `lua/plugins/format.lua:35,37-49`

**Current:**
```lua
format_on_save = { timeout_ms = 500, lsp_format = "fallback" },
-- ...
vim.api.nvim_create_user_command("FormatDisable", function(args)
  if args.bang then vim.b.disable_autoformat = true
  else vim.g.disable_autoformat = true end
end, { desc = "Disable autoformat-on-save", bang = true })
```

**Docs:** `~/.local/share/nvim/lazy/conform.nvim/doc/recipes.md:50,86-109` — `AUTOFORMAT` + `Command to toggle format-on-save`. `format_on_save` must be a function that checks the vars and returns `nil`/table.

**Issue:** commands set `vim.g/b.disable_autoformat` but static table never reads them, so autoformat cannot be disabled.

**Fix (existing behavior only):**
```lua
format_on_save = function(bufnr)
  if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then return end
  return { timeout_ms = 500, lsp_format = "fallback" }
end,
```

---

## 2. `lua/config/keymaps.lua:38-39` — deprecated diagnostic jump

**File:** `lua/config/keymaps.lua:38-39`
```lua
map("n", "[d", vim.diagnostic.goto_prev, { desc = "Prev diagnostic" })
map("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
```

**Docs:**
- `runtime/lua/vim/diagnostic.lua:541,641` — `---@deprecated` for both, wrapper around `_jump.goto_prev/next`.
- `runtime/lua/vim/_core/defaults.lua` — Nvim 0.11+ already maps `[d`/`]d` to `vim.diagnostic.jump({count=±vim.v.count1})`.

**Issue:** deprecated calls (will warn on `:checkhealth vim.deprecated`) and overrides built-in defaults with same keys.

**Fix:**
```lua
map("n", "[d", function() vim.diagnostic.jump({ count = -vim.v.count1 }) end, { desc = "Prev diagnostic" })
map("n", "]d", function() vim.diagnostic.jump({ count = vim.v.count1 }) end, { desc = "Next diagnostic" })
```

---

## 3. `lua/plugins/git.lua:19-20` — deprecated gitsigns navigation

**File:** `lua/plugins/git.lua:19-20`
```lua
map("n", "]h", gs.next_hunk, "Next hunk")
map("n", "[h", gs.prev_hunk, "Prev hunk")
```

**Docs:**
- `~/.local/share/nvim/lazy/gitsigns.nvim/lua/gitsigns/actions.lua:564,586` — `---@deprecated use [[gitsigns.nav_hunk()]]` for both.
- `~/.local/share/nvim/lazy/gitsigns.nvim/README.md:230-244` suggested example uses `gitsigns.nav_hunk('next'/'prev')` with `vim.wo.diff` guard.

**Fix:**
```lua
map("n", "]h", function() gs.nav_hunk("next") end, "Next hunk")
map("n", "[h", function() gs.nav_hunk("prev") end, "Prev hunk")
```

---

## 4. `lua/plugins/harpoon.lua:8` — `menu.width` has no effect

**File:** `lua/plugins/harpoon.lua:7-10`
```lua
opts = {
  menu = { width = vim.api.nvim_win_get_width(0) - 4 },
  settings = { save_on_toggle = true },
},
```

**Docs:**
- `~/.local/share/nvim/lazy/harpoon/lua/harpoon/config.lua:merge_config` + `get_default_config` — valid top keys are `settings`, `default`, `[list-name]`. Unknown `menu` becomes a list named `"menu"`, never read as UI width.
- `~/.local/share/nvim/lazy/harpoon/lua/harpoon/ui.lua:toggle_config` — width controlled per-toggle via `ui_width_ratio / ui_max_width / ui_fallback_width` passed to `toggle_quick_menu(list, opts)`.
- `README.md` has no `menu.width` (harpoon1 option).

**Issue:** dead option, likely carried over from harpoon1. UI uses defaults regardless.

**Fix:** remove `menu = {...}`. If custom width wanted, pass at toggle time (not added here per no-new-feat scope).

---

## 5. `lua/plugins/dap.lua:12` — wrong `ensure_installed` identifier

**File:** `lua/plugins/dap.lua:11-14`
```lua
opts = {
  ensure_installed = { "js-debug-adapter" },
  automatic_installation = { exclude = { "chrome" } },
},
```

**Docs:**
- `~/.local/share/nvim/lazy/mason-nvim-dap.nvim/README.md` example: `ensure_installed = { "python", "delve" }` — DAP adapter names, with note: “uses the `dap` adapter names … not `mason.nvim` package names.”
- `lua/mason-nvim-dap/mappings/source.lua:15` — `['js'] = 'js-debug-adapter'`.
- `lua/mason-nvim-dap/ensure_installed.lua:resolve_package` — looks up `nvim_dap_to_package[adapter_name]`. `"js-debug-adapter"` → `nil` → `if_present` does nothing, silently installs nothing.

**Fix:**
```lua
ensure_installed = { "js" },
```

---

## Notes (not bugs, verified)

- **N1 `lua/config/autocmds.lua:37-44`:** `K`, `gI/gy`, `<leader>ca/cr` duplicate Nvim 0.11+ defaults (`K` hover buffer-local, `gri/grt`, `gra/grn` global) per `:h lsp-defaults` + `runtime/lua/vim/_core/defaults.lua:212-232`. Harmless, `gd` custom is fine (no default `gd`).
- **N2 prefix collision:** `<leader>h` (Harpoon menu) is prefix of `<leader>hs/hr/hp/hb` (gitsigns). Works but waits `timeoutlen=300` (`lua/config/options.lua:30`). Other prefixes (`<leader>f/s/d/c/t/b/g`) have no bare mapping, so OK.
- **N3 fold duplication:** `treesitter-modules fold.enable=true` already sets `vim.wo.foldmethod/foldexpr` per its `README`, same as manual `o.foldmethod/foldexpr` in `options.lua:56-57`. Harmless redundancy.

## Verified OK (no issue)

- `o.winborder="rounded"`, `o.completeopt={menuone,noselect,popup}`, `o.confirm`, `o.laststatus=3` + `lualine.globalstatus`, `vim.g.loaded_*=0` per `provider.txt`, `lazy rocks.enabled=false`, `oil.lazy=false` per oil `README`, `blink version=1.*` (=`v1.10.2`), `fuzzy=prefer_rust_with_warning`, `mason-lspconfig.automatic_enable=true`, `vim.lsp.config("*",capabilities)` per `:h vim.lsp.config()`, `snacks zen.win.width=0` (=full width per `docs/zen.md`), `conform mode=""` (verified multi-mode, `mode_bits=71`), `which-key.show({global=false})`, `TodoQuickFix`, `Diffview*`, `DBUIToggle`, treesitter parser list all installed in `~/.local/share/nvim/site/parser/`, Harpoon loop closure (tested `1→1,2→2,3→3`), terminal `<Cmd>` maps valid.
