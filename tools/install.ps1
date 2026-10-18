# Control-Plaine installer.
# Run from the repo folder: powershell -ExecutionPolicy Bypass -File tools\install.ps1
# Links the repo into the Rainmeter Skins folder, creates User.inc, installs the layout and loads it.

param(
    # Also install the Ookla Speedtest CLI (winget) for the Wi-Fi skin's SPEED TEST link.
    [switch]$WithSpeedtest
)
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$skins = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'Rainmeter\Skins'
$target = Join-Path $skins 'Control-Plaine'
$layouts = Join-Path $env:APPDATA 'Rainmeter\Layouts'
$rainmeter = Join-Path $env:ProgramFiles 'Rainmeter\Rainmeter.exe'

# 1. Put the suite in the Skins folder (a junction, so git pull updates it in place).
if ((Resolve-Path $repo).Path -ne $target) {
    if (Test-Path $target) {
        $item = Get-Item $target -Force
        $linked = $item.LinkType -eq 'Junction' -and (Resolve-Path ($item.Target | Select-Object -First 1)).Path -eq (Resolve-Path $repo).Path
        if (-not $linked) {
            throw "$target already exists and is not a link to this repo ($repo). Rename or delete it, then run this again."
        }
        Write-Host "Skins\Control-Plaine is already linked to this repo."
    } else {
        New-Item -ItemType Junction -Path $target -Target $repo | Out-Null
        Write-Host "Linked $target -> $repo"
    }
}

# 2. Personal settings and runtime state (both git-ignored). Defaults live in
#    @Resources\Defaults.inc and <Skin>\Defaults.inc; the Settings skin writes
#    changes to User.inc.
foreach ($name in 'User.inc', 'State.inc') {
    $file = Join-Path $repo "@Resources\$name"
    if (-not (Test-Path $file)) {
        Set-Content -Encoding ascii $file "; Control-Plaine $name (not committed).`r`n[Variables]"
        Write-Host "Created @Resources\$name"
    }
}

# 2a. IsFullScreen.dll (hide skins while a full-screen app is in front). A copy
#     ships in Skins\@Vault from an earlier .rmskin; Rainmeter loads plugins
#     from %APPDATA%\Rainmeter\Plugins, so copy the 64-bit build there.
$plugins = Join-Path $env:APPDATA 'Rainmeter\Plugins'
$fullDll = Join-Path $plugins 'IsFullScreen.dll'
if (-not (Test-Path $fullDll)) {
    $vault = Get-ChildItem (Join-Path $skins '@Vault\Plugins\IsFullScreen') -Recurse -Filter 'IsFullScreen.dll' -ErrorAction SilentlyContinue |
        Where-Object { $_.DirectoryName -like '*64bit*' } | Sort-Object FullName -Descending | Select-Object -First 1
    if ($vault) {
        New-Item -ItemType Directory -Force -Path $plugins | Out-Null
        Copy-Item $vault.FullName $fullDll
        Write-Host "Installed IsFullScreen.dll. Restart Rainmeter so it loads the new plugin."
    } else {
        Write-Host "IsFullScreen.dll not found. Install the IsFullScreen plugin (64-bit) into $plugins, or turn off Hide in full screen."
    }
}

# 2b. MediaPlayer.dll for the Media skin (i2002/RainmeterMediaPlayer v1.4, GPL-3.0,
#     64-bit). Not committed; downloaded into Rainmeter's own Plugins folder.
$mediaDll = Join-Path $plugins 'MediaPlayer.dll'
# An earlier installer saved the .rmskin package itself as MediaPlayer.dll
# (Rainmeter then logs "Unable to load ... error 193"). Replace anything that
# is not a real DLL (a DLL starts with "MZ").
if ((Test-Path $mediaDll) -and
    (-join [char[]]([IO.File]::ReadAllBytes($mediaDll) | Select-Object -First 2)) -ne 'MZ') {
    Remove-Item $mediaDll
    Write-Host "Removed a broken MediaPlayer.dll."
}
if (-not (Test-Path $mediaDll)) {
    try {
        New-Item -ItemType Directory -Force -Path $plugins | Out-Null
        $release = Invoke-RestMethod 'https://api.github.com/repos/i2002/RainmeterMediaPlayer/releases/tags/v1.4' -Headers @{ 'User-Agent' = 'Control-Plaine' }
        # v1.4 ships two .rmskin packages (plain and static). An .rmskin is a zip
        # with a footer; the plugin is in Plugins\64bit. Prefer the static build.
        $asset = $release.assets | Sort-Object {
            $n = $_.name.ToLower()
            -(([int]($n -match 'static')) * 2 + ([int]($n -match '\.(dll|zip|rmskin)$')))
        } | Select-Object -First 1
        $tmp = Join-Path $env:TEMP $asset.name
        Invoke-WebRequest $asset.browser_download_url -OutFile $tmp -UseBasicParsing
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
    }
}

# 2c. Ookla Speedtest CLI for the Wi-Fi skin's SPEED TEST link.
if (-not (Get-Command speedtest.exe -ErrorAction SilentlyContinue) -and
    -not (Test-Path (Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Links\speedtest.exe'))) {
    if ($WithSpeedtest -and (Get-Command winget.exe -ErrorAction SilentlyContinue)) {
        winget install --id Ookla.Speedtest.CLI -e --accept-source-agreements --accept-package-agreements
        if ($LASTEXITCODE -ne 0) { Write-Host "winget could not install the Ookla Speedtest CLI (exit $LASTEXITCODE)." }
    } else {
        Write-Host "speedtest.exe not found. For the Wi-Fi SPEED TEST link run this installer with -WithSpeedtest, or install the Ookla Speedtest CLI and set its path in Settings > WI-FI."
    }
}

# 3. Back up the current desktop as a layout, then install the Control-Plaine layout.
#    Every run backs up (the name has the time), and a Control-Plaine layout
#    the user saved from Rainmeter is kept too, before it is overwritten.
$stamp = Get-Date -Format 'yyyy-MM-dd HH-mm-ss'
$currentIni = Join-Path $env:APPDATA 'Rainmeter\Rainmeter.ini'
if (Test-Path $currentIni) {
    $backup = Join-Path $layouts "Before Control-Plaine $stamp"
    New-Item -ItemType Directory -Path $backup | Out-Null
    Copy-Item $currentIni $backup
    Write-Host "Saved current desktop as layout '$(Split-Path -Leaf $backup)'"
}
$dest = Join-Path $layouts 'Control-Plaine'
if (Test-Path (Join-Path $dest 'Rainmeter.ini')) {
    $old = Join-Path $layouts "Control-Plaine before update $stamp"
    New-Item -ItemType Directory -Path $old | Out-Null
    Copy-Item (Join-Path $dest 'Rainmeter.ini') $old
    Write-Host "Kept your Control-Plaine layout as '$(Split-Path -Leaf $old)'"
}
New-Item -ItemType Directory -Force -Path $dest | Out-Null
Copy-Item (Join-Path $repo 'Layouts\Control-Plaine\Rainmeter.ini') $dest -Force

# 4. Load it.
if (Test-Path $rainmeter) {
    & $rainmeter '!LoadLayout' 'Control-Plaine'
    Write-Host "Loaded the Control-Plaine layout."
} else {
    Write-Host "Rainmeter.exe not found. Load the layout from Manage > Layouts."
}
