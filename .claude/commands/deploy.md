# /deploy -- no web deploy

**ChiMesh has no web deploy.** Its README on GitHub -- https://github.com/mindattic/ChiMesh -- is the project page. To update the project page, edit `README.md` and push to `main`.

MindAttic.Deploy does not handle ChiMesh (`npm run deploy -- --only chimesh` is rejected), so do not run it for this project.

The README is a static page. Its parts table is maintained by hand from `config/parts.json`, the canonical parts/price data; when a part or price changes, update both. There is no interactive configurator.

When invoked, tell the user the above and stop.
