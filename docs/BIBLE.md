---
codex: 1
project: ChiMesh
code: CM
layer: bible
status: living
updated: 2026-06-07
---

# ChiMesh — Project Bible
> Single source of truth for what ChiMesh IS, is NOT, and the rules that keep it coherent.
> README says how to build/run; this says how to think about the system.

## 1. The one sentence {#CM-§1}
ChiMesh is a buildable hardware guide for three solar-powered RAK4631 Meshtastic nodes (~$62/node) that prove multi-hop LoRa routing across Chicago — published as a single rendered landing page driven by a parts catalog and a config picker, with PowerShell tooling to provision and health-check the physical nodes.

## 2. The product promise {#CM-§2}
- A reader with ~$186 and basic soldering skill can order the parts, assemble three IP65 nodes in ~30 min each, flash stock Meshtastic, provision them identically, and watch a message route `A → via B → C`.
- Every part in the bill of materials is compatibility-checked end-to-end (panel → TP5000 → LFP → JST → RAK19003 → RAK4631 → IPEX → SMA → antenna); see [§4](#CM-§4).
- The guide adapts to the reader's choices (region / role / deployment / antenna) via an interactive picker that shows/hides conditional copy; see the config axes in [`config/parts.json`](../config/parts.json).
- Two safety rules are non-negotiable and surfaced everywhere: LiFePO4-only chemistry and never-USB-while-cell-wired; see [Law CM-LAW-1](#CM-LAW-1) and [Law CM-LAW-2](#CM-LAW-2).

## 3. What it is NOT {#CM-§3}
- NOT custom firmware. ChiMesh v0 runs **stock Meshtastic 2.5.x**; the value is deployment + config conventions, not a fork. (See [README §04](../README.md).)
- NOT a lamp disguise. The disguised-enclosure ("streetlight") concept is explicitly v2, after the protocol is proven.
- NOT a 1-hop demo. Nodes must be placed so at least one pair cannot hear each other directly; otherwise nothing about multi-hop routing is proven. (See [README §6.2](../README.md).)
- NOT Li-ion. Li-ion is forbidden outdoors in Chicago winter — see [Law CM-LAW-1](#CM-LAW-1).
- NOT a server/app/database. There is no backend; the "build" output is a static HTML page rendered from `README.md` + `config/parts.json` by the sibling **MindAttic.Deploy** pipeline.
- NOT self-hosting its own deploy. HTML rendering and FTPS upload live in MindAttic.Deploy, not in this repo; local `build-html*`/`deploy.ps1` were retired (see [CM-A1](AMENDMENTS.md#CM-A1)).

## 4. Architecture canon {#CM-§4}

ChiMesh has two halves: the **content/data half** (this repo) and the **render/deploy half** (sibling repo). Physically, each node is a fixed signal chain.

```
  CONTENT (this repo)                         RENDER + DEPLOY (sibling: MindAttic.Deploy)
  ────────────────────                        ──────────────────────────────────────────
  README.md ........... build narrative  ┐
  config/parts.json ... parts + axes     ├──►  index.template.htm (Hardware theme)
  config/images/*  .... part photos      ┘        + src/parts.js (CONFIG-WIDGET,
                                                    PARTS-GALLERY, when/end blocks)
                                                 ──► out/chimesh.htm ──► FTPS ──► mindattic.com/chimesh.htm

  NODE TOOLING (this repo, scripts/cli, runs against a USB-connected node via the meshtastic Python CLI)
  ──────────────────────────────────────────────────────────────────────────────────────────────────
  ChiMesh.Console.ps1 ──► provision-node.ps1   (set region / role / channel0 / owner)
                     └──► healthcheck-mesh.ps1  (verify region/role/channel/peers)

  PHYSICAL SIGNAL CHAIN (one node)
  ────────────────────────────────
  5V/2W solar ─► TP5000 (LFP jumper!) ─► LiFePO4 18650 ─► JST-PHR-2 ─► RAK19003 ─► RAK4631
                                                                          RAK4631 IPEX ─► pigtail ─► SMA bulkhead ─► 915 MHz antenna
```

### 4.1 Projects / components
- **`README.md`** — the authoritative build narrative (sections 01–08). Rendered verbatim into the landing page; `<!-- CONFIG-WIDGET -->`, `<!-- PARTS-GALLERY -->`, and `<!-- when: key=value -->…<!-- end -->` markers are filled at render time.
- **`config/parts.json`** — L5 canon-as-data: the parts catalog, `configAxes` (region/role/deployment/antenna), category definitions, and prices. Registered via [`docs/data/parts.json`](data/parts.json) against [`part.schema.json`](data/_schema/part.schema.json).
- **`config/versions.json`** — reference snapshot of pinned upstream versions (Meshtastic firmware/CLI, board labels, region/channel defaults). Values are inlined into `README.md`; this file is the canonical list to keep in sync.
- **`config/images/*`** — per-part photos, base64-inlined into the rendered gallery.
- **`scripts/cli/ChiMesh.Console.ps1`** — single dispatch-table entry point for local + node tasks (`update`, `provision`, `healthcheck`, `list-parts`, `find-deals`, `pull-latest`).
- **`scripts/cli/provision-node.ps1`** — provisions one USB node (region/role/channel0/owner) idempotently and reads back to confirm.
- **`scripts/cli/healthcheck-mesh.ps1`** — six-check smoke test against a connected node.
- **MindAttic.Deploy** (sibling, out of this repo) — renders `README.md` + `config/parts.json` to `out/chimesh.htm` and FTPS-uploads it. Invoked via [`.claude/commands/deploy.md`](../.claude/commands/deploy.md).

### 4.2 Domain model (NOUNS)
- **Node** — one assembled unit (RAK4631 + RAK19003 + power chain + enclosure + antenna). Owner name like `chimesh-001`.
- **Part** — a catalog row (`part.<id>`); `category` ∈ {core, consumable, tools}. Canon in [`config/parts.json`](../config/parts.json).
- **Config axis** — a reader choice (region, role, deployment, antenna) driving the picker and conditional copy.
- **Mesh** — the set of nodes; proven when a message routes through at least one intermediate hop.
- **Channel** — Meshtastic channel 0 (default name `ChiMesh-Test`), shared name + PSK across nodes.
- **Region / Role** — LoRa region (default `US` / 915 MHz) and device role (default `ROUTER_CLIENT`).

### 4.3 Key services (VERBS)
- **Render** — MindAttic.Deploy turns README + parts into HTML (CONFIG-WIDGET / PARTS-GALLERY / when-blocks). Out of this repo.
- **Provision** — `provision-node.ps1` writes region/role/channel0/owner over USB, reboots, reads back.
- **Healthcheck** — `healthcheck-mesh.ps1` verifies CLI present, node responds, region set, role set, channel-0 named, ≥1 NodeDB peer.
- **List / find deals** — `ChiMesh.Console` browses the parts catalog and records chosen purchase URLs.
- **Pull-latest** — self-update overlay from git via a detached finisher.

## 5. The Laws {#CM-§5}

ChiMesh **inherits the org-wide MindAttic House Rules** — see [`MindAttic.HouseRules.md`](../../MindAttic.HouseRules.md) (`HOUSE-LAW-1` … `HOUSE-LAW-9`). They are not restated here. Most directly relevant: whole-number versioning [see HOUSE-LAW-1], soft-disable over hard-delete [see HOUSE-LAW-2], "done is verified, not asserted" [see HOUSE-LAW-8], and `psst` only on explicit request [see HOUSE-LAW-9].

Project-specific laws below override nothing in the house rules; they encode ChiMesh's hardware-safety and proof invariants.

### CM-LAW-1 — LiFePO4, never Li-ion {#CM-LAW-1}
Every outdoor ChiMesh node uses a **LiFePO4 (IFR18650) cell**, never Li-ion. Chicago winters charge below 0 °C; Li-ion permanently plates lithium when charged that cold and can fail dangerously by summer. Non-negotiable. (Part `part.lfp-18650`.)

### CM-LAW-2 — Never USB-C into the RAK19003 while the LFP cell is on the JST {#CM-LAW-2}
The RAK19003's onboard charger is Li-ion only (4.2 V termination) and will overcharge an LFP cell (3.65 V max). Safe re-flash procedure: unplug JST-PHR-2 → plug USB-C → do the work → unplug USB-C → re-plug JST. (See [README §6.1](../README.md).) The cell is therefore installed only AFTER firmware + config are done.

### CM-LAW-3 — Set the TP5000 jumper to LFP (3.6 V) before connecting anything {#CM-LAW-3}
The TP5000 ships with its chemistry jumper in either position. Wrong jumper (Li-ion 4.2 V) destroys the LFP cell in weeks. Setting it to LFP/3.6 V is step 1 of every build. (Part `part.tp5000-lfp`.)

### CM-LAW-4 — SMA, not RP-SMA {#CM-LAW-4}
LoRa antennas and pigtails are **SMA**. RP-SMA looks identical, mates physically in some cases, and is wrong (it's for Wi-Fi/Helium). Buy SMA for `part.antenna-915-sma` and `part.pigtail-ipex-sma`.

### CM-LAW-5 — Stock firmware, conventions over forks {#CM-LAW-5}
v0 runs unmodified Meshtastic 2.5.x. ChiMesh's value is repeatable deployment + identical multi-node config conventions, not custom firmware. Do not fork firmware for v0.

### CM-LAW-6 — Prove multi-hop, or you've proven nothing {#CM-LAW-6}
The three proof nodes must be placed so at least one pair cannot reach each other directly, forcing traffic through an intermediate node. A network where every node shows `1 hop` does not satisfy the product promise. (See [README §6.2](../README.md), §7.3.)

### CM-LAW-7 — Single home per fact; parts data is canon-as-data {#CM-LAW-7}
Part facts (price, specs, sources) live only in [`config/parts.json`](../config/parts.json) (registered L5 via [`docs/data/parts.json`](data/parts.json)). Pinned upstream version facts live only in [`config/versions.json`](../config/versions.json). Prose cites by `part.<id>` and never restates the fields. Render + FTPS deploy live only in MindAttic.Deploy, never re-implemented here.

## 6. Verified state {#CM-§6}
Status legend: ✅ done (verified) · 🟡 partial · ⬜ planned · 🗑️ cut · living.

- 🟡 **Content is authored and internally consistent.** `README.md` (sections 01–08), `config/parts.json` (18 parts across core/consumable/tools, 4 config axes), `config/versions.json`, and 10 part images all exist and cross-reference correctly. No automated test asserts this — verified by review only, hence 🟡.
- 🟡 **Node tooling exists.** `provision-node.ps1` and `healthcheck-mesh.ps1` are complete and parameter-validated, but exercising them requires physical RAK4631 hardware + the `meshtastic` Python CLI, which is not present in CI. Unproven here → 🟡.
- ⬜ **Physical proof-of-mesh** (`A → via B → C`) — depends on three assembled nodes; not yet demonstrated in-repo.
- ⬜ **No build/test command in this repo.** `package.json` is metadata only (no `scripts`); there is no test tree and no `npm test`/`dotnet test`. Rendering + deploy run in the sibling MindAttic.Deploy repo and are out of scope here. The closest in-repo verifier is `tools/codex.ps1 doctor` (docs integrity).

**Build/test evidence (this repo, 2026-06-07):** No application build or unit-test command exists. `pwsh` is unavailable on this host; tooling runs under Windows PowerShell 5.1 via `powershell -File`. `tools/codex.ps1 doctor` is the authoritative in-repo gate — see [USER_STORIES](USER_STORIES.md) for per-story test citations (the codex tooling stories cite `codex.ps1 doctor`).

## 7. Active frontier {#CM-§7}
- **Physical proof run** — assemble + deploy three nodes and capture the `via B` hop. → [USER_STORIES](USER_STORIES.md) Epic C.
- **PSK / secured channel** — `provision-node.ps1` currently leaves channel 0 PSK at the Meshtastic default; generating + distributing a real PSK is deferred to the deployment phase. → [RFC 0001](rfc/0001-secured-channel-psk.md).
- **Winter power margin** — December harvest (~150–200 mAh/day) barely clears draw (~250 mAh/day); §6.3 documents adding a second cell or a 5 W panel. → backlog.
- **v2 lamp disguise** — out of scope for v0; tracked as a far-future epic.

## 8. Quality bar {#CM-§8}
A feature/change is done only when:
1. The relevant fact has a single home (parts → `config/parts.json`; versions → `config/versions.json`; narrative → `README.md`; rules → this bible / house rules) — no duplication. [see CM-LAW-7]
2. `tools/codex.ps1 doctor` passes (front-matter valid, IDs unique, cross-refs resolve, parts validate against schema, every ✅ story names an existing-or-best-effort test, cited paths exist, digest fresh).
3. Any `<!-- when: key=value -->` copy uses axis keys/values that exist in `config/parts.json.configAxes` (else the picker silently fails to toggle it).
4. Safety laws [CM-LAW-1..4] are honored in any procedure that touches power, charging, or RF.
5. "Done is verified, not asserted" [see HOUSE-LAW-8]: a story is ✅ only when a test or build proves it; otherwise 🟡/⬜.

## 9. Glossary {#CM-§9}
- **LoRa** — long-range, low-power RF modulation; here on the 915 MHz US ISM band via Semtech SX1262.
- **Meshtastic** — open-source mesh firmware/app over LoRa; ChiMesh runs it stock (2.5.x).
- **Multi-hop / proof-of-mesh** — a packet relayed through an intermediate node (`via B`); the project's headline goal. [see CM-LAW-6]
- **RAK4631** — RAK Wireless WisBlock Core: nRF52840 MCU + SX1262 radio (`part.rak4631`).
- **RAK19003** — WisBlock Mini base board: USB-C (flash only), JST battery in, IPEX pass-through (`part.rak19003`).
- **TP5000** — solar charge controller with a Li-ion/LFP chemistry jumper (`part.tp5000-lfp`). [see CM-LAW-3]
- **LFP / LiFePO4 / IFR18650** — the only permitted cell chemistry (`part.lfp-18650`). [see CM-LAW-1]
- **JST-PHR-2** — 2.0 mm battery connector feeding the RAK19003.
- **IPEX / u.FL** — the tiny RF connector on the RAK4631 module; adapted to SMA by a pigtail (`part.pigtail-ipex-sma`).
- **SMA vs RP-SMA** — interchangeable-looking RF connectors that are NOT compatible; LoRa uses SMA. [see CM-LAW-4]
- **ROUTER_CLIENT / ROUTER / CLIENT** — Meshtastic device roles; fixed proof nodes use ROUTER_CLIENT.
- **Config axis** — a reader choice (region/role/deployment/antenna) in the build picker.
- **Voc** — open-circuit voltage; the 5 V/2 W panel reads ~6.5 V Voc unloaded.
- **MindAttic.Deploy** — sibling repo that renders this README to HTML and FTPS-uploads the landing page.
