# OctClaw 文档

单文件 AI 编码助手。纯 Bash，1200 行。

## 快速开始

```bash
# 安装
curl -fsSL https://raw.githubusercontent.com/2045max/octclaw/main/oct -o ~/.local/bin/oct
chmod +x ~/.local/bin/oct

# 配置 API 密钥
export DEEPSEEK_API_KEY="sk-xxx"

# 运行
oct
```

## 命令方式

### 1. 交互模式（默认）

```bash
oct
```

进入交互式对话。输入问题或用 `/command` 控制：

```
> fix the bug
AI 回复...

> /model gpt-4o
模型已切换

> /clear
会话已清空

> /exit
退出
```

### 2. 一次性问答

```bash
oct "写个快速排序"
```

有消息时自动进入 print 模式，输出后退出。

### 3. Flags（启动时）

```bash
oct -m deepseek-chat "hello"      # 指定模型
oct -s myproject "fix bug"         # 指定会话
oct -c "then what?"                # 续上次会话
oct --debug "test"                 # 调试输出
oct -v                             # 版本号
oct -h                             # 帮助
```

### 4. 子命令

```bash
oct doctor                  # 检查依赖
oct config                  # 查看配置
oct config set .model '"gpt-4o"'    # 设置配置
oct sessions                # 列出所有会话
oct gateway 8080            # 启动 Web 界面（需 socat）
```

### 5. 交互中的 /命令

```
/model <name>        切换模型
/session <name>      切换会话
/sessions            列出会话
/clear               清空当前会话
/compact             压缩历史到最近 20 条消息
/tools               列出可用工具
/help                显示所有命令
/exit                退出
```

## 工具

6 个编码工具，AI 自动调用：

| 工具 | 用途 | 示例 |
|------|------|------|
| `read_file` | 读文件 | 查看代码 |
| `write_file` | 写文件 | 创建新文件 |
| `edit` | 编辑文件 | 精确匹配旧文本，替换为新文本 |
| `shell` | 执行命令 | 运行测试、git、npm |
| `grep` | 搜索代码 | 查找函数定义 |
| `find` | 查找文件 | 按文件名搜索 |

`edit` 是核心——精确匹配旧文本再替换，不会出错。

## 配置

保存在 `~/.octclaw/config.json`。

```bash
# 查看
oct config

# 设置
oct config set .model '"deepseek-chat"'
oct config set .api_base '"https://api.deepseek.com"'
oct config set .temperature '"0.7"'
```

或直接编辑 JSON：

```bash
vi ~/.octclaw/config.json
```

## API 支持

支持所有 OpenAI 兼容 API。

### DeepSeek

```bash
export DEEPSEEK_API_KEY="sk-xxx"
oct config set .api_base '"https://api.deepseek.com"'
oct config set .model '"deepseek-chat"'
```

### 本地 Ollama

```bash
export API_KEY="dummy"
oct config set .api_base '"http://localhost:11434/v1"'
oct config set .model '"mistral"'
```

### OpenAI

```bash
export OPENAI_API_KEY="sk-xxx"
oct config set .model '"gpt-4o"'
```

## 项目上下文

在项目根目录创建以下文件，oct 会自动加载为 prompt 上下文：

- `AGENTS.md` — 项目说明
- `.octclaw/context.md` — OctClaw 专用上下文
- `.github/copilot-instructions.md` — 通用 AI 指令

示例：

```bash
cat > AGENTS.md << 'EOF'
# 项目：MyApp

这是一个 TypeScript 项目。

## 编码规范
- 使用 prettier 格式化
- 必须有 JSDoc 注释
- 100% 测试覆盖率

## 目录结构
- src/ — 源代码
- test/ — 测试
- docs/ — 文档
EOF
```

然后：

```bash
oct "实现一个 API 路由处理器"
```

AI 会自动知道项目的规范。

## 会话

每个会话是独立的 JSONL 文件，保存在 `~/.octclaw/sessions/`。

```bash
# 列出所有会话
oct sessions

# 指定会话
oct -s work "write code"

# 续上次会话
oct -c "继续做"

# 清空当前会话
# （在交互中输入 /clear）
```

## Web 界面

启动 HTTP 服务器（需要 `socat`）：

```bash
oct gateway 8080
```

打开浏览器访问 `http://localhost:8080`。

## 环境变量

| 变量 | 说明 | 默认值 |
|------|------|--------|
| `API_KEY` | 通用 API 密钥 | — |
| `OPENAI_API_KEY` | OpenAI 密钥 | — |
| `DEEPSEEK_API_KEY` | DeepSeek 密钥 | — |
| `API_BASE` | API 地址 | `https://api.openai.com/v1` |
| `MODEL` | 模型名称 | `gpt-4o` |
| `MAX_TURNS` | 最大工具调用轮数 | `10` |
| `OCTCLAW_DEBUG=1` | 调试输出 | 关闭 |
| `TOOL_SHELL_TIMEOUT` | Shell 超时（秒） | `30` |

## 依赖

最少依赖：

- `bash` — shell
- `jq` — JSON 处理
- `curl` — HTTP 请求
- `socat` — 仅 gateway 模式需要

检查：

```bash
oct doctor
```

## 架构

单文件 11 个区块：

```
§1  工具函数
§2  配置管理
§3  会话管理
§4  API 调用
§5  工具系统 (6 个编码工具)
§6  System Prompt
§7  Agent 核心循环
§8  HTTP Gateway
§9  内嵌 Web UI
§10 CLI
§11 主入口
```

约 1200 行。无外部依赖文件。

## 常见问题

### Q: 如何使用不同的模型？

```bash
oct -m gpt-4 "写代码"
# 或
oct config set .model '"gpt-4"'
oct
```

### Q: 如何保存会话？

自动保存。每个会话对应一个 JSONL 文件：

```bash
~/.octclaw/sessions/default.jsonl
~/.octclaw/sessions/myproject.jsonl
```

### Q: 如何清除历史？

```bash
# 交互中
/clear

# 或直接删除文件
rm ~/.octclaw/sessions/default.jsonl
```

### Q: 如何使用 edit 工具？

AI 会自动使用。示例：

```bash
oct "在 src/main.ts 第 10 行后加一个日志语句"
```

AI 会用 edit 工具精确替换。

### Q: Web UI 支持多人协作吗？

不支持。Web UI 是单用户，适合本地使用。

### Q: 可以离线使用吗？

不可以。需要连接到 API 服务（OpenAI、DeepSeek 等）。但可以用本地 Ollama：

```bash
# 启动 Ollama
ollama pull mistral
ollama serve

# 另一个终端
export API_KEY="dummy"
oct config set .api_base '"http://localhost:11434/v1"'
oct config set .model '"mistral"'
oct
```

## 反馈

遇到问题？检查：

```bash
oct --debug "测试消息"
```

看调试输出，或检查日志：

```bash
ls -la ~/.octclaw/
cat ~/.octclaw/sessions/
```
