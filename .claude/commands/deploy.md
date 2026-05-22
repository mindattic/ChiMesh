Deploy the ChiMesh build guide to the FTP server (mindattic.com/chimesh/). Run the following command and report the result:

```
cmd /c "D:/Projects/MindAttic/ChiMesh/scripts/cli/deploy.bat"
```

This rebuilds `ChiMesh.htm` from `ChiMesh.md`, stamps it with the current UTC timestamp, clones it byte-for-byte to `index.htm` so `mindattic.com/chimesh/` serves the full guide directly (no redirect hop), and FTP-uploads all three files to `/mindattic.com/chimesh/`:

- `ChiMesh.md` — the canonical markdown source
- `ChiMesh.htm` — the self-contained styled page
- `index.htm` — byte-identical clone of `ChiMesh.htm`

After running, summarize how many files were uploaded successfully and flag any failures.
