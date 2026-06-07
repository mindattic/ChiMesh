---
codex: 1
project: ChiMesh
code: CM
layer: rfc
status: planned
updated: 2026-06-07
---

# RFC 0001 — Secured channel-0 PSK across the mesh

## Problem
`provision-node.ps1` writes channel-0 name (`ChiMesh-Test`) but **leaves the PSK at the Meshtastic
default**. A default-PSK channel is effectively open: anyone within RF range running stock
Meshtastic on the same name/region can read and inject traffic. For a throwaway proof run this is
acceptable; for any node left deployed it is not. We need a way to generate one PSK and apply it
identically to all proof nodes.

## Options compared
1. **Per-node manual `--ch-set psk`** — flexible, but error-prone: a single mistyped/mismatched PSK
   silently partitions the mesh (nodes hear each other but can't decrypt).
2. **Generate once, distribute via the channel URL/QR** — Meshtastic's native sharing; copy the
   Primary channel URL from node A and import it on B and C. Low typo risk, app-driven.
3. **Scripted: generate a random PSK once, loop `provision-node.ps1` with a `-Psk` parameter** —
   repeatable, scriptable for ≥3 nodes, fits the existing idempotent-provisioner pattern.

## Decision
Adopt **Option 3** as the default, with Option 2 documented as the manual fallback. Add an optional
`-Psk` parameter to `provision-node.ps1` (generate one with `meshtastic --ch-set psk random` on the
first node, read it back, then pass the same value to the rest). Keep the default-PSK behavior only
behind an explicit `-Insecure` / test flag so a forgotten PSK can't silently ship.

## What NOT to do
- Do NOT hard-code or commit a PSK — [see HOUSE-LAW-3](../../../MindAttic.HouseRules.md#HOUSE-LAW-3).
- Do NOT set different PSKs per node and expect a mesh — mismatched PSKs partition silently.
- Do NOT change the channel **name** as a security measure; name is not a secret.

## Phased plan (with risk)
1. Add `-Psk` (optional) + `-Insecure` (explicit) params to `provision-node.ps1`; default refuses to
   leave the default PSK unless `-Insecure`. *(Risk: behavior change for existing test scripts —
   gate behind the flag.)* — touches app tooling; out of scope for the Codex docs pass.
2. Document the generate-once-distribute flow in `README.md` §05.
3. Verify with `healthcheck-mesh.ps1` that all nodes share a non-default channel and still peer.

## Graduates into
- BIBLE [§7 Active frontier](../BIBLE.md#CM-§7) (already pointed here) and a new law if PSK becomes mandatory.
- USER_STORIES: a new Epic B story "provision a secured channel", citing the healthcheck.
