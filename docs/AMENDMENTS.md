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
