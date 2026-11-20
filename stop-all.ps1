# start-all.ps1 ile açılan tüm servisleri durdurur.
$ports = @(3100,3101,3102,3103,3104,3105,3107,3108,3109,3110,4100,4200,4300,4400,4500,4600,4700)
foreach ($port in $ports) {
  $procs = Get-NetTCPConnection -State Listen -LocalPort $port -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty OwningProcess -Unique
  foreach ($p in $procs) {
    try { Stop-Process -Id $p -Force -ErrorAction Stop; Write-Host ("durduruldu: port {0} (pid {1})" -f $port, $p) } catch {}
  }
}
Write-Host "tamam"
