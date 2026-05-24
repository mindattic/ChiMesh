Deploy the ChiMesh landing page (`mindattic.com/chimesh.htm`) via **MindAttic.Deploy** (sibling repo at `D:\Projects\MindAttic\MindAttic.Deploy`).

This now uses the standard catalog pipeline: `README.md` is rendered through `template/index.template.htm` with the `Hardware` theme and FTPS-uploaded as a single file. The old 3-file long-form-guide pipeline (`scripts/cli/deploy.ps1` + marker-block splicing + `/chimesh/` subfolder) is retired.

Run this command and report the result:

```
powershell -NoProfile -ExecutionPolicy Bypass -Command "cd D:\Projects\MindAttic\MindAttic.Deploy; npm run deploy -- --only chimesh"
```

It will:

1. Render `D:\Projects\MindAttic\ChiMesh\README.md` through the catalog template (Hardware theme, MindAttic.UIUX components loaded via jsDelivr).
2. FTPS-upload `out/chimesh.htm` to `/mindattic.com/chimesh.htm`.

After running, summarize the result and flag any failures.

Notes:
- Catalog entry: `MindAttic.Deploy/projects.json` -> `projects[]` slug `chimesh` (theme: Hardware).
- Credentials: `MindAttic.Deploy/secrets/ftp.json` (gitignored).
- `scripts/cli/` in this repo is dead code awaiting cleanup -- do not invoke `deploy.bat` / `deploy.ps1` from here.
- Old subfolder URL `mindattic.com/chimesh/` still exists on the FTP server until you manually delete it.
