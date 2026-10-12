# probe-ps-versions3.ps1 —— 第三轮：有效执行策略、策略注册表、winget 与安装来源
$engines = [ordered]@{
  'Windows PowerShell 5.1' = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
  'PowerShell 7'           = (Get-Command pwsh -ErrorAction SilentlyContinue).Source
}

$probe = @'
$ErrorActionPreference = "Continue"
"Get-ExecutionPolicy (effective) : " + (Get-ExecutionPolicy)
"--- scope list ---"
(Get-ExecutionPolicy -List | Out-String).Trim()
 "--- policy source keys visible to this engine ---"
foreach ($k in "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell","HKCU:\SOFTWARE\Policies\Microsoft\Windows\PowerShell",
               "HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell",
               "HKLM:\SOFTWARE\Microsoft\PowerShellCore\ShellIds\Microsoft.PowerShell") {
  if (Test-Path $k) {
    $v = (Get-ItemProperty -Path $k -ErrorAction SilentlyContinue).ExecutionPolicy
    "  {0,-72} -> {1}" -f $k, $(if ($v) { $v } else { "(key exists, no ExecutionPolicy value)" })
  } else { "  {0,-72} -> (key absent)" -f $k }
}
'@

foreach ($name in $engines.Keys) {
  Write-Output ("=" * 72); Write-Output "ENGINE: $name"; Write-Output ("=" * 72)
  $exe = $engines[$name]
  if (-not $exe -or -not (Test-Path -LiteralPath $exe)) { Write-Output "  NOT INSTALLED"; continue }
  try { (& $exe -NoProfile -Command $probe 2>&1) | ForEach-Object { "  " + $_.ToString() } }
  catch { Write-Output ("  LAUNCH FAILED: " + $_.Exception.Message) }
  Write-Output ""
}

Write-Output ("=" * 72); Write-Output "winget 与 PowerShell 7 安装来源"; Write-Output ("=" * 72)
try { Write-Output ("  winget --version : " + (winget --version 2>&1 | Out-String).Trim()) }
catch { Write-Output ("  winget 调用失败 : " + $_.Exception.Message) }

Write-Output "  已安装的 PowerShell 相关条目（卸载注册表）:"
$paths = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*','HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
Get-ItemProperty -Path $paths -ErrorAction SilentlyContinue |
  Where-Object { $_.DisplayName -match 'PowerShell' } |
  ForEach-Object { "    {0,-40} {1,-14} {2}" -f $_.DisplayName, $_.DisplayVersion, $_.Publisher }

Write-Output "  PowerShell 7 安装目录:"
if (Test-Path 'C:\Program Files\PowerShell\7') {
  Get-ChildItem 'C:\Program Files\PowerShell\7' -Filter 'pwsh.exe' | ForEach-Object { "    " + $_.FullName + "  (" + $_.VersionInfo.ProductVersion + ")" }
}
