# Build three release APK variants:
#   1. production -> http://92.5.10.116
#   2. emulator   -> http://10.0.2.2:8000
#   3. local      -> http://<your-lan-ip>:8000
#
# Usage:
#   .\scripts\build_apks.ps1
#   .\scripts\build_apks.ps1 -LanIp 192.168.1.42
#
# Output: frontend\build\apk-release\

param(
    [string]$LanIp = $env:LOCAL_API_HOST
)

$ErrorActionPreference = "Stop"
$FrontendRoot = Split-Path -Parent $PSScriptRoot
Set-Location $FrontendRoot

function Get-LanIpAddress {
    if ($LanIp -and $LanIp.Trim().Length -gt 0) {
        return $LanIp.Trim()
    }
    try {
        $addr = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
            Where-Object {
                $_.IPAddress -notmatch '^127\.' -and
                $_.IPAddress -notmatch '^169\.254\.'
            } |
            Sort-Object InterfaceMetric |
            Select-Object -First 1 -ExpandProperty IPAddress
        if ($addr) { return $addr }
    }
    catch {
        # ignore
    }
    Write-Warning "Could not detect LAN IP. Pass -LanIp 192.168.x.x"
    return "192.168.1.1"
}

$lan = Get-LanIpAddress
$outDir = Join-Path $FrontendRoot "build\apk-release"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

Write-Host ""
Write-Host "=== AirWatch: building 3 release APKs ===" -ForegroundColor Cyan
Write-Host "Local LAN IP for local flavor: $lan" -ForegroundColor Yellow
Write-Host ""

function Build-Apk {
    param(
        [string]$Flavor,
        [string]$ApiHost,
        [string]$OutName
    )

    Write-Host ">> Building $Flavor (API_HOST=$ApiHost)..." -ForegroundColor Green

    Push-Location (Join-Path $FrontendRoot "android")
    & .\gradlew.bat --stop 2>$null | Out-Null
    Pop-Location

    & flutter pub get --offline 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "   (offline pub get failed, trying online...)" -ForegroundColor Yellow
        & flutter pub get
        if ($LASTEXITCODE -ne 0) {
            throw "flutter pub get failed. Check internet/DNS or run: flutter pub get"
        }
    }

    & flutter build apk --flavor $Flavor --release --no-pub "--dart-define=API_HOST=$ApiHost"
    if ($LASTEXITCODE -ne 0) {
        throw "flutter build failed for flavor $Flavor"
    }

    $built = Join-Path $FrontendRoot "build\app\outputs\flutter-apk\app-$Flavor-release.apk"
    if (-not (Test-Path $built)) {
        throw "Expected APK not found: $built"
    }

    $dest = Join-Path $outDir $OutName
    Copy-Item -Path $built -Destination $dest -Force
    Write-Host "   Saved: build\apk-release\$OutName" -ForegroundColor Gray
}

Build-Apk -Flavor "production" -ApiHost "http://92.5.10.116" -OutName "airwatch-production.apk"
Build-Apk -Flavor "emulator" -ApiHost "10.0.2.2:8000" -OutName "airwatch-emulator.apk"
Build-Apk -Flavor "local" -ApiHost "${lan}:8000" -OutName "airwatch-local.apk"

Write-Host ""
Write-Host "Done. APK files:" -ForegroundColor Cyan
Write-Host "  airwatch-production.apk  - VM server 92.5.10.116"
Write-Host "  airwatch-emulator.apk    - Android emulator + local Django"
Write-Host "  airwatch-local.apk       - phone on WiFi, backend on ${lan}:8000"
Write-Host ""
