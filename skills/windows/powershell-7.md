---
name: windows-powershell-7
description: Windows 上判断自己用的是 Windows PowerShell 5.1 还是 PowerShell 7，以及同一个命令在两代里行为不同的排查。触发词：PowerShell 版本、pwsh、powershell 和 pwsh 的区别、5.1 升级 7、$PSVersionTable、执行策略、RemoteSigned、禁止运行脚本、curl 参数不对、wget 不存在、Out-File 中文乱码、PSModulePath。
platform: windows
last_verified: 2026-10-12
status: 部分实测
---

# windows-powershell-7

Windows 上两代 PowerShell 并存，命令长得几乎一样，行为不一样。用户说「在我机器上是好的」，十次有八次是两代的差异。

## 检测

先确定是哪一代，别猜：

```powershell
$PSVersionTable.PSVersion.ToString()
$PSVersionTable.PSEdition        # Desktop = 5.1，Core = 7+
```

再看两个引擎装在哪儿：

```powershell
Get-Command pwsh, powershell -ErrorAction SilentlyContinue |
  Select-Object Name, Version, Source
```

本机（Windows 11 build 22621）的输出：

```
Name        Version         Source
----        -------         ------
pwsh        7.6.6           C:\Program Files\PowerShell\7\pwsh.exe
powershell  5.1.22621.6133  C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe
```

判读：

- `PSEdition` 是 `Desktop`，或 `$PSHOME` 指向 `...\WindowsPowerShell\v1.0` → 在 5.1 里
- `PSEdition` 是 `Core`，`$PSHOME` 是 `C:\Program Files\PowerShell\7` → 在 7 里
- 5.1 是系统组件，Windows 10/11 上正常都在；找不到说明系统异常

要知道另一代的版本，直接问它：

```powershell
& "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -Command '$PSVersionTable.PSVersion.ToString()'
pwsh -NoProfile -Command '$PSVersionTable.PSVersion.ToString()'
```

## 两代实测差异

2026-10-12 在 Windows 11 build 22621 上实测，5.1.22621.6133 与 7.6.6。探测脚本在 [evidence/](../../evidence/probe-ps-versions.ps1)。

| | 5.1 | 7.6.6 |
|---|---|---|
| `PSEdition` | `Desktop` | `Core` |
| `$PSHOME` | `C:\Windows\System32\WindowsPowerShell\v1.0` | `C:\Program Files\PowerShell\7` |
| `$OutputEncoding` | `us-ascii` | `utf-8` |
| `Out-File -Encoding utf8` | 写 BOM | 不写 BOM |
| `curl` | 别名 → `Invoke-WebRequest` | `C:\Windows\system32\curl.exe` |
| `wget` | 别名 → `Invoke-WebRequest` | 不存在 |
| `sc` | 别名 → `Set-Content` | `C:\Windows\system32\sc.exe` |
| `Get-WmiObject` | 原生 Cmdlet | 兼容层 Function |
| `Get-EventLog` | 原生 Cmdlet | 兼容层 Function |
| 有效执行策略 | `Restricted` | `RemoteSigned` |
| `PSModulePath` 条数 | 3 | 5（含 5.1 的两条） |

## 坑

`curl` 在两代里是两个东西。5.1 里它是 `Invoke-WebRequest` 的别名，7 里是真的 `curl.exe`。`curl -Uri ...` 在 7 上报参数错，`curl -H "..."` 在 5.1 上报参数错。用 `Get-Command curl | Select-Object CommandType, Definition` 确认拿到的是什么。

`wget` 在 7 里没有了。5.1 的脚本搬过去会直接报「无法识别」。

`sc` 最阴。5.1 里它是 `Set-Content` 的别名，7 里指向 `sc.exe`。脚本里写 `sc $path $content` 想写文件，在 7 上会去操作 Windows 服务。

`Out-File -Encoding utf8` 在两代写出的字节数不同。同一句 `"test" | Out-File -Encoding utf8`，5.1 出 9 字节（前面多了 3 字节 BOM `EF BB BF`），7 出 6 字节。给 Java 读 properties、给 Python 读 JSON、给 CI 解析配置，多出来的 BOM 会导致读不了。

5.1 的 `$OutputEncoding` 是 `us-ascii`，把中文管道给 `git`、`python`、`ffmpeg` 会变成 `?`。要显式设置：

```powershell
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
```

执行策略两代不共享。本机 5.1 的有效策略是 `Restricted`，7 是 `RemoteSigned`，而注册表里 `HKLM:\SOFTWARE\Microsoft\PowerShellCore\ShellIds\Microsoft.PowerShell` 根本不存在——7 那个 `RemoteSigned` 是默认值，不是谁设的。给 7 设 `Set-ExecutionPolicy` 不等于给 5.1 设了。

7 的 `PSModulePath` 里包含 5.1 的两个模块目录，实测会同时加载两个版本的 `Microsoft.PowerShell.Management`（7.0.0.0 和 1.0）。为 5.1 写的模块不一定能用。

别用 exe 的文件属性判断版本。`powershell.exe` 的 ProductVersion 报的是 OS build，本机是 `10.0.22621.4745`，看着像 10.x，其实是 5.1。注册表 `HKLM:\SOFTWARE\Microsoft\PowerShell\3\PowerShellEngine` 里写的才是 `5.1.22621.1`。

在 7 的会话里敲 `powershell`，起的是 5.1 进程。要确保只在 7 里跑就写 `pwsh`。

不是所有 7.x 都一样。本机 7.6.6 里 `Get-WmiObject`、`Get-EventLog` 还在，类型是兼容层 Function；更早的 7.x 不一定有。用 `Get-Command Get-WmiObject` 自查，别照抄教程。

## 安装与升级

装 7 不会覆盖 5.1，两个并存，命令分别是 `pwsh` 和 `powershell`。

```powershell
winget install --id Microsoft.PowerShell --source winget
```

也可以从 GitHub Releases 下 `PowerShell-7.x.x-win-x64.msi`。

这段没验证过：本会话里 winget 调用一律返回 `0x8A150001` 且无输出。本机的 7.6.6 是 MSI 装的，卸载注册表条目为 `PowerShell 7-x64 / 7.6.6.0 / Microsoft Corporation`。

## 验证

```powershell
pwsh -NoProfile -Command '$PSVersionTable.PSVersion.ToString()'
# 期望 7.x

& "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -Command '$PSVersionTable.PSVersion.ToString()'
# 期望 5.1.x
```

两条都出结果，说明两代并存且各自可用。

## 回滚

撤销当前会话的策略改动：

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Undefined
```

卸载 PowerShell 7，不影响 5.1：

```powershell
winget uninstall --id Microsoft.PowerShell
```

5.1 是系统组件，别卸，卸了会破坏依赖它的系统功能。

## 不要做

- 别用删 `C:\Program Files\PowerShell\7` 目录的方式卸载，会留下注册表和 PATH 残留，走 MSI 或「应用和功能」
- 别把 `sc` 当 `Set-Content` 用在 7 上
- 别用 `Set-ExecutionPolicy Bypass` 图省事，要临时放开就加 `-Scope Process`
- 别装来源不明的安装包，官方渠道只有 GitHub Releases 和 Microsoft Store

## 来源

2026-10-12 于 Windows 11 build 22621 实测，Windows PowerShell 5.1.22621.6133 / PowerShell 7.6.6。三个只读探测脚本：[probe-ps-versions.ps1](../../evidence/probe-ps-versions.ps1)、[probe-ps-versions2.ps1](../../evidence/probe-ps-versions2.ps1)、[probe-ps-versions3.ps1](../../evidence/probe-ps-versions3.ps1)

没验证的部分：安装和卸载命令（本会话的 winget 跑不了）、PowerShell 7 的最低系统要求。

待补：Microsoft Learn 上 about_Windows_PowerShell_5.1 和 5.1 迁移到 7 的文档链接。
