# ChiMesh

**Chicago LoRa Meshtastic mesh — proof-of-mesh build.** Three solar-powered RAK4631 nodes in weatherproof IP65 enclosures that prove multi-hop LoRa routing across the city. About **~$62 per node** (so ~$186 for the proof batch of three), plus ~$25 in shared consumables (wire, JST, solder, heat-shrink) and any one-time tools you don't already own. No lamp disguise yet — that's v2 once the protocol is proven.

> **Two non-negotiable rules.**
>
> 1. **LiFePO4, not Li-ion.** Chicago winters charge below 0°C. Li-ion cells permanently plate lithium when charged that cold and can fail dangerously by summer. LFP is non-negotiable for any outdoor ChiMesh node.
> 2. **Never plug USB-C into the RAK19003 while the LFP cell is wired into the JST.** The RAK19003's onboard charger is Li-ion only (4.2 V termination) and will overcharge an LFP cell (3.65 V max). The safe re-flash procedure is in §6.1: unplug the JST-PHR-2, plug USB-C, do your work, unplug USB-C, plug the JST back in.

[github.com/mindattic/ChiMesh](https://github.com/mindattic/ChiMesh)

*Last updated: 2026.05.23d*

---

## 01. Configure

<!-- CONFIG-WIDGET -->

---

## 02. Shopping list

The total below counts **core parts per node** only. Multiply by your planned node count — minimum 3 to actually prove multi-hop routing (otherwise there's no chain to forward through). The consumables and tools categories show one-time / shared items and are excluded from the per-node total.

<!-- PARTS-GALLERY -->

---

## 03. Assemble

**Total time:** *~30 minutes per node, once parts are in hand.*

### 3.1 Tools you'll need

One-time tools, not per-node — most builders already own them. See the shopping list for specific picks if you don't:

- **Temperature-controlled soldering iron** + 60/40 rosin-core solder (0.8 mm)
- **Heat-shrink tubing** (2–8 mm assortment) + heat gun or lighter
- **Wire strippers + flush cutters** for 22 AWG
- **JST crimp tool** (or buy pre-crimped JST-PHR-2 pigtails and skip this)
- **Digital multimeter** — for verifying LFP cell voltage (3.2–3.65 V) and panel output (~6.5 V Voc) during troubleshooting
- **Drill + bits** — 6 mm for the SMA bulkhead hole, 12 mm for the M12 cable gland (a step bit makes cleaner holes in ABS)
- **Phillips #1 screwdriver** for the enclosure lid

### 3.2 Wiring overview

One signal path with two sub-paths:

```
Solar panel  →  TP5000 (LFP jumper set!)  →  LiFePO4 cell  →  JST-PHR-2  →  RAK19003  →  RAK4631
RAK4631 IPEX  →  pigtail  →  SMA bulkhead  →  915 MHz antenna
```

### 3.3 Build steps

> **DO NOT INSTALL THE LFP CELL UNTIL SECTION 06.** Sections 04 and 05 want you connecting USB-C to the RAK19003 for flashing and provisioning. The RAK19003's onboard charger terminates at 4.2 V (Li-ion), which will overcharge an LFP cell (3.65 V max). Cell goes in AFTER firmware + config are done.

1. **Set the TP5000 jumper to LFP (3.6 V).** This is the single most important step. The board ships with the jumper in either position; LFP termination is usually labeled `4.2/3.6` or `Li-ion/LiFePO4`. Wrong jumper = dead cell in weeks.
2. **Solder the solar panel leads to the TP5000 `IN+` / `IN-` pads.** Red to `+`, black to `-`. Heat-shrink the joint — the enclosure isn't fully sealed if the panel cable enters with bare conductors.
3. **Solder the LFP cell holder leads to the TP5000 `BAT+` / `BAT-` pads.** Don't insert the cell yet.
4. **Crimp a JST-PHR-2 onto a short pair of 22 AWG wires**, then solder the other end of those wires to the TP5000's `BAT+` / `BAT-` pads (in parallel with the cell-holder leads). This is the output that feeds the RAK19003.
5. **Snap the RAK4631 onto the RAK19003 Mini Base.** Align the silk-screen markers, press until the board-to-board connector seats fully.
6. **Connect the IPEX pigtail.** The u.FL connector on the RAK4631 is fragile — press straight down with a thumbnail until it clicks. Mount the SMA bulkhead end through the drilled hole in the top of the enclosure (panel nut on the outside). **SMA, not RP-SMA** — they look identical but won't mate with a LoRa antenna.
7. **Plug the JST-PHR-2 from the TP5000 into the RAK19003 battery input.** It only fits one way. Leave the cell holder EMPTY for now — power for sections 04 and 05 comes from USB-C, not the battery path.
8. **Mount everything inside the enclosure.** Foam-tape the TP5000 to one wall, the RAK19003 + Mini Base to the opposite wall, the cell holder along the floor (empty). Route the panel cable out through the M12 gland.
9. **Visual sanity check.** Antenna is vertical when the enclosure is mounted in its final orientation. No bare wire near the SMA bulkhead. Cell holder is empty and ready.

<!-- when: deployment=rooftop -->
**Rooftop note.** Grounding is a real concern when the antenna is your highest point. Add a gas-discharge tube (GDT) lightning arrestor on the SMA line before the radio — cheap insurance for a board you can't easily reach.
<!-- end -->

✅ **Checkpoint:** *Boards mounted, antenna threaded through enclosure wall, panel cable sealed at the gland, cell holder empty and ready for sections 04–05.*

---

## 04. Flash firmware

ChiMesh runs stock Meshtastic firmware. We're not forking — for v0 the value is in deployment + config conventions, not custom firmware.

### 4.1 Open the web flasher

In **Chrome or Edge** (Web Serial isn't in Firefox/Safari), open:

```
{{FLASHER_URL}}
```

### 4.2 Connect and flash

1. Plug the RAK19003's USB-C into your computer.
2. Click **Select Device**. Pick **RAK4631** from the dropdown.
3. Pick the latest stable {{MESHTASTIC_FIRMWARE_LABEL}} build.
4. Pick **Region: {{REGION_DEFAULT}}** (default; adjust if you're outside the US).
5. Click **Flash**, allow the browser's serial-port prompt.
6. Wait ~30 seconds. The board reboots into the Meshtastic firmware automatically.

✅ **Checkpoint:** *Flasher prints "Done" and the RAK19003 LED settles into a slow heartbeat pattern.*

---

## 05. Configure node

You can configure either via the official Meshtastic app over Bluetooth, or via the `meshtastic` CLI over USB. The CLI is faster for scripted multi-node setup — recommended for ChiMesh since you're provisioning at least 3 nodes identically.

### 5.1 Install the Meshtastic CLI

```bash
pip install --upgrade meshtastic
```

You should see {{MESHTASTIC_CLI_LABEL}} or newer.

### 5.2 Provision the node

Use the bundled provisioner — it walks one USB-connected node through the standard ChiMesh config:

```powershell
scripts\cli\provision-node.ps1 -NodeName chimesh-001
```

Or set each field manually:

```bash
meshtastic --set lora.region {{REGION_DEFAULT}}
meshtastic --set device.role ROUTER_CLIENT
meshtastic --ch-set name "{{CHANNEL_DEFAULT}}" --ch-index 0
meshtastic --set-owner chimesh-001
```

<!-- when: role=router -->
**Role note (ROUTER).** ROUTER means this node relays every packet it hears but never originates user messages. Reserve for true backbone nodes — usually 1 per metro area. For most ChiMesh deployments ROUTER_CLIENT is better because it both relays AND lets you chat from this node.
<!-- end -->
<!-- when: role=client -->
**Role note (CLIENT).** CLIENT is for portable / handheld use — the node sleeps aggressively to save battery. A sleeping CLIENT will not forward packets. Do NOT use this role for your fixed proof nodes; pick ROUTER_CLIENT for those.
<!-- end -->
<!-- when: region=eu868 -->
**Region note (EU 868).** EU duty-cycle rules limit each device to ~1% airtime on most sub-channels. Meshtastic respects this in firmware, but expect slower message throughput than US 915.
<!-- end -->

### 5.3 Confirm

```bash
meshtastic --info
```

You should see the region you picked, the role you picked, and channel 0 named `{{CHANNEL_DEFAULT}}`.

✅ **Checkpoint:** *`meshtastic --info` returns region + role + channel exactly as expected.*

---

## 06. Deploy

### 6.1 Install the LFP cell — finally

With firmware flashed and config written, **unplug USB-C** from the RAK19003. Now insert the LFP cell into the holder. The RAK19003 red LED should blip briefly as the board powers up from the TP5000's `BAT` output. From this point forward, never plug USB-C in unless you've first unplugged the JST-PHR-2 from the RAK19003 — the onboard charger will overcharge LFP otherwise.

If you need to re-flash later: power down (unplug JST), plug USB-C, flash, unplug USB-C, plug JST back in. Tedious but safe.

### 6.2 Placement strategy

For proof-of-mesh, the 3 nodes have to be positioned so **at least one pair cannot hear each other directly**. Otherwise you've built a 1-hop network and proven nothing about multi-hop routing.

A workable Chicago layout:

| Node | Suggested location | Why |
|------|--------------------|-----|
| Node A | High-rise apartment window or balcony | Gateway altitude — sees both B and C |
| Node B | Friend's apartment / office, ~1–3 km away | Far enough it can't reach C directly |
| Node C | Second remote location, ~1–3 km from B in a different direction | Forces traffic through A |

<!-- when: deployment=apartment_window -->
**Apartment-window note.** Indoor through low-E (energy-efficient) glass costs ~10–15 dB of signal. If you have access to a balcony or an exterior fence/eave, use it — Chicago's lake-effect glass is particularly bad for 915 MHz. Antenna outside the window beats antenna inside, every time.
<!-- end -->
<!-- when: deployment=rooftop -->
**Rooftop note.** Strongest placement. Aim the solar panel south at ~41° tilt (Chicago's latitude). Mount the enclosure on the north side of any obstruction so the antenna stays clear of metal HVAC, parapets, and roof-edge railings.
<!-- end -->
<!-- when: deployment=ground_pole -->
**Ground-pole note.** Range from a ground-level node is roughly half of an elevated one — buildings, cars, and foliage block line-of-sight. Useful as a yard pin but not as your gateway node. Don't expect to bridge anything beyond ~500 m.
<!-- end -->
<!-- when: antenna=fiberglass8 -->
**Fiberglass colinear note.** An 8+ dBi fiberglass antenna is heavier, more visible, and needs a real mast or bracket. Pair it with the rooftop deployment only — on a balcony it's overkill and on a window it's structurally awkward.
<!-- end -->

**Solar panel aim.** Face south, tilt ~41° (matches Chicago's latitude). Don't lay panels flat — flat panels collect snow and bird droppings, and the December sun angle is so low that flat-mount harvest drops ~30%.

**Antenna orientation.** Vertical. Most Meshtastic networks are vertically polarized; a sideways antenna costs you ~3 dB instantly.

### 6.3 Power budget

Rough draw for the RAK4631 (SX1262 + nRF52840) running stock Meshtastic in continuous receive:

- **SX1262 in RX:** ~4.6 mA
- **nRF52840 active** (BLE off, CPU lightly loaded): ~3–6 mA
- **Combined at 3.3 V:** ~8–12 mA average in steady listen, with brief spikes to ~120 mA on TX bursts.

Over 24 hours that's **~200–280 mAh consumed**. The ~1500 mAh LFP cell + 5 V / 2 W panel works for Chicago summer — a sunny day harvests ~600–800 mAh, well above draw — but December is tight: 1.5 peak sun hours × 2 W ≈ 150–200 mAh/day in, against ~250 mAh/day out. That's a real-world deficit on the worst weeks, and the reason the v0 panel-aim rule above says "tilt ~41°, never flat." If a node has to survive a Chicago January with no intervention, plan to add a second cell in parallel (~3000 mAh total) or step up to a 5 W panel — both are documented in §08.

✅ **Checkpoint:** *All 3 nodes deployed, solar panels facing the sky, antennas vertical, enclosure lids closed and sealed.*

---

## 07. Verify mesh

### 7.1 Pair with the Meshtastic app

Install the Meshtastic app — see {{MESHTASTIC_APP_URL}} for the official download links. Pair with Node A over Bluetooth (default PIN is `123456` unless you changed it).

### 7.2 Check the node list

The app's **Nodes** tab should list all 3 nodes within a few minutes — A directly (paired to your phone) plus B and C via radio. The gear icon next to each remote node shows hop count: `1 hop` = direct, `2 hops` = routed through another node.

### 7.3 The actual test

Send a text from the app (paired to A) to Node C. If it arrives at C, and the path shows `via B` in the app, you've proven multi-hop routing.

If every node shows `1 hop`, the nodes are too close together — separate them further until at least one pair can't see each other directly.

✅ **Checkpoint:** *A message from your phone (paired to A) reaches C with a `via B` hop indicator in the app.*

### 7.4 Run the bundled healthcheck

```powershell
scripts\cli\healthcheck-mesh.ps1
```

Connects to whichever node is on the USB cable, queries `--info` and `--nodes`, and reports region, role, channel-0 name, and the count of known peers. Use it as a one-shot sanity check before calling the deployment done.

---

## 08. Troubleshooting

### Nothing comes up on the web flasher
- Chrome or Edge only — Web Serial isn't in Firefox/Safari.
- Try a different USB-C cable. Many "charging only" cables don't carry USB data.
- On Windows, check Device Manager for the COM port; if it's missing, install Nordic's USB driver.

### Flashed, but no LED activity
- The RAK19003 red LED only lights when current is drawn — if the cell is dead or the jumper is wrong, the board sits at 0 V.
- Check cell voltage with a multimeter: a healthy LFP reads 3.2–3.65 V.
- Confirm the TP5000 jumper is set for LFP (3.6 V), not Li-ion (4.2 V).

### Nodes can't see each other
- Verify all nodes are on the same region (`meshtastic --info` shows `lora.region`).
- Verify all nodes are on the same channel name AND PSK.
- Move one node within 10 m of another to rule out a config bug vs a range issue.

### Solar isn't keeping up
- Confirm the panel is generating: disconnect from the TP5000, measure open-circuit voltage in sunlight — should be ~6.5 V Voc (closer to ~5 V once it's loaded by the TP5000).
- Confirm the TP5000 is charging: re-connect, measure across the cell — should rise toward 3.6 V over an hour of sun.
- December low-light is the close case. If a node won't survive the worst week, upgrade to a 5 W panel.

### Radio not responding via CLI
```powershell
scripts\cli\healthcheck-mesh.ps1 -Verbose
```
Reads the connected node and prints any error states from `--info`.

---

## Reference

- **Meshtastic firmware:** https://github.com/meshtastic/firmware
- **Meshtastic web flasher:** {{FLASHER_URL}}
- **Meshtastic apps (mobile + desktop):** {{MESHTASTIC_APP_URL}}
- **RAK4631 product page:** https://store.rakwireless.com/products/rak4631-lpwan-node
- **RAK19003 product page:** https://store.rakwireless.com/products/wisblock-base-board-rak19003
- **Project repo:** https://github.com/mindattic/ChiMesh

---

## Summary stack

| Layer | What it is |
|-------|-----------|
| Radio | Semtech SX1262 LoRa, 915 MHz US ISM |
| MCU | Nordic nRF52840 (ARM Cortex-M4F @ 64 MHz) |
| Board | {{BOARD_LABEL}} on {{BASE_BOARD_LABEL}} |
| Firmware | {{MESHTASTIC_FIRMWARE_LABEL}} (stock, unmodified) |
| Mesh protocol | Meshtastic managed flood routing |
| Power | 5 V / 2 W solar → TP5000 (LFP-configured) → LiFePO4 18650 |
| App / config | Meshtastic mobile/desktop over BLE, or `meshtastic` CLI over USB |
| Enclosure | IP65 ABS junction box, M12 gland for solar lead |

---

## Update Notes

### 2026.05.22l

- **RAK4631 listen-current numbers reconciled with §6.3.** The part card previously said *"Listens at ~7 mA"* in its note and *"~6–8 mA listening"* in its spec table — both pre-dated the §6.3 power-budget section added in `.k`, which gave the realistic combined figure (~8–12 mA: SX1262 ~4.6 mA RX + nRF52840 ~3–6 mA active). The card now matches §6.3, with the Heltec V3 comparison preserved as the "why this board" pitch.
- **LFP termination voltage standardized to 3.65 V.** The top callout (rule #2) and `parts.json` _description correctly use 3.65 V (the LiFePO4 charge-cutoff spec), but the cell-card spec row still said *"3.6 V termination."* That 50 mV gap is the difference between "topped off" and "starting to plate"; aligned to 3.65 V across the BOM.
- **RAK19003 JST pitch corrected.** Card spec said *"JST-PHR-2 (2.5 mm pitch)"* — JST PH series is 2.0 mm pitch (PHR-2 = PH series, with retention, 2-pin). The consumables card already used the correct 2.0 mm. Fixed the rak19003 row to match.
- **AS923 frequency in antenna note.** Said *"433 MHz for AS923"* — that's wrong. AS923 is 920–925 MHz; 433 MHz is a separate regional band and not what an AS923 antenna ships tuned for. Corrected to 920–925 MHz.
- **§6.3 cell capacity matches the BOM.** The new power-budget paragraph claimed *"3000 mAh LFP cell"* but the BOM ships a single IFR18650 at ~1500 mAh typical. Rewrote to use the actual 1500 mAh cell and added the December reality-check: 1.5 peak sun hours × 2 W ≈ 150–200 mAh/day in vs ~250 mAh/day draw — a genuine deficit in the worst Chicago weeks. Documents the two escape paths (parallel second cell → ~3000 mAh, or step up to 5 W panel) instead of pretending the budget is comfortable.
- **§6.3 panel rating matches the BOM.** Same paragraph said *"5 W panel"* — the BOM ships a 5 V / 2 W panel. Standardized the in-paragraph language to "5 V / 2 W" so the math (2 W × peak sun hours) actually corresponds to the part the reader bought. The 5 W upgrade path is now an explicit "if this isn't enough" pointer, not the assumed default.
- **§07.4 healthcheck description trimmed.** Said the script *"reports the count of known peers + the last-heard timestamps"* — it doesn't report timestamps, only the peer count + region/role/channel. Description now matches `healthcheck-mesh.ps1` behavior verbatim.
- **`provision-node.ps1` read-back is now anchored at word boundaries.** The post-write confirmation used `[regex]::Escape($Region)` and `[regex]::Escape($Role)` on bare substrings, so `Region=US` was satisfied by `USB`, `USE`, or any other US-prefixed token in the verbose `--info` output — a silent false-pass. Region and Role now require `\b…\b`; Channel stays a substring match because user-chosen channel names can contain punctuation that breaks word-boundary semantics.
- **Solar Voc figure unified at 6.5 V.** The §08 troubleshooting "Solar isn't keeping up" step said the panel should read *"~6 V"* open-circuit; `parts.json` (solar-panel-5v-2w) correctly says ~6.5 V Voc. Three places now agree: panel card, multimeter tool note, and the troubleshooting step (~6.5 V Voc, ~5 V loaded).
- **§3.1 Tools — multimeter parenthetical aligned.** Said "panel output (~6 V Voc)"; tightened to "(~6.5 V Voc)" so the value matches the panel card and the §08 troubleshooting step bumped in the previous bullet.

### 2026.05.22k

- **Power-budget subsection.** Added §6.3 with the rough current draw for the RAK4631 (SX1262 ~4.6 mA RX + nRF52840 ~3–6 mA active = ~8–12 mA average at 3.3 V, ~120 mA TX bursts, ~200–280 mAh/day). Explains why the 3000 mAh LFP + 5 W panel works in Chicago summer but tightens in December — and grounds the §6.2 "tilt ~41°, never flat" panel-aim rule in actual numbers instead of asserting it.

### 2026.05.22j

- **MindAttic.UiUx rename + re-sync.** Sibling components repo was renamed; `deploy.ps1`'s sync step now points at the new path and the spliced fonts/CSS were re-pulled. Stamp-only republish — no guide content changed.

### 2026.05.22i

- **Deploy now pulls subscribed components first.** `deploy.ps1` runs `MindAttic.UiUx/sync/sync-chimesh.ps1` before the version bump, so every deploy picks up the latest fonts and shared CSS from the sibling components repo without a manual sync step. Pass `-NoSync` (or skip if the components repo isn't checked out next to ChiMesh) and the deploy proceeds against whatever is already spliced into `build-html.js`. `.claude/commands/deploy.md` updated to describe the full 5-step flow.

### 2026.05.22h

- **TOC positioning.** `.toc` is now `position: absolute; top: 60px;` so the contents panel docks at a fixed offset from the top of the page instead of flowing inline.

### 2026.05.22g

- **`provision-node.ps1` docstring fix.** Top synopsis claimed it sets the PSK; it does not (and never has). Updated to match the actual behavior — sets region, role, channel-zero name, and owner; PSK stays at Meshtastic's default.
- **`provision-node.ps1` dead code removed.** Dropped an `$idLine` assignment that captured an `Owner` / `My info` regex match and then never used it.
- **`provision-node.ps1` reboot wait is now a poll, not a magic sleep.** Replaced the unexplained `Start-Sleep -Seconds 3` after a config write with a 5×2s retry loop against `meshtastic --info`, with a comment naming the constraint (USB-CDC re-enumeration on Windows can take up to ~8 s after an nRF52840 reboot).
- **`healthcheck-mesh.ps1` peer-count parse is now version-resilient.** Was matching the meshtastic CLI's ASCII-table border (`^\s*\|\s*\d+\s*\|`), which has changed shape across CLI versions. Now counts unique Meshtastic node IDs (`!XXXXXXXX` 8-hex-char tokens) in the output instead.
- **`healthcheck-mesh.ps1` channel-name parse no longer false-positives.** The previous `name:…` regex was greedy enough to match owner name, board name, or region name first depending on output ordering. Replaced with a precise match on the `channelName=` query parameter embedded in the Primary channel URL.
- **`deploy.ps1` no longer hard-codes `--insecure`.** Curl's TLS-cert bypass is now configurable via `FtpInsecure` in `deploy.settings.json` (default `true` for back-compat with shared-hosting FTPS endpoints, which usually serve a cert that doesn't match the FTP host). Template documents how to flip it off.
- **`deploy.ps1` refuses to deploy without a valid `*Last updated:*` line.** A missing or malformed version stamp used to log a warning and continue, which could ship un-versioned builds. Now hard-fails (`exit 1`) so every deploy guarantees a version bump that pairs with its Update Notes entry.

### 2026.05.22f

- **Rule #2 clarified.** The top callout previously read *"Never plug USB-C into the RAK19003 with an LFP cell installed,"* which implied you could never re-flash a deployed node. Rewritten to *"…while the LFP cell is wired into the JST,"* with a pointer to the §6.1 unplug-JST → plug-USB-C re-flash procedure that was already documented further down.
- **Voltage figures normalized.** Three places in the MD said the RAK19003 charger pushes "4.3 V max" while `config/parts.json` correctly used "4.2 V termination." Standardized to 4.2 V (the actual Li-ion termination spec) across the guide.
- **Cross-reference fix.** `config/parts.json`'s top-level `_description` pointed at "section 03 for the workflow" — but the LFP-protection workflow lives in §6.1 (§03 only has the don't-install-yet warning). Updated to point at §6.1.

### 2026.05.22e

- **Custom fonts baked in.** Outfit (variable, 100–900) now drives body text site-wide; the Attic display face renders the `#chimesh` page title. Both fonts are base64-inlined into the HTM via `MindAttic.UiUx/sync/sync-chimesh.ps1`, so the guide stays a single self-contained file with no external font requests.

### 2026.05.22d

- **Back-filled .c update notes.** The .c build (preview-image rollout) deployed without a corresponding entry below. Added retroactive notes for .c so the changelog is contiguous.

### 2026.05.22c

- **Part-card preview images.** All ten core parts now show a product photo on their card in the shopping list: RAK4631, RAK19003, LiFePO4 cell, 18650 holder, TP5000, 5V/2W panel, 915 MHz SMA antenna, IPEX→SMA pigtail, IP65 enclosure, M12 gland. Images are base64-encoded into a per-pid CSS rule by `build-html.js` (reads `imageFile` from `config/parts.json`), so the HTM stays single-file with no external asset fetches.

### 2026.05.22b

- **Second-pass review.** Added the two non-negotiable rules to the top callout (LFP-not-Li-ion + never-USB-C-with-cell-installed).
- **Workflow re-sequenced.** Cell installation moved from section 03 step 8 to a new section 6.1, so the user flashes (section 04) and provisions (section 05) over USB-C while the cell holder is still empty. Prevents the RAK19003's 4.2 V Li-ion charger from overcharging an LFP cell.
- **Added Tools subsection** (3.1) listing soldering iron, multimeter, drill+bits, heat gun, wire strippers, JST crimp tool, Phillips screwdriver. New `tools` category in `config/parts.json` with one card each (excluded from the per-node total via `inTotal: false`).
- **Added consumables.** Heat-shrink tubing assortment and 60/40 rosin-core solder — both excluded from the per-node total since they're one-time / shared.
- **Pigtail fix.** RAK's `u-fl-to-rp-sma-cable` is RP-SMA (wrong for LoRa). Removed from the IPEX→SMA part's tier list; replaced with Rokland's correct SMA cable. Added an explicit SMA-vs-RP-SMA warning to the pigtail's note and to section 03 step 6.

### 2026.05.22a

- **First real content.** Replaced the Claudia-derived scaffold (PiSugar voice assistant) with the ChiMesh v0 proof-of-mesh build: three solar-powered RAK4631 nodes in IP65 enclosures.
- **New config axes:** region (LoRa band), node role, deployment scenario, antenna gain. Conditional sections show region-specific and deployment-specific advice as the user toggles axes.
- **Real BOM with compatibility-checked links.** Ten parts, each with Official / Amazon / Reputable tiered links and a Google Shopping search. Signal path verified end-to-end: solar → TP5000 (LFP) → LFP cell → RAK19003 → RAK4631 → IPEX → SMA → antenna.
- **Scripts swapped.** Removed Pi-flavored chatbot install + healthcheck (irrelevant — Meshtastic nodes are microcontrollers, no shell). Added `scripts/cli/provision-node.ps1` and `scripts/cli/healthcheck-mesh.ps1` that drive the `meshtastic` CLI over USB.
