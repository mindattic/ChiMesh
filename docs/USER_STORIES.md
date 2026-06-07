---
codex: 1
project: ChiMesh
code: CM
layer: stories
status: living
updated: 2026-06-07
---

# ChiMesh — User Stories
> ✅ done (shipped & tested) · 🟡 partial · ⬜ planned · 🗑️ cut. Every ✅ cites the test.
> Note: this repo has no application build or unit-test suite (`package.json` is metadata only).
> The only automated verifier in-repo is `tools/codex.ps1 doctor`; node tooling can only be
> proven against physical RAK4631 hardware. Stories not provable in-repo are honestly marked 🟡/⬜.

## Epic A — Buy & build a node
- **CM-US-A1 🟡** As a builder, I can read a complete bill of materials with per-node cost so I know what to order. *Given the catalog, When I view the parts gallery, Then I see core/consumable/tools grouped with prices and a per-node total.* *(parts data lives in `config/parts.json`; rendered by MindAttic.Deploy `src/parts.js`. No in-repo test asserts the render → 🟡.)*
- **CM-US-A2 🟡** As a builder, I can follow a step-by-step assembly with the power chain wired safely, so I don't destroy a cell or board. *Given README §03, When I follow steps 1–9, Then boards are mounted, antenna threaded, panel sealed, cell holder empty.* *(authored in `README.md` §03; safety enforced by [CM-LAW-1](BIBLE.md#CM-LAW-1)/[CM-LAW-2](BIBLE.md#CM-LAW-2)/[CM-LAW-3](BIBLE.md#CM-LAW-3); no automated test → 🟡.)*
- **CM-US-A3 🟡** As a builder, I can browse vendor options and record my chosen purchase URL per part, so my catalog reflects what I actually bought. *Given `find-deals`, When I paste a URL, Then it is saved to `config/parts.json.chosen`.* *(implemented in `ChiMesh.Console.ps1` `Cmd-FindDeals`; interactive, hardware/browser-bound, no automated test → 🟡.)*

## Epic B — Flash & provision
- **CM-US-B1 🟡** As a builder, I can flash stock Meshtastic onto a RAK4631 via the web flasher, so the node runs proven firmware. *Given Chrome/Edge + README §04, When I flash the 2.5.x build, Then the board reboots into Meshtastic.* *(authored `README.md` §04; depends on hardware + external flasher → 🟡.)*
- **CM-US-B2 🟡** As a builder, I can provision a USB node to ChiMesh's standard config in one command, so all nodes are identical. *Given `provision-node.ps1 -NodeName chimesh-001`, When it runs, Then region/role/channel0/owner are written and read back to confirm.* *(implemented + parameter-validated in `provision-node.ps1`; requires a connected node → 🟡.)*
- **CM-US-B3 🟡** As a builder, I can confirm a node's config and connectivity with one healthcheck, so I trust it before deploying. *Given `healthcheck-mesh.ps1`, When it runs against a node, Then it reports CLI present, node responds, region set, role set, channel-0 named, peer count.* *(implemented in `healthcheck-mesh.ps1` (six checks); requires a connected node → 🟡.)*

## Epic C — Prove the mesh
- **CM-US-C1 ⬜** As a builder, I can place three nodes so at least one pair can't hear each other directly, so multi-hop is actually exercised. *Given README §6.2 placement, When nodes are positioned ~1–3 km apart, Then at least one link is indirect.* *(depends on physical deployment; [CM-LAW-6](BIBLE.md#CM-LAW-6).)*
- **CM-US-C2 ⬜** As a builder, I can send a message from my phone (paired to A) to node C and see a `via B` hop, so multi-hop routing is proven. *Given §7.3, When I send A→C, Then C receives it and the app shows `via B`.* *(the headline proof; not yet demonstrated in-repo.)*

## Epic D — Adapt the guide & keep docs honest
- **CM-US-D1 🟡** As a reader, I can pick region/role/deployment/antenna and the guide shows only the copy that applies to me. *Given the config picker, When I change an axis, Then matching `<!-- when: key=value -->` blocks show/hide and persist in localStorage.* *(axes in `config/parts.json.configAxes`; toggling implemented in MindAttic.Deploy `src/parts.js`; no in-repo test → 🟡.)*
- **CM-US-D2 ✅** As a maintainer, I can run a documentation doctor that fails on broken canon, so the bible/stories/data stay internally consistent. *Given `tools/codex.ps1 doctor`, When canon is valid, Then it exits 0; When a cross-ref/front-matter/schema/digest issue exists, Then it exits non-zero with a checklist.* *(verified by `tools/codex.ps1 doctor` — run in this repo on 2026-06-07, exit 0.)*
- **CM-US-D3 ✅** As a maintainer, I can regenerate a compact authoritative digest for session injection, so assistants start from canon. *Given `tools/codex.ps1 digest`, When it runs, Then `docs/BIBLE.digest.md` is regenerated from §1/§3/§5/§9 + a status index + the latest amendment.* *(verified by `tools/codex.ps1 digest` producing `docs/BIBLE.digest.md`, confirmed fresh by `doctor` on 2026-06-07.)*

## Priority backlog
Dependency-ordered toward the headline goal (CM-US-C2, proven multi-hop):
1. **CM-US-A1/A2** — order parts, assemble three nodes (gates everything physical).
2. **CM-US-B1 → B2 → B3** — flash, provision identically, healthcheck each node before it leaves the bench.
3. **CM-US-C1** — physical placement that forces an indirect link.
4. **CM-US-C2** — the proof: capture `A → via B → C`.
5. Secured channel PSK ([RFC 0001](rfc/0001-secured-channel-psk.md)) before any non-test deployment.
6. Winter power-margin upgrade (second cell / 5 W panel) for any node overwintering unattended.

### Audit log
No stories have been changed yet (initial Codex authoring on 2026-06-07). When a story's intent changes, preserve the original ask verbatim here, marked "(original spec — audit log)".
