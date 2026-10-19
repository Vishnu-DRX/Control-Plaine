# Control-Plaine helper: MediaPlayer.dll for the Media skin.
# Listed in @Resources\Setup\Helpers.txt (id mediaplayer); run by tools\install.ps1
# and by the first-run setup (RUN IT FOR ME). i2002/RainmeterMediaPlayer v1.4
# (GPL-3.0), 64-bit build, downloaded into Rainmeter's own Plugins folder.
# The package is checked against the SHA-256 pinned below before anything is
# unpacked; a different file is deleted and nothing is installed.
$ErrorActionPreference = 'Stop'
# SHA-256 of the v1.4 release assets (matches the digest GitHub lists for them).
$pinned = @{
    'MediaPlayer_v1.4_static.rmskin' = '096317d6a73b9b66342e3860e9bb94439ea872190e8d90fc161a1669bb8dc607'
    'MediaPlayer_v1.4.rmskin'        = '8a21d9709e76f4737831935e34ab24eaf061002837e2330cc602a993ecc0a42f'
}
$plugins = Join-Path $env:APPDATA 'Rainmeter\Plugins'
$mediaDll = Join-Path $plugins 'MediaPlayer.dll'

# An earlier installer saved the .rmskin package itself as MediaPlayer.dll
# (Rainmeter then logs "Unable to load ... error 193"). Replace anything that
# is not a real DLL (a DLL starts with "MZ").
if ((Test-Path $mediaDll) -and
    (-join [char[]]([IO.File]::ReadAllBytes($mediaDll) | Select-Object -First 2)) -ne 'MZ') {
    Remove-Item $mediaDll
    Write-Host "Removed a broken MediaPlayer.dll."
}
if (Test-Path $mediaDll) {
    Write-Host "MediaPlayer.dll is already installed."
    exit 0
}
try {
    New-Item -ItemType Directory -Force -Path $plugins | Out-Null
    $release = Invoke-RestMethod 'https://api.github.com/repos/i2002/RainmeterMediaPlayer/releases/tags/v1.4' -Headers @{ 'User-Agent' = 'Control-Plaine' }
    # v1.4 ships two .rmskin packages (plain and static). An .rmskin is a zip
    # with a footer; the plugin is in Plugins\64bit. Prefer the static build.
    $asset = $release.assets | Sort-Object {
        $n = $_.name.ToLower()
        -(([int]($n -match 'static')) * 2 + ([int]($n -match '\.(dll|zip|rmskin)$')))
    } | Select-Object -First 1
    $expected = $pinned[$asset.name]
    if (-not $expected) { throw "$($asset.name) is not a release asset this script knows (no pinned hash)" }
    $tmp = Join-Path $env:TEMP $asset.name
    Invoke-WebRequest $asset.browser_download_url -OutFile $tmp -UseBasicParsing
    $actual = (Get-FileHash $tmp -Algorithm SHA256).Hash.ToLower()
    if ($actual -ne $expected) {
        Remove-Item $tmp -Force
        throw "$($asset.name) does not match the pinned SHA-256 (got $actual), so it was deleted and nothing was installed"
    }
    if ($asset.name -match '\.(zip|rmskin)$') {
        # Expand-Archive only accepts a .zip extension.
        $zip = [IO.Path]::ChangeExtension($tmp, '.zip')
        if ($zip -ne $tmp) { Copy-Item $tmp $zip -Force }
        $dir = Join-Path $env:TEMP 'ControlPlaine-MediaPlayer'
        Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
        Expand-Archive $zip $dir -Force
        $dll = Get-ChildItem $dir -Recurse -Filter 'MediaPlayer.dll' |
            Where-Object { $_.FullName -notmatch '32bit' } |
            Sort-Object { -[int]($_.FullName -match '64') } |
            Select-Object -First 1
        if (-not $dll) { throw "no 64-bit MediaPlayer.dll in $($asset.name)" }
        Copy-Item $dll.FullName $mediaDll
    } else {
        Copy-Item $tmp $mediaDll
    }
    Write-Host "Installed MediaPlayer.dll. Restart Rainmeter (Exit, then start it) so it loads the new plugin."
} catch {
    Write-Host "Could not download MediaPlayer.dll ($_). Get the 64-bit build from https://github.com/i2002/RainmeterMediaPlayer/releases/tag/v1.4 and put it in $plugins, then restart Rainmeter."
    exit 1
}
