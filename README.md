# ChiMesh

**Chicago LoRa Meshtastic mesh — proof-of-mesh build.** Three solar-powered RAK4631 nodes in weatherproof IP65 enclosures that prove multi-hop LoRa routing across the city. About **~$62 per node** (so ~$186 for the proof batch of three), plus ~$25 in shared consumables (wire, JST, solder, heat-shrink) and any one-time tools you don't already own. No lamp disguise yet — that's v2 once the protocol is proven.

> **Two non-negotiable rules.**
>
> 1. **LiFePO4, not Li-ion.** Chicago winters charge below 0°C. Li-ion cells permanently plate lithium when charged that cold and can fail dangerously by summer. LFP is non-negotiable for any outdoor ChiMesh node.
> 2. **Never plug USB-C into the RAK19003 while the LFP cell is wired into the JST.** The RAK19003's onboard charger is Li-ion only (4.2 V termination) and will overcharge an LFP cell (3.65 V max). The safe re-flash procedure is in §6.1: unplug the JST-PHR-2, plug USB-C, do your work, unplug USB-C, plug the JST back in.

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
https://flash.meshtastic.org
```

### 4.2 Connect and flash

1. Plug the RAK19003's USB-C into your computer.
2. Click **Select Device**. Pick **RAK4631** from the dropdown.
3. Pick the latest stable Meshtastic 2.5.x build.
4. Pick **Region: US** (default; adjust if you're outside the US).
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

You should see meshtastic-python 2.5.x or newer.

### 5.2 Provision the node

Use the bundled provisioner — it walks one USB-connected node through the standard ChiMesh config:

```powershell
scripts\cli\provision-node.ps1 -NodeName chimesh-001
```

Or set each field manually:

```bash
meshtastic --set lora.region US
meshtastic --set device.role ROUTER_CLIENT
meshtastic --ch-set name "ChiMesh-Test" --ch-index 0
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

You should see the region you picked, the role you picked, and channel 0 named `ChiMesh-Test`.

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

Install the Meshtastic app — see https://meshtastic.org/docs/software/apps/ for the official download links. Pair with Node A over Bluetooth (default PIN is `123456` unless you changed it).

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
- December low-light is the close case. If a node won't survive the worst week, upgrade to a 5 W panel, or add a second LFP cell in parallel (~3000 mAh total) to ride through low-light stretches.

### Radio not responding via CLI
```powershell
scripts\cli\healthcheck-mesh.ps1 -Verbose
```
Reads the connected node and prints any error states from `--info`.

---

## Reference

- **Meshtastic firmware:** https://github.com/meshtastic/firmware
- **Meshtastic web flasher:** https://flash.meshtastic.org
- **Meshtastic apps (mobile + desktop):** https://meshtastic.org/docs/software/apps/
- **RAK4631 product page:** https://store.rakwireless.com/products/rak4631-lpwan-node
- **RAK19003 product page:** https://store.rakwireless.com/products/wisblock-base-board-rak19003
- **Project repo:** https://github.com/mindattic/ChiMesh

---

## Summary stack

| Layer | What it is |
|-------|-----------|
| Radio | Semtech SX1262 LoRa, 915 MHz US ISM |
| MCU | Nordic nRF52840 (ARM Cortex-M4F @ 64 MHz) |
| Board | RAK4631 (RAK Wireless WisBlock Core) on RAK19003 Mini Base |
| Firmware | Meshtastic 2.5.x (stock, unmodified) |
| Mesh protocol | Meshtastic managed flood routing |
| Power | 5 V / 2 W solar → TP5000 (LFP-configured) → LiFePO4 18650 |
| App / config | Meshtastic mobile/desktop over BLE, or `meshtastic` CLI over USB |
| Enclosure | IP65 ABS junction box, M12 gland for solar lead |
