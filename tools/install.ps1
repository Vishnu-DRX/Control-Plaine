# Control-Plaine installer.
# Run from the repo folder: powershell -ExecutionPolicy Bypass -File tools\install.ps1
# Links the repo into the Rainmeter Skins folder, creates User.inc, installs the layout and loads it.

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$skins = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'Rainmeter\Skins'
$target = Join-Path $skins 'Control-Plaine'
$layouts = Join-Path $env:APPDATA 'Rainmeter\Layouts'
$rainmeter = Join-Path $env:ProgramFiles 'Rainmeter\Rainmeter.exe'

# 1. Put the suite in the Skins folder (a junction, so git pull updates it in place).
if ((Resolve-Path $repo).Path -ne $target) {
    if (Test-Path $target) {
        Write-Host "Skins\Control-Plaine already exists, leaving it as is."
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
if (-not (Test-Path $mediaDll)) {
    try {
        New-Item -ItemType Directory -Force -Path $plugins | Out-Null
        $release = Invoke-RestMethod 'https://api.github.com/repos/i2002/RainmeterMediaPlayer/releases/tags/v1.4' -Headers @{ 'User-Agent' = 'Control-Plaine' }
        # Prefer a 64-bit static build; accept a bare DLL or a zip holding one.
        $asset = $release.assets | Sort-Object {
            $n = $_.name.ToLower()
            -(([int]($n -match '64')) * 4 + ([int]($n -match 'static')) * 2 + ([int]($n -match '\.(dll|zip)$')))
        } | Select-Object -First 1
        $tmp = Join-Path $env:TEMP $asset.name
        Invoke-WebRequest $asset.browser_download_url -OutFile $tmp -UseBasicParsing
        if ($asset.name -like '*.zip') {
            $dir = Join-Path $env:TEMP 'ControlPlaine-MediaPlayer'
            Expand-Archive $tmp $dir -Force
            $dll = Get-ChildItem $dir -Recurse -Filter 'MediaPlayer.dll' |
                Sort-Object { -(([int]($_.FullName -match '64')) * 2 + [int]($_.FullName -match 'static')) } |
                Select-Object -First 1
            Copy-Item $dll.FullName $mediaDll
        } else {
            Copy-Item $tmp $mediaDll
        }
        Write-Host "Installed MediaPlayer.dll. Restart Rainmeter (Exit, then start it) so it loads the new plugin."
    } catch {
        Write-Host "Could not download MediaPlayer.dll ($_). Get the 64-bit build from https://github.com/i2002/RainmeterMediaPlayer/releases/tag/v1.4 and put it in $plugins, then restart Rainmeter."
    }
}

# 3. Back up the current desktop as a layout, then install the Control-Plaine layout.
$stamp = Get-Date -Format 'yyyy-MM-dd'
$backup = Join-Path $layouts "Before Control-Plaine $stamp"
if (-not (Test-Path $backup)) {
    New-Item -ItemType Directory -Path $backup | Out-Null
    Copy-Item (Join-Path $env:APPDATA 'Rainmeter\Rainmeter.ini') $backup
    Write-Host "Saved current desktop as layout '$(Split-Path -Leaf $backup)'"
}
$dest = Join-Path $layouts 'Control-Plaine'
New-Item -ItemType Directory -Force -Path $dest | Out-Null
Copy-Item (Join-Path $repo 'Layouts\Control-Plaine\Rainmeter.ini') $dest -Force

# 4. Load it.
if (Test-Path $rainmeter) {
    & $rainmeter '!LoadLayout' 'Control-Plaine'
    Write-Host "Loaded the Control-Plaine layout."
} else {
    Write-Host "Rainmeter.exe not found. Load the layout from Manage > Layouts."
}
