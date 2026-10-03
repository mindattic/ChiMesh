---
codex: 1
project: ChiMesh
code: CM
layer: amendments
status: living
updated: 2026-06-07
---

# ChiMesh — Amendments (append-only; amendment wins over the bible)

> Never rewrite an amendment; supersede it with a new one. Beyond ~25, fold into the BIBLE and
> start a new epoch (note the git tag).

## CM-A1 — Deploy moved to MindAttic.Deploy; local build pipeline retired (supersedes —) {#CM-A1}
**What changed.** HTML rendering and FTPS upload no longer live in this repo. The old 3-file
long-form-guide pipeline (`scripts/cli/build-html*`, `bump-version*`, `deploy.ps1`, the
`/chimesh/` subfolder, and marker-block splicing) was removed. Deploys now run only through the
sibling **MindAttic.Deploy** repo, which renders `README.md` + `config/parts.json` through the
`Hardware`-theme catalog template and uploads a single `chimesh.htm`.

**Why.** One catalog pipeline for all MindAttic landing pages; this repo keeps only content
(`README.md`, `config/`) and live node tooling (`scripts/cli/`). Single home per fact for render
machinery — see [CM-LAW-7](BIBLE.md#CM-LAW-7).

**Migration.** Run `/deploy` (see [`.claude/commands/deploy.md`](../.claude/commands/deploy.md)),
not any local build script. The old subfolder URL `mindattic.com/chimesh/` lingers on the FTP
server until manually deleted. `config/versions.json` placeholder substitution was retired; its
values are now inlined directly into `README.md`.

## CM-A2 — Codex documentation standard installed (supersedes —) {#CM-A2}
**What changed.** Added the Codex canon layout: `docs/BIBLE.md` (L0), `docs/AMENDMENTS.md` (L1),
`docs/USER_STORIES.md` (L2), `docs/rfc/` (design notes), `docs/data/` (L5 — registers the existing
`config/parts.json` against `docs/data/_schema/part.schema.json`), `tools/codex.ps1` (doctor +
digest), and a `SessionStart` hook that injects `docs/BIBLE.digest.md`.

**Why.** Give ChiMesh the same single-source-of-truth + verifiable-docs discipline as the rest of
MindAttic, and inherit the org-wide [House Rules](../../MindAttic.HouseRules.md).

**Migration.** No content was deleted. `config/parts.json` and `config/versions.json` remain the
canonical data homes (the bible cites them; it does not copy them). No application/source code was
changed.

## CM-A3 — MindAttic.Deploy render + parts addon retired; README is a static GitHub page (supersedes CM-A1's render half and the bible's render/picker canon) {#CM-A3}
**What changed.** On 2026-10-03 MindAttic.Deploy retired its catalog pipeline (its amendment DEP-A6): the
README → `chimesh.htm` render, the `parts` addon (`src/parts.js`, which read `config/parts.json` and
`config/images` to fill `<!-- CONFIG-WIDGET -->`, `<!-- PARTS-GALLERY -->` and `<!-- when: -->` blocks) and
the upload are gone, and `mindattic.com/chimesh.htm` 301-redirects to https://github.com/mindattic/ChiMesh.
`README.md` is now the project page as GitHub shows it, with a static parts table; there is no interactive
configurator. `config/parts.json` stays the canonical parts/price data ([CM-LAW-7](BIBLE.md#CM-LAW-7)) and
`config/images/` the part photos the README links.

**Bible.** §1 (rendered landing page + picker), §2 (interactive picker), §3 (static HTML rendered by Deploy;
render lives in Deploy), §4 (two halves, README markers, gallery images, the Deploy component), §4.2/§9 config
axis "picker" wording, §4.3 Render, CM-LAW-7's render clause, §6's "rendering + deploy run in Deploy", §8 item 3
and the §9 MindAttic.Deploy entry are struck through and marked superseded. §7 gains a note that the
configurator is retired. The §3 mention of the retired local deploy script (a stale path the doctor warned
about) is reworded without the filename. **Stories.** CM-US-A1 now cites the README's static parts table;
CM-US-D1 (picker) is cut 🗑️.

**Migration.** None. `/deploy` already says there is no web deploy. No application code changed.
