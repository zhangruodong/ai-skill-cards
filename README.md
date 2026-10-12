# ai-skill-cards

给 AI 用的系统环境排查手册。一个具体问题一张卡，写成 Markdown，粘进任何 AI 的系统提示词或知识库就能用。

做这个是因为这些事到处都有人讲，但讲得散：Windows 自带的 PowerShell 是 5.1 不是 7；macOS 上的 `/usr/bin/git` 可能只是个占位符；最小化安装的 Linux 连 `ifconfig` 都没有。而且抄来抄去的多，真跑过命令的少。

所以这个仓库只收一种东西：命令在真机上跑过、并且写清了在哪个系统哪个版本上跑的卡。

## 现在有什么

一张：

[skills/windows/powershell-7.md](skills/windows/powershell-7.md) —— 区分 Windows PowerShell 5.1 和 PowerShell 7，以及 `curl`、`wget`、`sc` 这些同名命令在两代里行为不同的坑。在 Windows 11 build 22621、5.1.22621.6133 与 7.6.6 上实测。

macOS、Linux、AI 训练环境三块在做，没实测完不会放进来。

## 怎么用

把卡的内容整个复制，粘到你用的 AI 里：

- **DeepSeek**：对话开头直接粘，或上传 `.md` 文件让它读
- **豆包**：智能体的「人设与回复逻辑」，或知识库上传
- **ChatGPT**：自定义指令，或自定义 GPT 的 Instructions
- **Claude**：Project 的 Knowledge；卡带 frontmatter，也可以当 Skill 放
- **Gemini**：Gem 的指令，或附件

只有一张卡的时候直接粘那一张就行，不用管别的。

粘完验证一下：问「我这个 PowerShell 脚本换台机器就报错」，AI 应该先让你跑 `$PSVersionTable`，而不是直接叫你重装 PowerShell。要是它上来就让你重装，说明卡没读到。

## 写新卡

见 [CONTRIBUTING.md](CONTRIBUTING.md)。核心就一条：命令自己跑过，没跑过的写清楚没跑过。

## 目录

```
skills/<平台>/<卡名>.md    技能卡
evidence/                  卡里那些结论的实测脚本
tools/check-links.py       检查仓库内链
```

## 协议

MIT
