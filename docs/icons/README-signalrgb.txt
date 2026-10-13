signalrgb-src.png is SignalRGB's own app icon (from %LOCALAPPDATA%\VortxEngine\app.ico, 192 px).
@Resources\Icons\signalrgb.png is made from it: alpha = max(R,G,B) with the rounded-square
margin cropped (source pixels 12..178), white, drawn 22.5 px inside a 40 px box (1.25 boost).
It is a PNG source, not an .svg, so tools/render-icons.js never overwrites it. Don't add a
docs/icons/signalrgb.svg.
