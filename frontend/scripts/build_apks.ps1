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
        [string]$ApiHost
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

    & flutter build apk --flavor $Flavor --release --no-pub `
        "--dart-define=API_HOST=$ApiHost" `
        --split-per-abi
    if ($LASTEXITCODE -ne 0) {
        throw "flutter build failed for flavor $Flavor"
    }

    $apkDir = Join-Path $FrontendRoot "build\app\outputs\flutter-apk"
    $abis = @(
        @{ Abi = "arm64-v8a"; Suffix = "arm64" },
        @{ Abi = "armeabi-v7a"; Suffix = "arm32" },
        @{ Abi = "x86_64"; Suffix = "x86_64" }
    )

    foreach ($entry in $abis) {
        $built = Join-Path $apkDir "app-$($entry.Abi)-$Flavor-release.apk"
        if (-not (Test-Path $built)) { continue }
        $dest = Join-Path $outDir "airwatch-$Flavor-$($entry.Suffix).apk"
        Copy-Item -Path $built -Destination $dest -Force
        Write-Host "   Saved: build\apk-release\airwatch-$Flavor-$($entry.Suffix).apk" -ForegroundColor Gray
    }
}

Build-Apk -Flavor "production" -ApiHost "http://92.5.10.116"
Build-Apk -Flavor "emulator" -ApiHost "10.0.2.2:8000"
Build-Apk -Flavor "local" -ApiHost "${lan}:8000"

Write-Host ""
Write-Host "Done. Split APKs (pick the file that matches the phone CPU):" -ForegroundColor Cyan
Write-Host "  *-arm64.apk   - new 64-bit phones (arm64-v8a)"
Write-Host "  *-arm32.apk   - older phones (armeabi-v7a)"
Write-Host "  *-x86_64.apk  - Android emulator"
Write-Host ""
Write-Host "  production -> 92.5.10.116 | emulator -> 10.0.2.2:8000 | local -> ${lan}:8000"
Write-Host ""
Write-Host "One flavor only: .\scripts\build_apks_abi.ps1 -Flavor production" -ForegroundColor Gray
