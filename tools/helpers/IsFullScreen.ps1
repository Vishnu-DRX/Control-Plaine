# Control-Plaine helper: IsFullScreen.dll (hide skins while a full-screen app
# is in front). Listed in @Resources\Setup\Helpers.txt (id isfullscreen); run
# by tools\install.ps1 and by the first-run setup (RUN IT FOR ME).
# A copy ships in Skins\@Vault from an earlier .rmskin; Rainmeter loads
# plugins from %APPDATA%\Rainmeter\Plugins, so copy the 64-bit build there.
$ErrorActionPreference = 'Stop'
$skins = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'Rainmeter\Skins'
$plugins = Join-Path $env:APPDATA 'Rainmeter\Plugins'
$fullDll = Join-Path $plugins 'IsFullScreen.dll'
if (Test-Path $fullDll) {
    Write-Host "IsFullScreen.dll is already installed."
    exit 0
}
$vault = Get-ChildItem (Join-Path $skins '@Vault\Plugins\IsFullScreen') -Recurse -Filter 'IsFullScreen.dll' -ErrorAction SilentlyContinue |
    Where-Object { $_.DirectoryName -like '*64bit*' } | Sort-Object FullName -Descending | Select-Object -First 1
if ($vault) {
    New-Item -ItemType Directory -Force -Path $plugins | Out-Null
    Copy-Item $vault.FullName $fullDll
    Write-Host "Installed IsFullScreen.dll. Restart Rainmeter so it loads the new plugin."
} else {
    Write-Host "IsFullScreen.dll not found. Install the IsFullScreen plugin (64-bit) into $plugins, or turn off Hide in full screen."
    exit 1
}
