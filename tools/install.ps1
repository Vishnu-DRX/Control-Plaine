# Control-Plaine installer.
# Run from the repo folder: powershell -ExecutionPolicy Bypass -File tools\install.ps1
# Links the repo into the Rainmeter Skins folder, creates User.inc, installs the helpers
# listed in @Resources\Setup\Helpers.txt, installs the layout, loads it and opens Settings.

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
        $linked = $item.LinkType -eq 'Junction' -and
            (Resolve-Path ($item.Target | Select-Object -First 1)).Path -eq (Resolve-Path $repo).Path
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
$stateExisted = Test-Path (Join-Path $repo '@Resources\State.inc')
foreach ($name in 'User.inc', 'State.inc') {
    $file = Join-Path $repo "@Resources\$name"
    if (-not (Test-Path $file)) {
        Set-Content -Encoding ascii $file "; Control-Plaine $name (not committed).`r`n[Variables]"
        Write-Host "Created @Resources\$name"
    }
}

# 2-bis. First-run setup. State.inc without SetupDone makes Settings start the
#     onboarding. A profile that already had a State.inc is an existing user:
#     mark setup done so it does not nag (General > RUN SETUP AGAIN restarts it).
$stateFile = Join-Path $repo '@Resources\State.inc'
if ($stateExisted -and -not (Select-String -Path $stateFile -Pattern '^SetupDone=' -Quiet)) {
    Add-Content -Encoding ascii $stateFile 'SetupDone=1'
    Write-Host "Existing profile: first-run setup marked done."
}

# 2a. Helpers (plugins and tools some skins need). The list is
#     @Resources\Setup\Helpers.txt, the same allow-list the first-run setup in
#     Settings uses, so the two cannot drift. Only entries with installer=1 run
#     here, and only when none of their verify checks is already satisfied.
function Read-Helpers([string]$file) {
    $list = @(); $cur = $null
    foreach ($line in Get-Content $file) {
        if ($line -match '^\s*;' -or $line -match '^\s*$') { continue }
        if ($line -match '^\[([\w-]+)\]\s*$') {
            $cur = @{ id = $Matches[1]; verify = @() }; $list += $cur
        } elseif ($cur -and $line -match '^(\w+)=(.*)$') {
            if ($Matches[1] -eq 'verify') { $cur.verify += $Matches[2] } else { $cur[$Matches[1]] = $Matches[2] }
        }
    }
    return $list
}
function Test-Helper($h) {
    foreach ($v in $h.verify) {
        $kind, $value = $v -split ':', 2
        $value = [Environment]::ExpandEnvironmentVariables($value)
        if ($kind -eq 'file' -and (Test-Path $value)) { return $true }
        if ($kind -eq 'path' -and (Get-Command $value -ErrorAction SilentlyContinue)) { return $true }
    }
    return $false
}
$restart = $false
foreach ($h in Read-Helpers (Join-Path $repo '@Resources\Setup\Helpers.txt')) {
    if ($h.installer -ne '1' -or (Test-Helper $h)) { continue }
    if (-not (Get-Command $h.program -ErrorAction SilentlyContinue)) {
        Write-Host "$($h.label): $($h.program) is missing, so it was not installed. Settings can show how."
        continue
    }
    Write-Host "Installing $($h.label) ($($h.source))"
    $argText = $h.args.Replace('{ROOT}', $repo.TrimEnd('\') + '\')
    Start-Process -FilePath $h.program -ArgumentList $argText -Wait -NoNewWindow
    if (Test-Helper $h) {
        if ($h.restart -eq '1') { $restart = $true }
    } else {
        Write-Host "$($h.label) is still missing. Run the first-run setup in Settings, or see docs\guide\first-time-setup.md."
    }
}
if ($restart) { Write-Host "Restart Rainmeter (Exit, then start it) so it loads the new plugin." }

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
# The layout source is tools\layout\Control-Plaine.layout (not an .ini, outside any skin
# folder, so Rainmeter does not list it as a skin); Rainmeter wants it named Rainmeter.ini.
Copy-Item (Join-Path $repo 'tools\layout\Control-Plaine.layout') (Join-Path $dest 'Rainmeter.ini') -Force

# 4. Load it.
if (Test-Path $rainmeter) {
    & $rainmeter '!LoadLayout' 'Control-Plaine'
    Write-Host "Loaded the Control-Plaine layout."
    # 5. Open Settings. On a profile with no SetupDone it starts the first-run
    #    setup by itself (Settings.lua); otherwise it shows General.
    Start-Sleep -Seconds 2
    & $rainmeter '!ActivateConfig' 'Control-Plaine\Settings' 'General.ini'
    Write-Host "Opened Settings."
} else {
    Write-Host "Rainmeter.exe not found. Load the layout from Manage > Layouts."
}
