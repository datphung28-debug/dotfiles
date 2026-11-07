# Personal snippets (LuaSnip, Lua format)

Files here are named after the filetype they belong to, e.g. `lua.lua`,
`typescript.lua`, `markdown.lua`. A file called `all.lua` is available in
every filetype.

Each file returns a table with two optional keys, `snippets` and
`autosnippets`:

```lua
-- lua/snippets/lua.lua
return {
  snippets = {
    s({ trig = "req", dscr = "require module" }, {
      t('local '),
      i(1, "module"),
      t(' = require("'),
      rep(1),
      t('")'),
    }),
  },
  autosnippets = {},
}
```

`t` (text), `i` (insert node), `c` (choice), `f` (function), `d` (dynamic),
`rep` (repeat insert) etc. are available in this file's environment without
requiring them. Reload with `:LuaSnipEdit` or `:lua require("luasnip.loaders.from_lua").load()`.

VSCode-style snippets from `friendly-snippets` are loaded automatically, no
file needed here.
