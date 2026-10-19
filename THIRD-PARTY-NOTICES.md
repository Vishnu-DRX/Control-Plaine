# Third-party notices

Control-Plaine's own work is licensed as stated in [LICENSE](LICENSE). The items below belong to other people and keep their own terms. These items are not covered by the MIT licence: the SignalRGB, DeepCool and Playnite artwork belongs to its owners and is used only to label the buttons that open those programs. Status notes what is still being confirmed.

## Bundled in this repository

| Item | Where | Owner and licence | Status |
| --- | --- | --- | --- |
| Lucide icons (stroke style, several shapes) | `docs/icons/*.svg`, rendered to `@Resources/Icons/*.png` | Lucide Contributors; ISC licence (text below). Parts derived from Feather, MIT. | Many icons were redrawn or edited (stroke width, shape). Confirm which files are unmodified Lucide, which are derived and which are original. |
| Xbox controller outline | `docs/icons/controller-xbox.svg` | Named "Fluent, MIT" in `docs/DESIGN-V1.md`: Microsoft Fluent UI System Icons, MIT licence. | Confirm the source; add the MIT notice (Copyright Microsoft Corporation) if confirmed. |
| SignalRGB app icon | `docs/icons/signalrgb-src.png`, `@Resources/Icons/signalrgb.png` | Owned by SignalRGB (WhirlwindFX). Used only to label the button that opens that program. | Trademark/logo, not open licensed. Maintainer to accept or replace with a generic icon. |
| DeepCool logo | `docs/icons/deepcool.svg`, `@Resources/Icons/deepcool.png` | Trademark of DeepCool. Traced by hand. | As above. |
| Playnite controller art | `docs/icons/playnite-controller-src.png`, `@Resources/Icons/playnite-controller.png` | From the Playnite project (MIT licence for the code; confirm for the artwork). | Confirm. |
| Controller, steering wheel and case drawings | `controller-dualsense`, `wheel-moza`, `case-screen` icons | Generic outline drawings of products by Sony, Moza and DeepCool. No vendor artwork is copied. | Original drawings; names are used only to say what the skin works with. |
| Some icons carry an embedded Content Credentials (C2PA) manifest | 26 files, listed in `docs/reviews/WP-P-public-readiness.md` | Provenance metadata only, no licence effect. | Harmless; may be stripped. |

## Downloaded or installed separately (never committed)

| Item | How it arrives | Licence |
| --- | --- | --- |
| MediaPlayer plugin (i2002/RainmeterMediaPlayer v1.4) | `tools/install.ps1` or the setup window downloads the pinned release to `%APPDATA%\Rainmeter\Plugins` | GPL-3.0 |
| IsFullScreen plugin | copied from the user's own `Skins\@Vault` | Rainmeter plugin; see its own licence |
| Ookla Speedtest CLI | `winget install Ookla.Speedtest.CLI` | Proprietary, Ookla terms (accepted on first run) |
| Fan Control (Rem0o), HWiNFO, SignalRGB, DeepCool software, Playnite, DSX, Moza Pit House, Rainmeter | installed by the user | Their own licences; Control-Plaine only starts or reads them |

No `.dll`, `.exe` or archive is committed; `python tools/lint.py` (rule P2) fails if one is.

## Fonts

Segoe UI and Segoe UI Variable come with Windows and are not included.

## Lucide licence (ISC)

ISC License

Copyright (c) for portions of Lucide are held by Cole Bemis 2013-2022 as part of Feather (MIT). All other copyright (c) for Lucide are held by Lucide Contributors 2022.

Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted, provided that the above copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
