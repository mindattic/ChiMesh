# ChiMesh

> **Decentralized mesh chat.** _[One-paragraph pitch TBD. This README is a content-free scaffold copied from the Claudia layout so the page styling, the build pipeline, and the deploy plumbing can all be reviewed end-to-end before real copy lands.]_

## Layout

| Path | What it is |
|------|-----------|
| `ChiMesh.md` | Markdown source of truth for the public build guide. |
| `ChiMesh.htm` | Self-contained styled page rendered from `ChiMesh.md` by `scripts/cli/build-html.js`. |
| `index.htm` | Byte-identical clone of `ChiMesh.htm` so `mindattic.com/chimesh/` serves it directly. |
| `config/parts.json` | Parts catalog feeding the shopping list. |
| `config/versions.json` | External dependency versions injected into `ChiMesh.md` at build time. |
| `scripts/cli/` | Windows-side tooling: build, bump, deploy, console launcher. |
| `scripts/pi/` | Device-side install + healthcheck scripts. |

## Build the HTML locally

```bash
npm install
npm run build:html
```

Outputs `ChiMesh.htm` (and mirrors it to `index.htm`).

## Edit + auto-rebuild

The `.claude/settings.json` `PostToolUse` hook re-runs `build-html.js` on every save to `ChiMesh.md`, so the styled page stays in sync while you edit.

## Deploy

```bash
scripts\cli\deploy.bat
```

Bumps the date stamp in `ChiMesh.md`, rebuilds, and FTPs the three files to `mindattic.com/chimesh/`. Requires `scripts/cli/deploy.settings.json` (gitignored — start from the `.template`).
