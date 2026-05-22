# ChiMesh

**Chicago LoRa Meshtastic mesh — proof-of-mesh build.** Three solar-powered RAK4631 nodes in weatherproof IP65 enclosures that prove multi-hop LoRa routing across the city. Total ~$192 for the proof batch (parts per node × 3 + shared consumables). No lamp disguise yet — that's v2 once the protocol is proven.

> **Heads-up: LiFePO4, not Li-ion.** Chicago winters charge below 0°C. Li-ion cells permanently plate lithium when charged that cold and can fail dangerously by summer. LFP is non-negotiable for any outdoor ChiMesh node — see the cell row in the shopping list.

[github.com/mindattic/ChiMesh](https://github.com/mindattic/ChiMesh)

*Last updated: 2026.05.22b*

---

## 01. Configure

<!-- CONFIG-WIDGET -->

---

## 02. Shopping list

The total below is **per node**. Multiply by your planned node count — minimum 3 to actually prove multi-hop routing (otherwise there's no chain to forward through). Consumables are shared across all nodes, not per-node.

<!-- PARTS-GALLERY -->

---

## 03. Assemble

**Total time:** *~30 minutes per node, once parts are in hand.*

The wiring is one signal path with two sub-paths:

```
Solar panel  →  TP5000 (LFP jumper set!)  →  LiFePO4 cell  →  JST-PHR-2  →  RAK19003  →  RAK4631
RAK4631 IPEX  →  pigtail  →  SMA bulkhead  →  915 MHz antenna
```

1. **Set the TP5000 jumper to LFP (3.6 V).** This is the single most important step. The board ships with the jumper in either position; LFP termination is usually labeled `4.2/3.6` or `Li-ion/LiFePO4`. Wrong jumper = dead cell in weeks.
2. **Solder the solar panel leads to the TP5000 `IN+` / `IN-` pads.** Red to `+`, black to `-`. Heat-shrink the joint — the enclosure isn't fully sealed if the panel cable enters with bare conductors.
3. **Solder the LFP cell holder leads to the TP5000 `BAT+` / `BAT-` pads.** Don't insert the cell yet.
4. **Crimp a JST-PHR-2 onto a short pair of 22 AWG wires**, then solder the other end of those wires to the TP5000's `BAT+` / `BAT-` pads (in parallel with the cell-holder leads). This is the output that feeds the RAK19003.
5. **Snap the RAK4631 onto the RAK19003 Mini Base.** Align the silk-screen markers, press until the board-to-board connector seats fully.
6. **Connect the IPEX pigtail.** The u.FL connector on the RAK4631 is fragile — press straight down with a thumbnail until it clicks. Mount the SMA bulkhead end through the drilled hole in the top of the enclosure (panel nut on the outside).
7. **Plug the JST-PHR-2 from the TP5000 into the RAK19003 battery input.** It only fits one way.
8. **Insert the LFP cell.** The RAK19003 red LED should blip briefly. If you've already flashed firmware, the RAK4631 user LED may pulse; blank is also fine — firmware lands in section 04.
9. **Mount everything inside the enclosure.** Foam-tape the TP5000 to one wall, the RAK19003 + Mini Base to the opposite wall, the cell holder along the floor. Route the panel cable out through the M12 gland.
10. **Visual sanity check.** Antenna is vertical when the enclosure is mounted in its final orientation. No bare wire near the SMA bulkhead. Cell is seated and the holder spring is in contact.

<!-- when: deployment=rooftop -->
**Rooftop note.** Grounding is a real concern when the antenna is your highest point. Add a gas-discharge tube (GDT) lightning arrestor on the SMA line before the radio — cheap insurance for a board you can't easily reach.
<!-- end -->

✅ **Checkpoint:** *Cell installed, RAK19003 red LED blipped on power-up, antenna threaded through enclosure wall, panel cable sealed at the gland.*

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

Connects to whichever node is on the USB cable, queries `--info`, and reports the count of known peers + the last-heard timestamps. Use it as a one-shot sanity check before calling the deployment done.

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
- Confirm the panel is generating: disconnect from the TP5000, measure open-circuit voltage in sunlight — should be ~6 V.
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

### 2026.05.22a

- **First real content.** Replaced the Claudia-derived scaffold (PiSugar voice assistant) with the ChiMesh v0 proof-of-mesh build: three solar-powered RAK4631 nodes in IP65 enclosures.
- **New config axes:** region (LoRa band), node role, deployment scenario, antenna gain. Conditional sections show region-specific and deployment-specific advice as the user toggles axes.
- **Real BOM with compatibility-checked links.** Ten parts, each with Official / Amazon / Reputable tiered links and a Google Shopping search. Signal path verified end-to-end: solar → TP5000 (LFP) → LFP cell → RAK19003 → RAK4631 → IPEX → SMA → antenna.
- **Scripts swapped.** Removed Pi-flavored chatbot install + healthcheck (irrelevant — Meshtastic nodes are microcontrollers, no shell). Added `scripts/cli/provision-node.ps1` and `scripts/cli/healthcheck-mesh.ps1` that drive the `meshtastic` CLI over USB.
