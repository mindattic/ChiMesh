---
codex: 1
project: ChiMesh
code: CM
layer: stories
status: living
updated: 2026-10-03
---
<!-- GENERATED from MindAttic.Tickets/data/Tickets.db by `tickets db render`. Do not edit: this file is rewritten from the database; change stories and tickets with the tickets CLI. -->

# ChiMesh — User Stories
> ✅ done (shipped & tested) · 🟡 partial · ⬜ planned. Every ✅ cites the test.
> Note: this repo has no application build or unit-test suite.
> The only automated verifier in-repo is `tools/codex.ps1 doctor`; node tooling can only be
> proven against physical RAK4631 hardware. Stories not provable in-repo are honestly marked 🟡/⬜.

## Epic A — Buy & build a node
- **CM-US-A1 🟡** As a builder, I can read a complete bill of materials with per-node cost so I know what to order. *Given the catalog, When I view the README's Parts list, Then I see core/consumable/tools grouped with prices and a per-node total.* *(parts data lives in `config/parts.json`; the README carries a static parts table maintained by hand from it. No in-repo test asserts the table matches the catalog → 🟡.)*
- **CM-US-A2 🟡** As a builder, I can follow a step-by-step assembly with the power chain wired safely, so I don't destroy a cell or board. *Given README §03, When I follow steps 1–9, Then boards are mounted, antenna threaded, panel sealed, cell holder empty.* *(authored in `README.md` §03; safety enforced by [CM-LAW-1](BIBLE.md#CM-LAW-1)/[CM-LAW-2](BIBLE.md#CM-LAW-2)/[CM-LAW-3](BIBLE.md#CM-LAW-3); no automated test → 🟡.)*
- **CM-US-A3 🟡** As a builder, I can browse vendor options and record my chosen purchase URL per part, so my catalog reflects what I actually bought. *Given `find-deals`, When I paste a URL, Then it is saved to `config/parts.json.chosen`.* *(implemented in `ChiMesh.Console.ps1` `Cmd-FindDeals`; interactive, hardware/browser-bound, no automated test → 🟡.)*

## Epic B — Flash & provision
- **CM-US-B1 🟡** As a builder, I can flash stock Meshtastic onto a RAK4631 via the web flasher, so the node runs proven firmware. *Given Chrome/Edge + README §04, When I flash the 2.5.x build, Then the board reboots into Meshtastic.* *(authored `README.md` §04; depends on hardware + external flasher → 🟡.)*
- **CM-US-B2 🟡** As a builder, I can provision a USB node to ChiMesh's standard config in one command, so all nodes are identical. *Given `provision-node.ps1 -NodeName chimesh-001`, When it runs, Then region/role/channel0/owner are written and read back to confirm.* *(implemented + parameter-validated in `provision-node.ps1`; requires a connected node → 🟡.)*
- **CM-US-B3 🟡** As a builder, I can confirm a node's config and connectivity with one healthcheck, so I trust it before deploying. *Given `healthcheck-mesh.ps1`, When it runs against a node, Then it reports CLI present, node responds, region set, role set, channel-0 named, peer count.* *(implemented in `healthcheck-mesh.ps1` (six checks); requires a connected node → 🟡.)*

## Epic C — Prove the mesh
- **CM-US-C1 ⬜** As a builder, I can place three nodes so at least one pair can't hear each other directly, so multi-hop is actually exercised. *Given README §6.2 placement, When nodes are positioned ~1–3 km apart, Then at least one link is indirect.* *(depends on physical deployment; [CM-LAW-6](BIBLE.md#CM-LAW-6).)*
- **CM-US-C2 ⬜** As a builder, I can send a message from my phone (paired to A) to node C and see a `via B` hop, so multi-hop routing is proven. *Given §7.3, When I send A→C, Then C receives it and the app shows `via B`.* *(the headline proof; not yet demonstrated in-repo.)*

## Epic D — Keep docs honest
- **CM-US-D2 ✅** As a maintainer, I can run a documentation doctor that fails on broken canon, so the bible/stories/data stay internally consistent. *Given `tools/codex.ps1 doctor`, When canon is valid, Then it exits 0; When a cross-ref/front-matter/schema/digest issue exists, Then it exits non-zero with a checklist.* *(verified by `tools/codex.ps1 doctor` — run in this repo on 2026-06-07, exit 0.)*
- **CM-US-D3 ✅** As a maintainer, I can regenerate a compact authoritative digest for session injection, so assistants start from canon. *Given `tools/codex.ps1 digest`, When it runs, Then `docs/BIBLE.digest.md` is regenerated from §1/§3/§5/§9 + a status index + any pending decisions.* *(verified by `tools/codex.ps1 digest` producing `docs/BIBLE.digest.md`, confirmed fresh by `doctor` on 2026-06-07.)*

## Priority backlog
Dependency-ordered toward the headline goal (CM-US-C2, proven multi-hop):
1. **CM-US-A1/A2** — order parts, assemble three nodes (gates everything physical).
2. **CM-US-B1 → B2 → B3** — flash, provision identically, healthcheck each node before it leaves the bench.
3. **CM-US-C1** — physical placement that forces an indirect link.
4. **CM-US-C2** — the proof: capture `A → via B → C`.
5. Secured channel PSK ([RFC 0001](rfc/0001-secured-channel-psk.md)) before any non-test deployment.
6. Winter power-margin upgrade (second cell / 5 W panel) for any node overwintering unattended.

## Tickets
> Permanent log of every change and fix — this repo's ticket system. Rows are append-only: never
> delete or reword one; only move its Status (open → closed / wont-do) and fill in Ref. Status is
> a word, not a glyph, so tickets don't count toward the story index. Keep this section last.

| ID | Date | Type | Status | Summary | Ref |
|---|---|---|---|---|---|
| CM-T1 | 2026-10-12 | docs | closed | Start the permanent ticket log in USER_STORIES.md | — |
| CM-T2 | 2026-10-15 | chore | closed | Remove duplicate command copies (/deploy, /do, /quickload, /quicksave) now centralized at the user level (~/.claude/commands) | M.FLOW-T14 |
| CM-T3 | 2026-10-16 | chore | closed | install.ps1 adds this repo's 8 .prose/commands stubs for the shared global commands, so any LLM client finds them | mindattic-agent-standard/install.ps1 run 2026-10-16 |
| CM-T4 | 2026-10-16 | chore | closed | Bug hunt: run an exhaustive /bughunt over the whole repo and fix every real bug found (each fix under its own fix ticket), then hunt again; close this only when a full pass finds nothing | fea8981 |
| CM-T5 | 2026-10-16 | chore | open | Run the full unit test suite and fix every failure (each under its own fix ticket) until it passes; put the passing run in --ref. No test project: close this wont-do saying so | user request 2026-10-16: approved repo sweep |
| CM-T6 | 2026-10-16 | chore | open | Clean up code and docs: remove dead code, stale comments and outdated or duplicated docs, and simplify where behaviour doesn't change (/simplify); tests stay green | user request 2026-10-16: approved repo sweep |
| CM-T7 | 2026-10-16 | docs | open | Bring README.md up to date with the code as it is now (what it is, setup, usage, commands, current state), following codex-standard/README-STYLE.md; README.htm regenerated if the repo has one | user request 2026-10-16: approved repo sweep |
| CM-T8 | 2026-10-16 | docs | closed | Update USER_STORIES.md | — |
| CM-T9 | 2026-10-19 | chore | wont-do | Convert tracked source files to LF line endings via .gitattributes, per HOUSE-LAW-13 (low priority) | — |
| CM-T10 | 2026-10-20 | docs | open | Publish ChiMesh docs to GitHub Pages via the shared Toolkit DocFX pipeline: run adopt-docs-site.ps1 (README.md as home page, docs/*.md as articles, API reference only where the code builds in CI), enable Pages with build_type=workflow, set the repo homepage URL, retire tools/build-readme.ps1 and README.htm, confirm the docs Actions run is green and https://mindattic.github.io/ChiMesh/ returns 200. Depends on MAT-T8. | — |
| CM-T11 | 2026-10-21 | fix | closed | healthcheck-mesh.ps1 fails to parse under Windows PowerShell 5.1 (BOM-less UTF-8 em dashes read as cp1252 smart quotes), so ChiMesh.Console healthcheck never runs; provision/console/digest hook print mojibake | ba8edc1 |
| CM-T12 | 2026-10-21 | fix | closed | ChiMesh.Console provision/healthcheck pass -Region/-Role/-Channel/-Port through array splatting, which binds them positionally: 'provision chimesh-001 -Region EU_868' fails with PositionalParameterNotFound | dbebd82 |
| CM-T13 | 2026-10-21 | fix | closed | Native-command stderr under ErrorActionPreference=Stop throws NativeCommandError in PS 5.1: provision-node dies instead of its no-node message / reboot retry loop, healthcheck (via console) and pull-latest's no-upstream check likewise | cb96372 |
| CM-T14 | 2026-10-21 | fix | closed | pull-latest stages a clone of the local repo and resets to its origin (= the local repo itself), so the overlay copies the old tree and never updates anything | 749a892 |
| CM-T15 | 2026-10-21 | fix | closed | ChiMesh.Console exits 0 even when provision/healthcheck fail, so the .bat failure path never fires and a failed healthcheck reports success | b6465ab |
| CM-T16 | 2026-10-21 | fix | closed | Typing an unknown command in the ChiMesh.Console interactive menu calls exit 2 and kills the whole console instead of reprompting | d4a2190 |
| CM-T17 | 2026-10-21 | fix | closed | find-deals reads config/parts.json without -Encoding UTF8 under PS 5.1 and writes it back, corrupting every non-ASCII char in the canonical parts catalog (and list-parts prints mojibake) | 5f21d66 |
| CM-T18 | 2026-10-21 | fix | closed | codex doctor fails on main: BIBLE.md 4.1 links ../.claude/commands/deploy.md, which no longer exists (deploy is the global router now) | 8a3dd76 |
| CM-T19 | 2026-10-21 | fix | closed | codex doctor's digest freshness check compares file mtimes, so any fresh clone/worktree where BIBLE.md is checked out after the digest false-fails as STALE; compare content instead | 539c151 |
| CM-T20 | 2026-10-21 | fix | closed | codex doctor false-fails in every linked worktree (the orchestrator's MindAttic.worktrees\ChiMesh\<ticket>): it looks for MindAttic.HouseRules.md beside the worktree instead of beside the main checkout | bf46121 |
| CM-T21 | 2026-10-21 | fix | open | pull-latest overlays files with robocopy but never moves HEAD (and never deletes files removed upstream), so after a successful update every changed file shows as a local modification and the next pull-latest reports 'behind N' + 'dirty' and needs --force; needs a design call (ff-only merge in the finisher vs. reset --mixed vs. keep overlay) | — |
| CM-T22 | 2026-10-21 | fix | closed | ChiMesh.Console.bat (root and scripts/cli) are LF-only with a UTF-8 em dash; under a UTF-8 (65001) console cmd.exe misparses them ('M'/'etlocal'/'owershell.exe' not recognized) and the console never launches; check them out CRLF and keep them ASCII | fea8981 |
| CM-T23 | 2026-10-21 | docs | closed | Update USER_STORIES.md | — |
| CM-T24 | 2026-10-22 | docs | closed | Update USER_STORIES.md | — |
