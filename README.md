# ai-skill-cards

给 AI 用的系统环境排查手册。一个问题一张卡，写成 Markdown，粘到 AI 的系统提示词或知识库里就能用。

内容集中在那些讲的人多、但讲得散的地方：Windows 自带的是 PowerShell 5.1 不是 7；macOS 上的 `/usr/bin/git` 可能只是个占位符；最小化安装的 Linux 连 `ifconfig` 都没有。

收录标准：命令在真机上跑过，并写清是在哪个系统、哪个版本上跑的。没实测过的不放进来。

## 现有卡片

| 卡片 | 内容 | 实测环境 |
|---|---|---|
| [skills/windows/powershell-7.md](skills/windows/powershell-7.md) | Windows PowerShell 5.1 与 PowerShell 7 的区别，以及 `curl`、`wget`、`sc` 这些同名命令在两代里行为不同的坑 | Windows 11 build 22621，PowerShell 5.1.22621.6133 与 7.6.6 |

macOS、Linux、AI 训练环境三部分在写，实测完再放。

## 怎么用

把卡片内容整个复制，粘到你用的 AI 里：

- DeepSeek：对话开头直接粘，或上传 `.md` 文件
- 豆包：智能体的「人设与回复逻辑」，或知识库上传
- ChatGPT：自定义指令，或自定义 GPT 的 Instructions
- Claude：Project 的 Knowledge；卡片带 frontmatter，也可以当 Skill 放
- Gemini：Gem 的指令，或附件

目前只有一张卡，直接粘那一张就行。

验证有没有生效：问「我这个 PowerShell 脚本换台机器就报错」。如果 AI 先让你跑 `$PSVersionTable`，说明卡读到了；如果直接叫你重装 PowerShell，说明没读到。

## 写新卡

见 [CONTRIBUTING.md](CONTRIBUTING.md)。

## 目录

```
skills/<平台>/<卡名>.md    技能卡
evidence/                  卡里那些结论的实测脚本
tools/check-links.py       检查仓库内链
```

## 许可

MIT
