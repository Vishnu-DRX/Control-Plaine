# Control-Plaine site

Single-page showcase. Static HTML, CSS and a little JS; no build step and no external requests.

Preview: `python -m http.server -d site 8000` and open http://localhost:8000.

The desktop at the top draws every skin from the suite's own icons (`docs/icons/*.svg`, inlined as symbols in `index.html`), the Playnite and SignalRGB art (`img/`, copied from `@Resources/Icons`) and the tokens in `@Resources/Theme.inc` (copied into `style.css`; keep them in step). Hover, always-on details, left or right, light or dark and the accent follow the real skins; check a skin's guide in `docs/guide/` when changing how a demo behaves. Real screenshots can be added later.

Deploy: `.github/workflows/pages.yml` is manual-only and guarded.
