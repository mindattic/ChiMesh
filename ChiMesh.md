# ChiMesh

_[Tagline TBD — a 2–3 sentence pitch goes here. This paragraph occupies the same visual slot as Claudia's intro: short, dense, links the reader to what they'll have at the end. Placeholder text only; real copy lands once the spec stabilises.]_

> **Heads-up.** This `>` block renders as a sidebar callout. Use it for the one constraint a first-time builder is most likely to miss. Placeholder only.

[github.com/mindattic/ChiMesh](https://github.com/mindattic/ChiMesh)

*Last updated: 2026.05.22a*

---

## 01. Configure

<!-- CONFIG-WIDGET -->

---

## 02. Shopping list

<!-- PARTS-GALLERY -->

---

## 03. Assemble

**Total time:** _~TBD minutes._

1. Step one placeholder — short, imperative voice.
2. Step two placeholder — call out one specific pin / port / cable.
3. Step three placeholder — visual sanity check before powering on.

<!-- when: tier=portable -->
4. Optional step for the portable tier — appears only when that configurator option is selected.
<!-- end -->
<!-- when: tier=stationary -->
**Stationary layout placeholder** — appears only when that configurator option is selected.
<!-- end -->

✅ **Checkpoint:** _[What "done" looks like for this section — one observable signal.]_

---

## 04. Flash microSD

### 4.1 Install imager

Placeholder text for installing the flashing tool.

### 4.2 Flash

1. Open the imager.
2. Pick the device.
3. Pick the OS image.
4. Pick the storage target.
5. Set hostname, user, password, Wi-Fi, locale.
6. Write.

### 4.3 First boot

```bash
ssh user@chimesh.local
```

✅ **Checkpoint:** _[Shell prompt is reachable.]_

---

## 05. System setup

### 5.1 Update

```bash
sudo apt update && sudo apt full-upgrade -y
```

### 5.2 Install dependencies

```bash
sudo apt install -y git curl build-essential
```

✅ **Checkpoint:** _[Dependencies present.]_

---

## 06. Install software

```bash
cd ~
git clone https://github.com/mindattic/ChiMesh.git
cd ChiMesh
bash install.sh
```

You should see `{{NODE_LABEL}}` or newer.

✅ **Checkpoint:** _[Installer exits clean.]_

---

## 07. API key

1. Visit the provider console.
2. Add billing.
3. Create a key named `chimesh`. Copy it now — you can't see it again.
4. Treat it like a password.

### Which model to pick

| Model ID | Speed | Quality | When to use |
|----------|-------|---------|-------------|
| `model-fast` | Fastest | Good | Default. |
| `model-balanced` | Medium | Excellent | Richer answers. |
| `model-best` | Slowest | Best | Hard reasoning only. |

---

## 08. Configure software

### 8.1 Create your `.env`

```bash
cp .env.template .env
nano .env
```

```env
API_KEY=replace-me
MODEL=model-fast
```

<!-- when: variant=a -->
**Variant A placeholder.** Appears only when variant A is picked.
<!-- end -->
<!-- when: variant=b -->
**Variant B placeholder.** Appears only when variant B is picked.
<!-- end -->

### 8.2 Build

```bash
bash build.sh
```

✅ **Checkpoint:** _[Build exits clean.]_

---

## 09. Healthcheck

```bash
bash ~/healthcheck.sh
```

✅ **Checkpoint:** _[All checks green.]_

---

## 10. Run

### Manual launch

```bash
bash run.sh
```

### Start on boot

```bash
bash startup.sh
sudo systemctl status chimesh.service
```

### Live logs

```bash
journalctl -u chimesh.service -f
```

---

## 11. Case

<!-- when: case=none -->
You picked **no case**. Placeholder text for the no-case path.
<!-- end -->
<!-- when: case=fdm,sla -->
Placeholder text for printed case options. Links to STL files will land here.
<!-- end -->

---

## 12. Troubleshooting

### Nothing works
- Placeholder symptom + fix.

### Something works but slowly
- Placeholder symptom + fix.

### Service won't start
```bash
sudo systemctl status chimesh.service --no-pager
journalctl -u chimesh.service -n 60 --no-pager
```

---

## Reference

- **Project repo:** https://github.com/mindattic/ChiMesh
- **Provider docs:** _TBD_
- **Pricing:** _TBD_

---

## Summary stack

| Layer | What it is |
|-------|-----------|
| Hardware | _TBD_ |
| OS | _TBD_ |
| Wake / trigger | _TBD_ |
| Transport | _TBD_ |
| Brain | _TBD_ |
| Service manager | _TBD_ |

---

## Update Notes

### 2026.05.22a

- **Scaffold imported.** Cloned the Claudia hardware-page layout into ChiMesh as a content-free shell so the look-and-feel can be reviewed before real copy lands. Every section header, callout style, code block, table, checkpoint, and configurator hook is in place with placeholder text. Real content lands incrementally after this scaffold is checked in.
