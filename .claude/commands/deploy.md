Deploy the ChiMesh build guide to the FTP server (mindattic.com/chimesh/). Run the following command and report the result:

```
cmd /c "D:/Projects/MindAttic/ChiMesh/scripts/cli/deploy.bat"
```

This:

1. Pulls latest subscribed components (fonts, shared CSS) from sibling repo `MindAttic.Components/sync/sync-chimesh.ps1` into `scripts/cli/build-html.js` (pass `-NoSync` to skip if the components repo isn't checked out locally).
2. Bumps the per-build letter in `ChiMesh.md`'s `*Last updated:*` line.
3. Rebuilds `ChiMesh.htm` from `ChiMesh.md`.
4. Stamps the HTM with the current UTC timestamp and clones it byte-for-byte to `index.htm` so `mindattic.com/chimesh/` serves the full guide directly (no redirect hop).
5. FTP-uploads all three files to `/mindattic.com/chimesh/`:
   - `ChiMesh.md` — the canonical markdown source
   - `ChiMesh.htm` — the self-contained styled page
   - `index.htm` — byte-identical clone of `ChiMesh.htm`

After running, summarize how many files were uploaded successfully and flag any failures.
