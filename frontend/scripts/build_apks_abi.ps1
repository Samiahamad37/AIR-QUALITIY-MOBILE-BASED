# Build one APK per CPU architecture (smaller downloads for each device type).
#
# Command used: flutter build apk --split-per-abi
#
# Output APKs:
#   arm64-v8a   - most phones since ~2017 (64-bit, newer devices)
#   armeabi-v7a - older 32-bit ARM phones
#   x86_64      - Android emulators / some tablets
#
# Usage:
#   .\scripts\build_apks_abi.ps1
#   .\scripts\build_apks_abi.ps1 -Flavor production
#   .\scripts\build_apks_abi.ps1 -Flavor local -LanIp 192.168.1.42
#
# Output: frontend\build\apk-release\abi\

param(
    [ValidateSet("production", "local", "emulator")]
    [string]$Flavor = "production",
    [string]$LanIp = $env:LOCAL_API_HOST
)

$ErrorActionPreference = "Stop"
$FrontendRoot = Split-Path -Parent $PSScriptRoot
Set-Location $FrontendRoot

function Get-LanIpAddress {
    if ($LanIp -and $LanIp.Trim().Length -gt 0) { return $LanIp.Trim() }
    try {
        $addr = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
            Where-Object {
                $_.IPAddress -notmatch '^127\.' -and
                $_.IPAddress -notmatch '^169\.254\.'
            } |
            Sort-Object InterfaceMetric |
            Select-Object -First 1 -ExpandProperty IPAddress
        if ($addr) { return $addr }
    } catch { }
    return "192.168.1.1"
}

$apiHost = switch ($Flavor) {
    "production" { "http://92.5.10.116" }
    "emulator" { "10.0.2.2:8000" }
    "local" { "$(Get-LanIpAddress):8000" }
}

$outDir = Join-Path $FrontendRoot "build\apk-release\abi"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

Write-Host ""
Write-Host "=== AirWatch: split APKs by device CPU (--split-per-abi) ===" -ForegroundColor Cyan
Write-Host "Flavor: $Flavor  API_HOST=$apiHost" -ForegroundColor Yellow
Write-Host ""

& flutter pub get
if ($LASTEXITCODE -ne 0) { throw "flutter pub get failed" }

& flutter build apk --flavor $Flavor --release --split-per-abi --no-pub `
    "--dart-define=API_HOST=$apiHost"
if ($LASTEXITCODE -ne 0) { throw "flutter build apk --split-per-abi failed" }

$apkDir = Join-Path $FrontendRoot "build\app\outputs\flutter-apk"
$patterns = @{
    "arm64-v8a"   = "airwatch-$Flavor-arm64-v8a.apk"
    "armeabi-v7a" = "airwatch-$Flavor-armeabi-v7a.apk"
    "x86_64"      = "airwatch-$Flavor-x86_64.apk"
}

Write-Host ""
Write-Host "Saved APKs:" -ForegroundColor Green
foreach ($abi in $patterns.Keys) {
    $src = Join-Path $apkDir "app-$abi-$Flavor-release.apk"
    if (-not (Test-Path $src)) { continue }
    $dest = Join-Path $outDir $patterns[$abi]
    Copy-Item -Path $src -Destination $dest -Force
    $mb = [math]::Round((Get-Item $dest).Length / 1MB, 1)
    Write-Host "  $($patterns[$abi])  (${mb} MB)  -> $abi"
}

Write-Host ""
Write-Host "Install guide:" -ForegroundColor Cyan
Write-Host "  arm64-v8a   - new phones (most devices today)"
Write-Host "  armeabi-v7a - older 32-bit phones"
Write-Host "  x86_64      - Android emulator only"
Write-Host ""
Write-Host "Folder: build\apk-release\abi\" -ForegroundColor Gray
Write-Host ""
