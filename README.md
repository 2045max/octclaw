<div align="center">

# 🐙 OctClaw

**Shell is all. Everything can be clawed. 🦞**

The universal AI agent that runs anywhere shell runs.

<p>
  <img src="https://img.shields.io/badge/shell-3.2%2B_(2006)-4EAA25?logo=gnubash&logoColor=white" alt="Shell 3.2+" />
  <img src="https://img.shields.io/badge/deps-jq%20%2B%20curl-blue" alt="Dependencies" />
  <img src="https://img.shields.io/badge/RAM-%3C%2010MB-purple" alt="Memory" />
  <img src="https://img.shields.io/badge/万物皆可claw-🦞-orange" alt="Everything can be clawed" />
  <a href="https://opensource.org/licenses/MIT">
    <img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="MIT" />
  </a>
</p>

<p>
  <a href="#philosophy">Philosophy</a> &middot;
  <a href="#install">Install</a> &middot;
  <a href="#quick-start">Quick Start</a> &middot;
  <a href="#skills">Skills</a> &middot;
  <a href="#commands">Commands</a> &middot;
  <a href="#architecture">Architecture</a> &middot;
  <a href="#中文">中文</a>
</p>

</div>

---

## 🧠 Philosophy

### Shell is the Universal OS

> "Shell is already there. On your Mac, Linux server, Raspberry Pi, Android phone, IoT device. No install, no package managers, no compatibility issues.
>
> Shell is the universal runtime. OctClaw makes it a universal AI agent."

OctClaw is built on a simple premise: **if it runs shell, it can run an AI agent**. From your laptop to a Raspberry Pi, from Android Termux to embedded systems — OctClaw brings AI assistance to every environment.

### Everything Can Be Clawed 🦞

The octopus represents **adaptability and reach** — eight arms to interact with, manipulate, and understand any system. OctClaw gives you octopus-like capabilities to work with:

- **IoT devices** — Manage sensors, automate homes
- **Mobile phones** — Android automation via Termux  
- **Servers** — System administration, monitoring
- **Development environments** — Coding assistance
- **Personal computers** — Daily tasks, automation

### The OctClaw Philosophy

OctClaw follows a simple yet powerful philosophy:

1. **Self-Managing** — Installs its own tools, configures itself
2. **Skill-Based** — Extends capabilities through skills
3. **Context-Aware** — Understands your environment and projects
4. **Persistent** — Remembers conversations and learns from them
5. **Universal** — Works anywhere, with anything

### The Human's AI Agent

OctClaw isn't just a tool — it's **your agent**. It works for you, learns your preferences, and operates in your environments. Like a personal assistant that can run anywhere you have shell.

### Universal Compatibility

OctClaw runs on **shell 3.2+**, which means it works on:

- **macOS** — 2007 年至今的所有版本，零额外安装
- **Linux** — 任何发行版 (Ubuntu, Debian, Fedora, Alpine, Arch...)
- **Android Termux** — 无需 root
- **Windows** — WSL2, Git Bash, Cygwin
- **嵌入式系统** — Alpine 容器、树莓派、CI 运行器、NAS 设备
- **开发板** — 树莓派、NanoPi、Orange Pi 等

### Messaging Integration

OctClaw can connect to your favorite messaging platforms:
- **Telegram** — 个人和群组聊天
- **飞书/钉钉** — 企业协作
- **Discord/Slack** — 社区和团队
- **微信** — 日常沟通
- **邮件** — 自动化处理

Connect once, access everywhere.

## 🚀 Install

**One-line install**:

```bash
curl -fsSL https://raw.githubusercontent.com/2045max/octclaw/main/install.sh | bash
```

**Manual install**:

```bash
curl -fsSL https://raw.githubusercontent.com/2045max/octclaw/main/oct -o ~/.local/bin/oct
chmod +x ~/.local/bin/oct
```

**Check dependencies**:

```bash
oct doctor  # Needs: shell + jq + curl
```

## ⚡ Quick Start

### 1. Set API Key

```bash
# Any OpenAI-compatible API works
export DEEPSEEK_API_KEY="sk-xxx"  # Free tier available
# or
export OPENAI_API_KEY="sk-xxx"
# or use local models
export API_KEY="dummy"
oct config set .api_base '"http://localhost:11434/v1"'
oct config set .model '"mistral"'
```

### 2. Start Your Agent

```bash
# Interactive mode (REPL)
oct

# One-shot command
oct "list files in current directory"

# With session management
oct -s work "check system status"
```

### 3. Add Skills (Optional)

```bash
# Skills extend OctClaw's capabilities
# Example: Add a note-taking skill
oct "create a skill to manage notes"

# OctClaw will create the skill and teach you how to use it
```

## 🛠️ Skills System

### What are Skills?

Skills are OctClaw's way of extending capabilities. Each skill is a self-contained module that OctClaw can understand and use.

**Skill structure**:
```
~/.octclaw/skills/
├── note/
│   ├── SKILL.md          # Skill documentation
│   └── note.sh           # Implementation
├── weather/
│   ├── SKILL.md
│   └── weather.py
└── system-monitor/
    ├── SKILL.md
    └── monitor.sh
```

### Built-in Skills

OctClaw comes with essential skills:

| Skill | Purpose | Example |
|-------|---------|---------|
| **File Operations** | Read, write, edit files | `oct "read config.json"` |
| **Shell Execution** | Run any command | `oct "check disk usage"` |
| **Code Search** | Find code patterns | `oct "find where function X is defined"` |
| **System Info** | Get system status | `oct "show running processes"` |

### Creating Skills

You can ask OctClaw to create skills, or create them yourself:

```bash
# Ask OctClaw to create a skill
oct "create a skill that monitors website uptime"

# Or create manually
mkdir -p ~/.octclaw/skills/uptime
cat > ~/.octclaw/skills/uptime/SKILL.md << 'EOF'
---
name: uptime
description: Monitor website availability
---

# Uptime Monitoring Skill

Check if websites are online and measure response time.

## Usage
Check a single website:
```bash
curl -I https://example.com
```

Monitor multiple sites:
```bash
for site in google.com github.com; do
  if curl -s --head $site | grep "200 OK"; then
    echo "$site: UP"
  else
    echo "$site: DOWN"
  fi
done
```
EOF
```

### Skill Discovery

OctClaw automatically discovers skills in:
1. `~/.octclaw/skills/` — Global skills (all sessions)
2. `./.octclaw/skills/` — Project-specific skills
3. Session-specific skill directories

## 📟 Commands

### Interactive Commands

When running `oct` (interactive mode), you can use:

```
/help           Show all commands
/exit or /quit  Exit
/model <name>   Switch model (gpt-4o, deepseek-chat, etc.)
/session <name> Switch session
/sessions       List all sessions
/clear          Clear current session
/compact        Keep only last 20 messages
/skills         List available skills
/config         Show configuration
```

### CLI Commands

```bash
# Basic usage
oct [flags] [message]

# Flags
-m, --model <name>     Model name (default: gpt-4o)
-s, --session <id>     Session ID (default: default)
-c, --continue         Continue most recent session
-p, --print            Force non-interactive output
--debug                Debug output

# Subcommands
oct doctor             Check dependencies
oct config             View or edit config
oct sessions           List sessions
oct gateway [port]     Start web interface (default: 16869)
```

### Configuration Commands

```bash
# View config
oct config

# Set values
oct config set .model '"deepseek-chat"'
oct config set .api_base '"https://api.deepseek.com"'
oct config set .temperature '0.7'

# Environment variables also work
export DEEPSEEK_API_KEY="sk-xxx"
export MODEL="deepseek-chat"
```

## 🏗️ Architecture

### System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     OctClaw Architecture                     │
└─────────────────────────────────────────────────────────────┘

Core Components:
├── Agent Engine          # LLM interaction, tool calling
├── Skill System          # Extensible capabilities
├── Session Manager       # Conversation persistence
├── Configuration         # Settings and API keys
└── CLI Interface         # User interaction

Data Structure:
~/.octclaw/
├── config.json          # Configuration
├── system.md           # Custom system prompt
├── .env                # Environment variables
├── skills/             # Global skills
├── sessions/           # Conversation history
│   ├── default.jsonl
│   ├── work.jsonl
│   └── ...
└── projects/           # Project-specific data
    ├── myapp/
    │   ├── .octclaw/
    │   │   ├── skills/     # Project skills
    │   │   └── context.md  # Project context
    │   └── ...
    └── ...
```

### Agent Loop

```bash
1. User sends message
2. Load session context
3. Discover available skills
4. Call LLM with context + skills
5. Execute skill if requested
6. Store result, continue if needed
7. Return final response
```

## 🌐 Use Cases

### Personal Automation

```bash
# Daily tasks
oct "remind me to water plants every day at 9am"
oct "backup important documents to cloud"

# Information management
oct "organize my downloads folder"
oct "find duplicate files"
```

### System Administration

```bash
# Server monitoring
oct "check disk space on all servers"
oct "monitor service status and restart if down"

# Security
oct "scan for open ports"
oct "check for failed login attempts"
```

### Development Assistance

```bash
# Project setup
oct "initialize a new Python project with virtualenv"

# Code maintenance
oct "update dependencies in package.json"
oct "run tests and report coverage"

# Debugging
oct "find memory leaks in the application"
```

### IoT & Embedded

```bash
# Raspberry Pi automation
oct "control GPIO pins"
oct "read sensor data and log to database"

# Home automation
oct "turn on lights at sunset"
oct "adjust thermostat based on weather"
```

## 🔧 Advanced Usage

### Project Context

OctClaw automatically loads context from your project:

```bash
# Create project context
cat > .octclaw/context.md << 'EOF'
# Project: Home Automation

## Devices
- Living room lights (GPIO 17)
- Temperature sensor (I2C address 0x76)
- Camera (USB)

## Automation Rules
- Lights on at 6pm, off at 11pm
- Temperature logging every 5 minutes
- Motion detection alerts
EOF

# Now OctClaw understands your project
oct "check living room lights status"
```

### Custom System Prompt

```bash
# Define OctClaw's personality
cat > ~/.octclaw/system.md << 'EOF'
# You are OctClaw

## Role
A helpful AI assistant that can interact with any system.

## Principles
1. Be precise and reliable
2. Explain what you're doing
3. Ask for clarification when needed
4. Respect security boundaries

## Capabilities
- Execute shell commands
- Read/write files
- Manage skills
- Remember context
EOF
```

### Session Management

```bash
# Work on different projects
oct -s home-automation "check all devices"
oct -s server-admin "update packages"
oct -s personal "organize photos"

# Continue where you left off
oct -c "what's next?"

# List all sessions
oct sessions
```

## 🤝 Community & Ecosystem

### Skills Ecosystem

OctClaw's power comes from its extensible skills system. Create your own skills or use community-contributed ones:

```bash
# Create a new skill
oct "create a skill to monitor website uptime"

# Use existing skills
oct "what skills are available?"
```

### Skill Categories

- **System Administration** — Monitoring, backups, security
- **Development** — Code generation, testing, deployment
- **Personal Productivity** — Notes, reminders, organization
- **IoT & Hardware** — GPIO control, sensor reading
- **Web & APIs** — HTTP requests, API integration
- **Data Processing** — CSV/JSON manipulation, analysis
- **Messaging** — Telegram, Discord, WeChat integration

### Skill Categories

- **System Administration** — Monitoring, backups, security
- **Development** — Code generation, testing, deployment
- **Personal Productivity** — Notes, reminders, organization
- **IoT & Hardware** — GPIO control, sensor reading
- **Web & APIs** — HTTP requests, API integration
- **Data Processing** — CSV/JSON manipulation, analysis

## 🔒 Security Considerations

### Permission Model

OctClaw runs with **your user permissions**. It can:

- Read/write files you have access to
- Execute commands you can run
- Access network resources available to you

### Best Practices

1. **Use project-specific sessions** for different security contexts
2. **Review skill code** before using community skills
3. **Limit API key permissions** to minimum required
4. **Monitor tool execution** in sensitive environments
5. **Consider Docker containers** for isolation when needed

### Sandboxing Options

```bash
# Run in Docker container (recommended for untrusted skills)
docker run -it --rm -v $(pwd):/workspace alpine sh
# Then install and run OctClaw inside

# Or use virtual machines for complete isolation
```

## 📚 Documentation

### Quick Reference

```bash
# Installation
curl -fsSL https://raw.githubusercontent.com/2045max/octclaw/main/install.sh | bash

# Configuration
export DEEPSEEK_API_KEY="sk-xxx"
oct config set .model '"deepseek-chat"'

# Basic usage
oct                          # Interactive
oct "your command"           # One-shot
oct -s project "task"        # Project session
oct gateway                  # Web interface

# Skill management
oct "list skills"            # Show available
oct "create skill for X"     # Ask to create
```

### Further Reading

- [Detailed Documentation](DOC.md) — Complete usage guide
- [Architecture Reference](ARCHITECTURE_AND_REFERENCE.md) — System design
- [Skill Development Guide](SKILLS_GUIDE.md) — Creating skills
- [API Reference](API.md) — Integration options

## ❓ FAQ

### Q: How is OctClaw different from other AI agents?
A: OctClaw runs **anywhere shell runs** — no special runtime required. It's designed for universal accessibility, from servers to IoT devices.

### Q: Can I use it without an internet connection?
A: Yes, with local models like Ollama:
```bash
ollama pull mistral
export API_KEY="dummy"
oct config set .api_base '"http://localhost:11434/v1"'
oct config set .model '"mistral"'
```

### Q: How do skills work?
A: Skills are self-documented modules. OctClaw reads SKILL.md files to understand what a skill does and how to use it.

### Q: Is it safe to run arbitrary commands?
A: OctClaw runs with your permissions. Review what it's doing, especially with community skills. Use containers for untrusted environments.

### Q: Can I contribute?
A: Yes! Create skills, improve documentation, report issues. The entire system is designed to be extended.

## 🌍 Connect

- **Website**: [octclaw.xyz](https://octclaw.xyz)
- **GitHub**: [github.com/2045max/octclaw](https://github.com/2045max/octclaw)
- **Issues & Discussions**: GitHub

## 📄 License

MIT License. See [LICENSE](LICENSE).

---

<div align="center">

**Shell is all. Everything can be clawed. 🦞**

[Install Now](#install) · [Quick Start](#quick-start) · [Create Your First Skill](#skills-system)

</div>

---

# 中文

<div align="center">

# 🐙 OctClaw

**Shell 就是一切。万物皆可 claw。🦞**

在任何运行 shell 的地方运行的通用 AI 代理。

<p>
  <img src="https://img.shields.io/badge/shell-3.2%2B_(2006)-4EAA25?logo=gnubash&logoColor=white" alt="Shell 3.2+" />
  <img src="https://img.shields.io/badge/依赖-jq%20%2B%20curl-blue" alt="Dependencies" />
  <img src="https://img.shields.io/badge/内存-%3C%2010MB-purple" alt="Memory" />
  <img src="https://img.shields.io/badge/万物皆可claw-🦞-orange" alt="Everything can be clawed" />
  <a href="https://opensource.org/licenses/MIT">
    <img src="https://img.shields.io/badge/许可证-MIT-yellow.svg" alt="MIT" />
  </a>
</p>

<p>
  <a href="#哲学">哲学</a> &middot;
  <a href="#安装">安装</a> &middot;
  <a href="#快速开始">快速开始</a> &middot;
  <a href="#技能">技能</a> &middot;
  <a href="#命令">命令</a> &middot;
  <a href="#架构">架构</a>
</p>

</div>

---

## 🧠 哲学

### Shell 是通用操作系统

> "Shell 已经在那里了。在你的 Mac、Linux 服务器、树莓派、Android 手机、IoT 设备上。无需安装，无需包管理器，无兼容性问题。
>
> Shell 是通用运行时。OctClaw 让它成为通用 AI 代理。"

OctClaw 建立在一个简单的前提上：**如果它运行 shell，它就能运行 AI 代理**。从你的笔记本电脑到树莓派，从 Android Termux 到嵌入式系统——OctClaw 将 AI 助手带到每个环境。

### 万物皆可 Claw 🦞

章鱼代表**适应性和触达能力**——八只手臂可以与任何系统交互、操作和理解。OctClaw 给你章鱼般的能力来工作：

- **IoT 设备** — 管理传感器，自动化家庭
- **移动电话** — 通过 Termux 进行 Android 自动化
- **服务器** — 系统管理，监控
- **开发环境** — 编码协助
- **个人电脑** — 日常任务，自动化

### OctClaw 哲学

OctClaw 遵循简单而强大的哲学：

1. **自我管理** — 安装自己的工具，配置自己
2. **基于技能** — 通过技能扩展能力
3. **上下文感知** — 理解你的环境和项目
4. **持久性** — 记住对话并从中学习
5. **通用性** — 在任何地方，与任何事物一起工作

### 人类的 AI 代理

OctClaw 不仅仅是一个工具——它是**你的代理**。它为你工作，学习你的偏好，并在你的环境中操作。就像一个可以在你有 shell 的任何地方运行的个人助手。

### 通用兼容性

OctClaw 运行在 **shell 3.2+** 上，这意味着它可以在以下平台工作：

- **macOS** — 2007 年至今的所有版本，零额外安装
- **Linux** — 任何发行版 (Ubuntu, Debian, Fedora, Alpine, Arch...)
- **Android Termux** — 无需 root
- **Windows** — WSL2, Git Bash, Cygwin
- **嵌入式系统** — Alpine 容器、树莓派、CI 运行器、NAS 设备
- **开发板** — 树莓派、NanoPi、Orange Pi 等

### 消息集成

OctClaw 可以连接到你喜欢的消息平台：
- **Telegram** — 个人和群组聊天
- **飞书/钉钉** — 企业协作
- **Discord/Slack** — 社区和团队
- **微信** — 日常沟通
- **邮件** — 自动化处理

一次连接，随处访问。

## 🚀 安装

**一行安装**:

```bash
curl -fsSL https://raw.githubusercontent.com/2045max/octclaw/main/install.sh | bash
```

**手动安装**:

```bash
curl -fsSL https://raw.githubusercontent.com/2045max/octclaw/main/oct -o ~/.local/bin/oct
chmod +x ~/.local/bin/oct
```

**检查依赖**:

```bash
oct doctor  # 需要: shell + jq + curl
```

## ⚡ 快速开始

### 1. 设置 API 密钥

```bash
# 任何 OpenAI 兼容 API 都可以工作
export DEEPSEEK_API_KEY="sk-xxx"  # 有免费额度
# 或
export OPENAI_API_KEY="sk-xxx"
# 或使用本地模型
export API_KEY="dummy"
oct config set .api_base '"http://localhost:11434/v1"'
oct config set .model '"mistral"'
```

### 2. 启动你的代理

```bash
# 交互模式 (REPL)
oct

# 一次性命令
oct "列出当前目录的文件"

# 使用会话管理
oct -s work "检查系统状态"
```

### 3. 添加技能 (可选)

```bash
# 技能扩展 OctClaw 的能力
# 示例: 添加笔记技能
oct "创建一个管理笔记的技能"

# OctClaw 将创建技能并教你如何使用它
```

## 🛠️ 技能系统

### 什么是技能？

技能是 OctClaw 扩展能力的方式。每个技能都是一个自包含的模块，OctClaw 可以理解和使用。

**技能结构**:
```
~/.octclaw/skills/
├── note/
│   ├── SKILL.md          # 技能文档
│   └── note.sh           # 实现
├── weather/
│   ├── SKILL.md
│   └── weather.py
└── system-monitor/
    ├── SKILL.md
    └── monitor.sh
```

### 内置技能

OctClaw 附带基本技能：

| 技能 | 用途 | 示例 |
|------|------|------|
| **文件操作** | 读取、写入、编辑文件 | `oct "读取 config.json"` |
| **Shell 执行** | 运行任何命令 | `oct "检查磁盘使用情况"` |
| **代码搜索** | 查找代码模式 | `oct "查找函数 X 在哪里定义"` |
| **系统信息** | 获取系统状态 | `oct "显示运行中的进程"` |

### 创建技能

你可以让 OctClaw 创建技能，或自己创建：

```bash
# 让 OctClaw 创建技能
oct "创建一个监控网站正常运行时间的技能"

# 或手动创建
mkdir -p ~/.octclaw/skills/uptime
cat > ~/.octclaw/skills/uptime/SKILL.md << 'EOF'
---
name: uptime
description: 监控网站可用性
---

# 正常运行时间监控技能

检查网站是否在线并测量响应时间。

## 用法
检查单个网站：
```bash
curl -I https://example.com
```

监控多个网站：
```bash
for site in google.com github.com; do
  if curl -s --head $site | grep "200 OK"; then
    echo "$site: 在线"
  else
    echo "$site: 离线"
  fi
done
```
EOF
```

### 技能发现

OctClaw 自动发现以下位置的技能：
1. `~/.octclaw/skills/` — 全局技能 (所有会话)
2. `./.octclaw/skills/` — 项目特定技能
3. 会话特定技能目录

## 📟 命令

### 交互命令

运行 `oct` (交互模式) 时，你可以使用：

```
/help           显示所有命令
/exit 或 /quit  退出
/model <name>   切换模型 (gpt-4o, deepseek-chat 等)
/session <name> 切换会话
/sessions       列出所有会话
/clear          清空当前会话
/compact        只保留最近 20 条消息
/skills         列出可用技能
/config         显示配置
```

### CLI 命令

```bash
# 基本用法
oct [flags] [message]

# 标志
-m, --model <name>     模型名称 (默认: gpt-4o)
-s, --session <id>     会话 ID (默认: default)
-c, --continue         继续最近会话
-p, --print            强制非交互输出
--debug                调试输出

# 子命令
oct doctor             检查依赖
oct config             查看或编辑配置
oct sessions           列出会话
oct gateway [端口]     启动网页界面 (默认: 16869)
```

### 配置命令

```bash
# 查看配置
oct config

# 设置值
oct config set .model '"deepseek-chat"'
oct config set .api_base '"https://api.deepseek.com"'
oct config set .temperature '0.7'

# 环境变量也有效
export DEEPSEEK_API_KEY="sk-xxx"
export MODEL="deepseek-chat"
```

## 🏗️ 架构

### 系统概述

```
┌─────────────────────────────────────────────────────────────┐
│                     OctClaw 架构                             │
└─────────────────────────────────────────────────────────────┘

核心组件:
├── 代理引擎          # LLM 交互，工具调用
├── 技能系统          # 可扩展能力
├── 会话管理器        # 对话持久化
├── 配置              # 设置和 API 密钥
└── CLI 界面          # 用户交互

数据结构:
~/.octclaw/
├── config.json          # 配置
├── system.md           # 自定义系统提示词
├── .env                # 环境变量
├── skills/             # 全局技能
├── sessions/           # 对话历史
│   ├── default.jsonl
│   ├── work.jsonl
│   └── ...
└── projects/           # 项目特定数据
    ├── myapp/
    │   ├── .octclaw/
    │   │   ├── skills/     # 项目技能
    │   │   └── context.md  # 项目上下文
    │   └── ...
    └── ...
```

### 代理循环

```bash
1. 用户发送消息
2. 加载会话上下文
3. 发现可用技能
4. 使用上下文 + 技能调用 LLM
5. 如果请求则执行技能
6. 存储结果，如果需要则继续
7. 返回最终响应
```

## 🌐 使用场景

### 个人自动化

```bash
# 日常任务
oct "每天上午 9 点提醒我浇水"
oct "将重要文档备份到云端"

# 信息管理
oct "整理我的下载文件夹"
oct "查找重复文件"
```

### 系统管理

```bash
# 服务器监控
oct "检查所有服务器的磁盘空间"
oct "监控服务状态，如果宕机则重启"

# 安全
oct "扫描开放端口"
oct "检查失败的登录尝试"
```

### 开发协助

```bash
# 项目设置
oct "用 virtualenv 初始化新的 Python 项目"

# 代码维护
oct "更新 package.json 中的依赖"
oct "运行测试并报告覆盖率"

# 调试
oct "查找应用程序中的内存泄漏"
```

### IoT & 嵌入式

```bash
# 树莓派自动化
oct "控制 GPIO 引脚"
oct "读取传感器数据并记录到数据库"

# 家庭自动化
oct "日落时打开灯"
oct "根据天气调整恒温器"
```

## 🔧 高级用法

### 项目上下文

OctClaw 自动从你的项目加载上下文：

```bash
# 创建项目上下文
cat > .octclaw/context.md << 'EOF'
# 项目: 家庭自动化

## 设备
- 客厅灯 (GPIO 17)
- 温度传感器 (I2C 地址 0x76)
- 摄像头 (USB)

## 自动化规则
- 灯在下午 6 点打开，晚上 11 点关闭
- 每 5 分钟记录一次温度
- 运动检测警报
EOF

# 现在 OctClaw 理解你的项目了
oct "检查客厅灯状态"
```

### 自定义系统提示词

```bash
# 定义 OctClaw 的个性
cat > ~/.octclaw/system.md << 'EOF'
# 你是 OctClaw

## 角色
一个可以与任何系统交互的有用 AI 助手。

## 原则
1. 精确可靠
2. 解释你在做什么
3. 需要时请求澄清
4. 尊重安全边界

## 能力
- 执行 shell 命令
- 读/写文件
- 管理技能
- 记住上下文
EOF
```

### 会话管理

```bash
# 处理不同项目
oct -s home-automation "检查所有设备"
oct -s server-admin "更新包"
oct -s personal "整理照片"

# 继续上次的工作
oct -c "接下来是什么？"

# 列出所有会话
oct sessions
```

## 🤝 社区与生态系统

### 技能生态系统

OctClaw 的力量来自其可扩展的技能系统。创建你自己的技能或使用社区贡献的技能：

```bash
# 创建新技能
oct "创建一个监控网站正常运行时间的技能"

# 使用现有技能
oct "有哪些可用的技能？"
```

### 技能类别

- **系统管理** — 监控、备份、安全
- **开发** — 代码生成、测试、部署
- **个人生产力** — 笔记、提醒、组织
- **IoT & 硬件** — GPIO 控制、传感器读取
- **Web & API** — HTTP 请求、API 集成
- **数据处理** — CSV/JSON 操作、分析
- **消息集成** — Telegram、Discord、微信集成

### 技能类别

- **系统管理** — 监控、备份、安全
- **开发** — 代码生成、测试、部署
- **个人生产力** — 笔记、提醒、组织
- **IoT & 硬件** — GPIO 控制、传感器读取
- **Web & API** — HTTP 请求、API 集成
- **数据处理** — CSV/JSON 操作、分析

## 🔒 安全考虑

### 权限模型

OctClaw 以**你的用户权限**运行。它可以：

- 读/写你有权访问的文件
- 执行你可以运行的命令
- 访问你可用的网络资源

### 最佳实践

1. **使用项目特定会话**处理不同的安全上下文
2. **在使用社区技能前审查技能代码**
3. **将 API 密钥权限限制为最小必需**
4. **在敏感环境中监控工具执行**
5. **需要时考虑使用 Docker 容器进行隔离**

### 沙箱选项

```bash
# 在 Docker 容器中运行 (推荐用于不受信任的技能)
docker run -it --rm -v $(pwd):/workspace alpine sh
# 然后在内部安装和运行 OctClaw

# 或使用虚拟机进行完全隔离
```

## 📚 文档

### 快速参考

```bash
# 安装
curl -fsSL https://raw.githubusercontent.com/2045max/octclaw/main/install.sh | bash

# 配置
export DEEPSEEK_API_KEY="sk-xxx"
oct config set .model '"deepseek-chat"'

# 基本用法
oct                          # 交互式
oct "你的命令"               # 一次性
oct -s project "任务"        # 项目会话
oct gateway                  # 网页界面

# 技能管理
oct "列出技能"               # 显示可用技能
oct "为 X 创建技能"          # 请求创建
```

### 进一步阅读

- [详细文档](DOC.md) — 完整使用指南
- [架构参考](ARCHITECTURE_AND_REFERENCE.md) — 系统设计
- [技能开发指南](SKILLS_GUIDE.md) — 创建技能
- [API 参考](API.md) — 集成选项

## ❓ 常见问题

### Q: OctClaw 与其他 AI 代理有什么不同？
A: OctClaw 在**任何运行 shell 的地方运行**——无需特殊运行时。它设计用于通用可访问性，从服务器到 IoT 设备。

### Q: 没有互联网连接可以使用吗？
A: 可以，使用像 Ollama 这样的本地模型：
```bash
ollama pull mistral
export API_KEY="dummy"
oct config set .api_base '"http://localhost:11434/v1"'
oct config set .model '"mistral"'
```

### Q: 技能如何工作？
A: 技能是自文档化的模块。OctClaw 读取 SKILL.md 文件来理解技能做什么以及如何使用它。

### Q: 运行任意命令安全吗？
A: OctClaw 以你的权限运行。审查它在做什么，特别是使用社区技能时。在不受信任的环境中使用容器。

### Q: 我可以贡献吗？
A: 可以！创建技能，改进文档，报告问题。整个系统设计为可扩展的。

## 🌍 联系

- **网站**: [octclaw.xyz](https://octclaw.xyz)
- **GitHub**: [github.com/2045max/octclaw](https://github.com/2045max/octclaw)
- **问题与讨论**: GitHub

## 📄 许可证

MIT 许可证。查看 [LICENSE](LICENSE)。

---

<div align="center">

**Shell 就是一切。万物皆可 claw。🦞**

[立即安装](#安装) · [快速开始](#快速开始) · [创建你的第一个技能](#技能系统)

</div>