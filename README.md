# ChiMesh

**Off-grid Chicago. A solar-powered LoRa mesh that runs without the internet, the grid, or anyone's permission.**

ChiMesh is a community-built LoRa Meshtastic network for Chicago, deployed on solar-powered RAK4631 nodes in IP65 enclosures. v0 ships three nodes to prove multi-hop routing across neighborhoods. v2 disguises them as solar wall lamps so they can hide in plain sight on alley walls, back fences, and rooftops. No SIM, no Wi-Fi, no cloud — just sub-GHz radio, sunlight, and the protocol.

The build guide is a single self-contained HTML page rendered from a Markdown source of truth — same toolchain as Claudia, same `build-html.js`, same FTP deploy.

**Why ChiMesh:**

- **Truly off-grid.** Each node is a LiFePO4 battery, a 5W panel, and an RAK4631 in IP65. No external power, no SIM, no internet uplink.
- **Hardware that hides.** v2's enclosure looks like a generic solar wall lamp — the entire project is a mesh of nodes nobody notices.
- **Self-contained guide.** One Markdown file builds one HTML file. No CMS, no static site generator, no `npm run dev` server. Open `ChiMesh.htm` and you have the entire build guide, offline.
- **Tiered shopping links.** Every part in the BOM has Official / Amazon / Reputable links plus a Google Shopping search URL — so an out-of-stock primary source never blocks a build.
- **Save-to-rebuild.** A Claude Code `PostToolUse` hook re-runs `build-html.js` on every save to `ChiMesh.md`, so the styled page stays in sync while you edit.
- **Boilerplate for other hardware builds.** Layout, build pipeline, parts schema, and config-widget pattern carry over unchanged to any sibling hardware-build site.

---

## Table of Contents

- [Layout](#layout)
- [Build the HTML locally](#build-the-html-locally)
- [Edit + auto-rebuild](#edit--auto-rebuild)
- [Provision a node](#provision-a-node)
- [Healthcheck a deployed node](#healthcheck-a-deployed-node)
- [Console (interactive)](#console-interactive)
- [Deploy](#deploy)
- [Stack](#stack)
- [What this guide IS the boilerplate for](#what-this-guide-is-the-boilerplate-for)

---

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

## Stack

| Layer | Technology |
|---|---|
| **Hardware** | RAK4631 (nRF52840 + SX1262 LoRa) on RAK19007 baseboard, IP65 enclosure, 5W solar panel, LiFePO4 battery |
| **Firmware** | [Meshtastic](https://meshtastic.org/) (flashed via flash.meshtastic.org) |
| **Build pipeline** | Node.js + [marked@4](https://github.com/markedjs/marked) + [highlight.js@11](https://highlightjs.org/) — `scripts/cli/build-html.js` renders `ChiMesh.md` into a single self-contained HTML file |
| **Provisioning** | Windows PowerShell over USB serial (`meshtastic-cli`) |
| **Deploy** | FTPS via `curl` to `mindattic.com/chimesh/` |
| **Front-end components** | Subscribes to [`MindAttic.UIUX`](../MindAttic.UIUX/) for `OutfitFont`, `AtticFont`, and the `BackHomeM` return-home anchor |
| **Hosting** | Static page on `mindattic.com/chimesh/` — no server-side code, no CMS, no database |

## What this guide IS the boilerplate for

The layout, build pipeline, parts-catalog schema, and config-widget pattern are reusable across any hardware build guide. To start a new project from this template:

1. Clone the repo as the seed.
2. Rewrite `ChiMesh.md` with the new project's sections.
3. Rewrite `config/parts.json` with the new BOM (keep the schema: `category`, `name`, `price`, `specs[]`, `searchFor`, `tiers[{tier, url}]`).
4. Update `BUILD_CONFIG_AXES` in `scripts/cli/build-html.js` with the new project's configurable axes.
5. Update `config/versions.json` with whatever upstream version labels the new project cares about.

Sections, conditional `<!-- when: key=val -->` blocks, the price-aware total, the Official/Amazon/Reputable tier system, the parts gallery, the dark/light theme toggle, the scroll-spy TOC — all of it carries over unchanged.
