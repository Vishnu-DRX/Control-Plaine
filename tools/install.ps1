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

# 2. Personal settings.
$user = Join-Path $repo '@Resources\User.inc'
if (-not (Test-Path $user)) {
    (Get-Content (Join-Path $repo '@Resources\User.example.inc')) |
        ForEach-Object { $_ -replace '%LOCALAPPDATA%', $env:LOCALAPPDATA } |
        Set-Content -Encoding ascii $user
    Write-Host "Created @Resources\User.inc"
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
