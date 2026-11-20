# Starts every local app, waits for ports, opens the local test board.
# Usage: powershell -ExecutionPolicy Bypass -File .\start-all.ps1
$ErrorActionPreference = "Continue"
$root = "C:\Desktop"

$apps = @(
  @{ name="meydan-web";   dir="$root\discord-clone";     port=3100; cmd="pnpm exec next dev -p 3100"; env=@{ APP_ORIGINS="http://localhost:3100"; COOKIE_SECURE="0"; NEXT_PUBLIC_REALTIME_PORT="4300" } },
  @{ name="meydan-api";   dir="$root\discord-clone";     port=4300; cmd="pnpm dev:api";                 env=@{ APP_ORIGINS="http://localhost:3100"; COOKIE_SECURE="0" } },
  @{ name="kavram-web";   dir="$root\admin-panel";       port=3101; cmd="pnpm exec next dev -p 3101";   env=@{ APP_ORIGINS="http://localhost:3101"; COOKIE_SECURE="0"; API_PORT="4400" } },
  @{ name="kavram-api";   dir="$root\admin-panel";       port=4400; cmd="pnpm dev:api";                 env=@{ APP_ORIGINS="http://localhost:3101"; COOKIE_SECURE="0"; ADMIN_PASSWORD="test-admin-123"; API_PORT="4400" } },
  @{ name="rehber-web";   dir="$root\kopilot-mvp";       port=3102; cmd="pnpm exec next dev -p 3102";   env=@{ APP_ORIGINS="http://localhost:3102"; COOKIE_SECURE="0"; API_PORT="4500" } },
  @{ name="rehber-api";   dir="$root\kopilot-mvp";       port=4500; cmd="pnpm dev:api";                 env=@{ APP_ORIGINS="http://localhost:3102"; COOKIE_SECURE="0"; API_PORT="4500" } },
  @{ name="bal-web";      dir="$root\bal-topluluk";      port=3103; cmd="pnpm exec next dev -p 3103";   env=@{ APP_ORIGINS="http://localhost:3103"; COOKIE_SECURE="0"; API_PORT="4600" } },
  @{ name="bal-api";      dir="$root\bal-topluluk";      port=4600; cmd="pnpm dev:api";                 env=@{ APP_ORIGINS="http://localhost:3103"; ADMIN_TOKEN="test-admin-token-1234567890"; API_PORT="4600" } },
  @{ name="tek-web";      dir="$root\tek-kopya";         port=3104; cmd="pnpm exec next dev -p 3104";   env=@{ APP_ORIGINS="http://localhost:3104"; API_PORT="4700" } },
  @{ name="tek-api";      dir="$root\tek-kopya";         port=4700; cmd="pnpm dev:api";                 env=@{ APP_ORIGINS="http://localhost:3104"; API_PORT="4700" } },
  @{ name="drawing-web";  dir="$root\drawing-worlds";    port=3105; cmd="pnpm exec next dev -p 3105";   env=@{ NEXT_PUBLIC_WS_URL="ws://localhost:4100/ws"; WS_ALLOWED_ORIGINS="http://localhost:3105" } },
  @{ name="drawing-ws";   dir="$root\drawing-worlds";    port=4100; cmd="pnpm dev:ws";                   env=@{ WS_PORT="4100"; WS_ALLOWED_ORIGINS="http://localhost:3105" } },
  @{ name="kisa";         dir="$root\link-shortener";    port=4200; cmd="pnpm dev";                       env=@{ PORT="4200"; BASE_URL="http://localhost:4200"; ADMIN_TOKEN="test-admin-token" } },
  @{ name="magi";         dir="$root\magi";              port=3107; cmd="pnpm exec next dev -p 3107";   env=@{} },
  @{ name="anime";        dir="$root\anime-glasses";     port=3108; cmd="pnpm exec next dev -p 3108";  env=@{} },
  @{ name="gitkolay";     dir="$root\gitkolay";          port=3109; cmd="pnpm exec next dev -p 3109";  env=@{} },
  @{ name="gateway";      dir="$root\personal-gateway";  port=3110; cmd="pnpm exec next dev -p 3110";  env=@{ NEXT_PUBLIC_SITE_URL="http://localhost:3110" } }
)

function Wait-Port($port, $seconds = 150) {
  $deadline = (Get-Date).AddSeconds($seconds)
  while ((Get-Date) -lt $deadline) {
    if (Test-NetConnection 127.0.0.1 -Port $port -InformationLevel Quiet -WarningAction SilentlyContinue) { return $true }
    Start-Sleep -Milliseconds 800
  }
  return $false
}

Write-Host "==> stopping anything already on our ports"
foreach ($app in $apps) {
  $procs = Get-NetTCPConnection -State Listen -LocalPort $app.port -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess -Unique
  foreach ($p in $procs) { try { Stop-Process -Id $p -Force -ErrorAction Stop } catch {} }
}
Start-Sleep -Seconds 2

Write-Host "==> launching services"
foreach ($app in $apps) {
  $logDir = Join-Path $app.dir "logs"
  New-Item -ItemType Directory -Force -Path $logDir | Out-Null
  $bat = Join-Path $logDir ("start-" + $app.name + ".cmd")
  $lines = @("@echo off", ("cd /d `"{0}`"" -f $app.dir))
  foreach ($k in $app.env.Keys) { $lines += ("set {0}={1}" -f $k, $app.env[$k]) }
  $lines += ($app.cmd + (" > `"{0}`" 2>&1" -f (Join-Path $logDir ("run-" + $app.name + ".log"))))
  Set-Content -Path $bat -Value $lines -Encoding ASCII
  Start-Process -FilePath "cmd.exe" -ArgumentList @("/c", $bat) -WindowStyle Hidden | Out-Null
  Write-Host ("started {0} (port {1})" -f $app.name, $app.port)
  Start-Sleep -Milliseconds 300
}

Write-Host "==> waiting for ports (up to 150s each)"
$failed = @()
foreach ($app in $apps) {
  if (-not (Wait-Port $app.port 150)) {
    $failed += $app.name
    Write-Host ("!! {0} port {1} did not open" -f $app.name, $app.port)
  }
}

Start-Process (Join-Path $root "emre-proje-linkleri\local.html")
if ($failed.Count -gt 0) { Write-Host ("==> board opened. Failed: " + ($failed -join ", ")) }
else { Write-Host "==> board opened. Stop with: .\stop-all.ps1" }
