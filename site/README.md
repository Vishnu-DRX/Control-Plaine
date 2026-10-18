# Control-Plaine site

Single-page showcase. Static HTML, CSS and a few lines of JS; no build step and no external requests.

Preview: `python -m http.server -d site 8000` and open http://localhost:8000.

Skin demos are HTML/SVG illustrations built from `docs/icons/*.svg` and the tokens in `@Resources/Theme.inc` (copied into `style.css`; keep them in step). Real screenshots can be added later next to the illustrations.

Deploy: `.github/workflows/pages.yml` is manual-only and guarded. It does nothing until Vishnu enables Pages and sets the repository variable `PAGES_ENABLED` to `true`.
