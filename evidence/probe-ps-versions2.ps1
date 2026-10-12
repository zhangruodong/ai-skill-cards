# probe-ps-versions2.ps1 —— 第二轮：定位来源模块、别名定义、执行策略存储位置
$engines = [ordered]@{
  'Windows PowerShell 5.1' = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
  'PowerShell 7'           = (Get-Command pwsh -ErrorAction SilentlyContinue).Source
}

$probe = @'
$ErrorActionPreference = "Continue"
"--- cmdlet sources (Module / Source) ---"
foreach ($n in "Get-WmiObject","Get-EventLog","Get-Counter","Out-GridView","Get-Clipboard","Get-CimInstance","Get-Content") {
  $c = Get-Command $n -ErrorAction SilentlyContinue
  if ($c) { "  {0,-16} type={1,-12} module={2,-34} src={3}" -f $n, $c.CommandType, $c.ModuleName, $c.Source }
  else    { "  {0,-16} (not found)" -f $n }
}
"--- alias definitions ---"
foreach ($a in "curl","wget","sc","ls","cat","rm","iwr","wget2","Invoke-WebRequest") {
  $c = Get-Command $a -ErrorAction SilentlyContinue
  if ($c) { "  {0,-18} type={1,-12} def={2}" -f $a, $c.CommandType, $c.Definition }
  else    { "  {0,-18} (not found)" -f $a }
}
"--- imported modules matching *Compat* / *Utility* ---"
Get-Module | Where-Object { $_.Name -match "Compat|Utility|Management|Graphical" } | ForEach-Object { "  " + $_.Name + " " + $_.Version }
"--- loaded module count ---"
"  " + (Get-Module).Count
'@

foreach ($name in $engines.Keys) {
  $exe = $engines[$name]
  Write-Output ("=" * 72)
  Write-Output "ENGINE: $name"
  Write-Output ("=" * 72)
  if (-not $exe -or -not (Test-Path -LiteralPath $exe)) { Write-Output "  NOT INSTALLED"; continue }
  try { (& $exe -NoProfile -Command $probe 2>&1) | ForEach-Object { "  " + $_.ToString() } }
  catch { Write-Output ("  LAUNCH FAILED: " + $_.Exception.Message) }
  Write-Output ""
}

Write-Output ("=" * 72)
Write-Output "执行策略注册表位置（本机只读检查）"
Write-Output ("=" * 72)
$keys = @(
  'HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell',
  'HKCU:\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell',
  'HKLM:\SOFTWARE\Microsoft\PowerShellCore\ShellIds\Microsoft.PowerShell',
  'HKCU:\SOFTWARE\Microsoft\PowerShellCore\ShellIds\Microsoft.PowerShell'
)
foreach ($k in $keys) {
  if (Test-Path $k) {
    $v = (Get-ItemProperty -Path $k -ErrorAction SilentlyContinue).ExecutionPolicy
    Write-Output ("  {0,-70} -> {1}" -f $k, $(if ($v) { $v } else { '(no value)' }))
  } else {
    Write-Output ("  {0,-70} -> (key absent)" -f $k)
  }
}
