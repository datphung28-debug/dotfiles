# cssclass

A tiny, local [blink.cmp](https://github.com/Saghen/blink.cmp) source that
suggests **CSS class names** and **ids** used in the current project, while you
type selectors (or `class="..."` attributes).

```
/* styles.css */
.bt|            ->  .btn, .btn-primary, .btn-secondary, ...
#su|            ->  #submit-btn, #submit-icon, ...
.btn:ho|        ->  (no suggestions, it is a pseudo class)
color: .|       ->  (no suggestions, it is a value)
@apply bt|      ->  btn, btn-primary, ...            (Tailwind)
```

```html
<div class="bt|">   <!-- also works inside markup attributes -->
<div id="su|">
```

## How it works

`cssclass.scanner` walks the project root once and collects values of
`class`, `className`, `:class`, `v-bind:class`, `[class]`, `ng-class`,
`class:list`, `id`, `:id`, ... from:

- `*.html`, `*.htm`, `*.xhtml`, `*.vue`, `*.svelte`, `*.astro`, `*.php`,
  `*.jsx`, `*.tsx`, `*.js`, `*.ts`, `*.md`, `*.mdx`, `*.erb`, `*.ejs`,
  `*.hbs`, `*.twig`, `*.liquid`, `*.njk`, `*.heex`, `*.templ`
- while skipping `node_modules`, `.git`, `dist`, `build`, `vendor`, `target`, ...

The result is grouped by filetype, sorted by usage count and cached in memory.
`cssclass.source` turns it into blink.cmp completion items with an explicit
`textEdit`, so only the text after `.` / `#` is replaced.

## Setup

Already wired in `lua/plugins/completion.lua`:

```lua
require("cssclass").setup()

require("blink.cmp").setup({
  sources = {
    default = { "lsp", "path", "snippets", "buffer", "cssclass" },
    providers = {
      cssclass = {
        name = "CSS Class",
        module = "cssclass.source",
        score_offset = 10,
      },
    },
  },
})
```

## Options

```lua
require("cssclass").setup({
  -- filetypes where `.foo` / `#foo` are completed
  filetypes = { "css", "scss", "sass", "less", "stylus", "postcss", "pcss" },

  -- filetypes where class="..." / id="..." values are completed
  markup_filetypes = { "html", "vue", "svelte", "javascriptreact", ... },
  markup_attributes = true, -- set false to only complete CSS selectors

  -- scanned file extensions and skipped directories
  extensions = { "html", "vue", "svelte", "jsx", "tsx", ... },
  ignore_dirs = { "node_modules", "dist", "build", ... },

  -- scan limits (keep the first scan fast on huge repositories)
  max_files = 600,
  max_file_size = 1024 * 1024,
  max_total_bytes = 16 * 1024 * 1024,
  max_depth = 20,
  max_entries = 4000, -- unique class names / ids per kind

  -- 0 = cache until a markup file is written / :CssClassRefresh
  -- >0 = also expire after N milliseconds
  cache_ttl = 0,

  -- override project root detection
  get_root = function(bufnr) return vim.fn.getcwd() end,
})
```

## Commands

| Command | Description |
| --- | --- |
| `:CssClassRefresh` | drop the cache; the project is rescanned on next completion |
| `:CssClassList` | put detected classes/ids (with usage counts) into the quickfix list |

## Project root detection

The project is scanned from the first directory found by:

1. your `get_root` override (if set),
2. the nearest ancestor containing a marker: `.git`, `package.json`,
   `composer.json`, `vite.config.js`, `vite.config.ts`, `tsconfig.json`,
   `pyproject.toml`, `Cargo.toml`, `go.mod`, `Gemfile`, `mix.exs`,
3. the nearest ancestor that directly contains markup files
   (`index.html`, `*.vue`, `*.svelte`, ...). This is what makes
   `css/style.css` work in a plain project with no `.git` / `package.json`,
4. the working directory if the file lives inside it,
5. the file's own directory.

The result is cached per directory, so `css/style.css` and `index.html` at the
project root share the same cache/scan.

## Cache invalidation

- After saving a scanned file (`BufWritePost`).
- When Neovim regains focus (`FocusGained`) — picks up `git pull`, other editors…
- When the working directory changes.
- On `cache_ttl` expiry, if you set a non-zero value.

## Notes

- Classes/ids are only collected from markup; CSS files themselves are not
  scanned (so a selector that exists only in CSS is not suggested back to you).
- Multi-line attribute values and unquoted values are ignored.
- Symlinked files/directories are skipped to avoid loops.
