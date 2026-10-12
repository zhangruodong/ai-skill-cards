# probe-ps-versions.ps1 —— 在 Windows PowerShell 5.1 与 PowerShell 7 中跑同一组只读探测，对比差异
# 用途：为 skills/windows/powershell-7.md 提供实测证据。只读，不改系统设置。

$engines = [ordered]@{
  'Windows PowerShell 5.1' = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
  'PowerShell 7'           = (Get-Command pwsh -ErrorAction SilentlyContinue).Source
}

$probe = @'
$ErrorActionPreference = "Continue"
function Has($n) { if (Get-Command $n -ErrorAction SilentlyContinue) { "YES" } else { "NO" } }
"PSVersion        : " + $PSVersionTable.PSVersion.ToString()
"PSEdition        : " + $PSVersionTable.PSEdition
"PSHOME           : " + $PSHOME
"Host             : " + $Host.Name + " " + $Host.Version
"--- command availability ---"
foreach ($n in "Get-WmiObject","Get-CimInstance","Get-EventLog","Get-Counter","Get-Clipboard","Get-Service","Out-GridView","ConvertFrom-Json","ConvertFrom-Json -AsHashtable") {
  "  {0,-32}: {1}" -f $n, (Has ($n -split " ")[0])
}
"--- aliases / commands ---"
foreach ($a in "curl","wget","sc","ls","cat","rm") {
  $c = Get-Command $a -ErrorAction SilentlyContinue
  if ($c) { "  {0,-6} -> {1,-28} [{2}]" -f $a, $c.Name, $c.CommandType } else { "  {0,-6} -> (none)" -f $a }
}
"--- encoding ---"
"OutputEncoding   : " + $OutputEncoding.WebName
"[Console]::Output : " + [Console]::OutputEncoding.WebName
"--- Out-File -Encoding utf8 BOM test ---"
$f = Join-Path $env:TEMP ("bomtest_" + $PID + ".txt")
"test" | Out-File -Encoding utf8 -FilePath $f
$b = [System.IO.File]::ReadAllBytes($f)
"first 3 bytes    : " + (($b[0..2] | ForEach-Object { $_.ToString("X2") }) -join " ")
"file bytes       : " + $b.Length
Remove-Item -LiteralPath $f -Force -ErrorAction SilentlyContinue
"--- execution policy ---"
(Get-ExecutionPolicy -List | Out-String).Trim()
"--- PSModulePath ---"
$env:PSModulePath -split ";" | ForEach-Object { "  " + $_ }
'@

foreach ($name in $engines.Keys) {
  $exe = $engines[$name]
  Write-Output ("=" * 72)
  Write-Output "ENGINE: $name"
  Write-Output "EXE   : $exe"
  Write-Output ("=" * 72)
  if (-not $exe -or -not (Test-Path -LiteralPath $exe)) { Write-Output "  NOT INSTALLED"; continue }
  try {
    $out = & $exe -NoProfile -Command $probe 2>&1
    $out | ForEach-Object { "  " + $_.ToString() }
  } catch {
    Write-Output ("  LAUNCH FAILED: " + $_.Exception.Message)
  }
  Write-Output ""
}
