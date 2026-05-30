Deploy the ChiMesh landing page (`mindattic.com/chimesh.htm`) via **MindAttic.Deploy** (sibling repo at `D:\Projects\MindAttic\MindAttic.Deploy`).

This now uses the standard catalog pipeline: `README.md` is rendered through `template/index.template.htm` with the `Hardware` theme and FTPS-uploaded as a single file. The old 3-file long-form-guide pipeline (`scripts/cli/deploy.ps1` + marker-block splicing + `/chimesh/` subfolder) is retired.

Run this command and report the result:

```
powershell -NoProfile -ExecutionPolicy Bypass -Command "cd D:\Projects\MindAttic\MindAttic.Deploy; npm run deploy -- --only chimesh"
```

It will:

1. Render `D:\Projects\MindAttic\ChiMesh\README.md` through the catalog template (Hardware theme, MindAttic.UIUX components loaded via jsDelivr).
2. Augment the rendered HTML from `config/parts.json` (see "Parts configurator" below).
3. FTPS-upload `out/chimesh.htm` to `/mindattic.com/chimesh.htm`.

After running, summarize the result and flag any failures.

Notes:
- Catalog entry: `MindAttic.Deploy/projects.json` -> `projects[]` slug `chimesh` (theme: Hardware).
- Credentials: `MindAttic.Deploy/secrets/ftp.json` (gitignored).

## Parts configurator + cost calculator

`MindAttic.Deploy/src/parts.js` runs automatically during the build for any project whose sibling repo has a `config/parts.json` (ChiMesh and Claudia today). It post-processes the rendered README and fills three author-placed markers:

- `<!-- CONFIG-WIDGET -->` -> the interactive build picker, generated from the `configAxes` array in `config/parts.json` (region / role / deployment / antenna). Choices persist in `localStorage` under `chimesh-build-config`.
- `<!-- PARTS-GALLERY -->` -> the parts cards (grouped by category, per-part `imageFile` base64-inlined) plus the live **Your build estimate** total. The total sums `data-price` over visible core cards; `consumable` / `tools` parts carry `"inTotal": false` and are excluded.
- `<!-- when: key=value; ... -->` ... `<!-- end -->` -> conditional blocks shown/hidden as the picker changes. Keys/values must match `configAxes` values exactly (e.g. `deployment=rooftop`, `role=client`, `antenna=fiberglass8`). Nested `when` blocks ARE supported (a stack-based scanner pairs each `<!-- end -->` with the nearest unclosed `when`).

To change the parts, prices, picker options, or conditional copy, edit `config/parts.json` and `README.md` in this repo — the next `/deploy` regenerates everything. The CSS/JS are injected via the template's `{{EXTRA_STYLE}}` / `{{EXTRA_SCRIPTS}}` placeholders and use the Hardware theme's CSS variables, so the widgets track light/dark automatically.
- `scripts/cli/` now holds only live node/parts tooling (`provision-node`, `healthcheck-mesh`, `find-deals`/`list-parts` via `ChiMesh.Console`, `pull-latest`). The old local build/FTP pipeline (`build-html*`, `bump-version*`, `deploy.ps1`) has been removed -- deploys run only through MindAttic.Deploy.
- Old subfolder URL `mindattic.com/chimesh/` still exists on the FTP server until you manually delete it.
