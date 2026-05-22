# ChiMesh

> **Chicago LoRa Meshtastic mesh.** A community-built LoRa mesh network for Chicago, deployed on solar-powered RAK4631 nodes in IP65 enclosures. v0 ships three nodes to prove multi-hop routing; v2 disguises them as solar wall lamps. The build guide is a single self-contained HTML page rendered from a Markdown source of truth.

## Layout

| Path | What it is |
|------|-----------|
| `ChiMesh.md` | Markdown source of truth for the public build guide. |
| `ChiMesh.htm` | Self-contained styled page rendered from `ChiMesh.md` by `scripts/cli/build-html.js`. |
| `index.htm` | Byte-identical clone of `ChiMesh.htm` so `mindattic.com/chimesh/` serves it directly. |
| `config/parts.json` | Parts catalog feeding the shopping list. Each part has tiered Official / Amazon / Reputable links plus a Google Shopping search URL. |
| `config/versions.json` | External dependency versions injected into `ChiMesh.md` at build time. |
| `scripts/cli/` | Windows-side tooling: build, bump, deploy, node provisioner, healthcheck, console launcher. |

## Build the HTML locally

```bash
npm install
npm run build:html
```

Outputs `ChiMesh.htm`. Re-copy it over `index.htm` if you want the local mirror up to date (the `deploy` script does this automatically).

## Edit + auto-rebuild

The `.claude/settings.json` `PostToolUse` hook re-runs `build-html.js` on every save to `ChiMesh.md`, so the styled page stays in sync while you edit.

## Provision a node

Once a fresh RAK4631 has been flashed via [flash.meshtastic.org](https://flash.meshtastic.org) and is plugged into USB:

```powershell
scripts\cli\provision-node.ps1 -NodeName chimesh-001
```

Sets region, role (`ROUTER_CLIENT` by default), channel, and owner. Re-running is safe. See section 05 of the guide for full flag docs.

## Healthcheck a deployed node

```powershell
scripts\cli\healthcheck-mesh.ps1
```

Queries the USB-connected node for region, role, channel, and peer count. Exits 0 on green, 1 on any failure.

## Console (interactive)

```powershell
scripts\cli\ChiMesh.Console.bat
```

Single entry point for build, deploy, parts catalog walker, and the two node scripts above. Run without arguments for a menu, or pass a command name directly:

```powershell
ChiMesh.Console build-html
ChiMesh.Console provision chimesh-001
ChiMesh.Console healthcheck
ChiMesh.Console find-deals core
```

## Deploy

```powershell
scripts\cli\deploy.bat
```

Bumps the date stamp in `ChiMesh.md`, rebuilds, mirrors to `index.htm`, and FTPs the three files to `mindattic.com/chimesh/`. Requires `scripts/cli/deploy.settings.json` (gitignored — start from the `.template`).

## What this guide IS the boilerplate for

The layout, build pipeline, parts-catalog schema, and config-widget pattern are reusable across any hardware build guide. To start a new project from this template:

1. Clone the repo as the seed.
2. Rewrite `ChiMesh.md` with the new project's sections.
3. Rewrite `config/parts.json` with the new BOM (keep the schema: `category`, `name`, `price`, `specs[]`, `searchFor`, `tiers[{tier, url}]`).
4. Update `BUILD_CONFIG_AXES` in `scripts/cli/build-html.js` with the new project's configurable axes.
5. Update `config/versions.json` with whatever upstream version labels the new project cares about.

Sections, conditional `<!-- when: key=val -->` blocks, the price-aware total, the Official/Amazon/Reputable tier system, the parts gallery, the dark/light theme toggle, the scroll-spy TOC — all of it carries over unchanged.
