# OctClaw 架构图与快速参考

## 系统架构全景图

```
┌─────────────────────────────────────────────────────────────────────┐
│                        OctClaw 系统架构                              │
└─────────────────────────────────────────────────────────────────────┘

用户交互层:
├── CLI (cli.sh)
│   ├── 交互模式 REPL
│   ├── 一次性模式
│   ├── 标志解析 (-m, -s, -c, -p)
│   └── 子命令路由 (doctor, config, sessions, gateway)
│
├── Web UI (ui.sh)
│   ├── HTML/CSS/JavaScript
│   ├── 聊天界面
│   ├── 会话管理
│   └── 配置编辑
│
└── Telegram Bot (telegram.sh)
    ├── 长轮询消息
    ├── 消息转发到 Agent
    └── 结果回复

        │
        ├─ HTTP Gateway (gateway.sh) [socat]
        │  ├─ POST /api/chat
        │  ├─ GET /api/sessions
        │  ├─ DELETE /api/session/*
        │  └─ GET /api/config
        │
        ↓

业务逻辑层:
┌─────────────────────────────────────────────────────────────────────┐
│                     Agent 核心循环 (agent.sh)                       │
│                                                                      │
│  while iteration < max_turns:                                       │
│    1. 获取用户消息                                                  │
│    2. 加载会话历史                                                  │
│    3. 调用 API (api.sh)                                             │
│    4. 检查 stop_reason:                                             │
│       ├─ "tool_use" → 执行工具 → 继续循环                           │
│       └─ "end_turn" → 返回最终文本                                  │
│    5. 压缩历史                                                      │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘

支持系统:

┌─ System Prompt (prompt.sh)
│  ├─ 用户自定义 (优先)
│  ├─ 默认 Coding Prompt
│  └─ 自动加载项目上下文

┌─ 会话管理 (session.sh)
│  ├─ session_append
│  ├─ session_build_messages
│  ├─ session_prune
│  └─ session_list

┌─ API 调用 (api.sh)
│  ├─ 支持 OpenAI 兼容 API
│  ├─ 工具规格转换
│  └─ 重试机制

┌─ 配置管理 (config.sh)
│  ├─ 命令行 flag
│  ├─ 环境变量
│  ├─ 配置文件
│  └─ 默认值

工具系统 (tools/):
├─ read_file (read.sh)    → 读文件 (分页支持)
├─ write_file (write.sh)  → 写文件 (创建目录)
├─ edit (edit.sh)         → 精确文本替换 ★
├─ shell (shell.sh)       → 执行命令 (超时保护)
├─ grep (grep.sh)         → 搜索代码
└─ find (find.sh)         → 查找文件

持久化层:
└─ 文件系统 (~/.octclaw/)
   ├─ config.json          (配置)
   ├─ .env                 (环境变量)
   ├─ system.md            (自定义提示词)
   └─ sessions/
      ├─ default.jsonl     (会话 1)
      ├─ project.jsonl     (会话 2)
      └─ ...
```

---

## 调用流程详解

### 完整的一个问答流程

```
用户输入: "写个快速排序"
      │
      ↓
oct "写个快速排序"
      │
      ├─ 解析命令行 flags
      ├─ 加载配置
      ├─ 进入 _mode_print 模式
      │
      ↓
agent_run("default", "写个快速排序")
      │
      ├─ 获取模型/API 端点
      ├─ 加载会话文件
      ├─ session_append("user", "写个快速排序")
      │
      ├─ iteration = 1
      │  ├─ 构建消息数组
      │  ├─ 调用 call_api()
      │  │  ├─ 获取 API 密钥
      │  │  ├─ 构建 OpenAI 格式请求
      │  │  ├─ curl POST https://api.openai.com/v1/chat/completions
      │  │  └─ 解析 JSON 响应
      │  │
      │  ├─ response = {
      │  │    "stop_reason": "tool_use",
      │  │    "content": [
      │  │      {"type": "text", "text": "我会为你写一个快速排序..."},
      │  │      {"type": "tool_use", "id": "call_1", "name": "write_file",
      │  │       "input": {"path": "sort.py", "content": "def sort(arr):\n..."}}
      │  │    ]
      │  │  }
      │  │
      │  ├─ stop_reason == "tool_use" ? YES
      │  ├─ session_append("assistant", "我会为你写一个快速排序...")
      │  │
      │  ├─ tool_call_1:
      │  │  ├─ tool_name = "write_file"
      │  │  ├─ session_append_tool_call(...)
      │  │  ├─ tool_execute("write_file", {...})
      │  │  │  ├─ _tool_write_file 执行
      │  │  │  ├─ 创建 sort.py
      │  │  │  └─ 返回 {"ok": true}
      │  │  │
      │  │  ├─ result = {"ok": true}
      │  │  └─ session_append_tool_result(...)
      │  │
      │  └─ continue (返回第 1 轮迭代开头)
      │
      ├─ iteration = 2
      │  ├─ 构建消息数组 (包含工具结果)
      │  ├─ 调用 call_api()
      │  │
      │  ├─ response = {
      │  │    "stop_reason": "end_turn",
      │  │    "content": [
      │  │      {"type": "text", "text": "已完成..."}
      │  │    ]
      │  │  }
      │  │
      │  ├─ stop_reason == "end_turn" ? YES
      │  ├─ session_append("assistant", "已完成...")
      │  ├─ break 退出循环
      │
      ├─ session_prune(...) 压缩历史
      │
      └─ return "已完成..."

输出到终端: "已完成..."
```

---

## 文件读写流程

### 典型编辑场景

```
用户: "在 main.js 的第 10 行后加一行 console.log"
      │
      ↓
agent_run():
      │
      ├─ 第 1 轮 API 调用
      │  ├─ AI 思考: 需要读文件 → 调用 read_file
      │  └─ response 包含 tool_use: read_file
      │
      ├─ 执行 tool: read_file("main.js")
      │  └─ 返回完整文件内容
      │
      ├─ 第 2 轮 API 调用 (带文件内容)
      │  ├─ AI 分析文件
      │  ├─ AI 决定用 edit 工具
      │  └─ response 包含 tool_use: edit
      │
      ├─ 执行 tool: edit({
      │     "path": "main.js",
      │     "old_text": "  return x;  // 第 10-11 行",
      │     "new_text": "  console.log('debug');\n  return x;"
      │   })
      │
      │  edit 工具流程:
      │  ├─ 读文件
      │  ├─ 精确匹配 old_text
      │  ├─ 检查唯一性 (只有一个匹配)
      │  ├─ 执行替换
      │  ├─ 原子写回
      │  └─ 返回 {"ok": true}
      │
      ├─ 第 3 轮 API 调用 (工具结果: ok)
      │  ├─ AI 确认完成
      │  └─ stop_reason: "end_turn"
      │
      └─ return 最终描述
```

---

## 会话持久化示例

### 完整会话文件示例

文件: `~/.octclaw/sessions/myproject.jsonl`

```jsonl
{"role":"user","content":"写一个 Python 类"}
{"type":"tool_call","tool_name":"write_file","tool_id":"call_1","tool_input":{"path":"person.py","content":"class Person:\n    def __init__(self, name):\n        self.name = name"}}
{"type":"tool_result","tool_id":"call_1","content":"{\"ok\":true,\"path\":\"person.py\"}","is_error":false}
{"role":"assistant","content":"已创建 Person 类"}
{"role":"user","content":"添加一个 greet 方法"}
{"type":"tool_call","tool_name":"edit","tool_id":"call_2","tool_input":{"path":"person.py","old_text":"class Person:\n    def __init__(self, name):\n        self.name = name","new_text":"class Person:\n    def __init__(self, name):\n        self.name = name\n    \n    def greet(self):\n        return f'Hello, {self.name}'"}}
{"type":"tool_result","tool_id":"call_2","content":"{\"ok\":true}","is_error":false}
{"role":"assistant","content":"已添加 greet 方法"}
```

### 转换为 API 消息格式

```json
[
  {"role": "user", "content": "写一个 Python 类"},
  {
    "role": "assistant",
    "content": null,
    "tool_calls": [{
      "id": "call_1",
      "type": "function",
      "function": {
        "name": "write_file",
        "arguments": "{\"path\":\"person.py\",\"content\":\"class Person:\\n    def __init__(self, name):\\n        self.name = name\"}"
      }
    }]
  },
  {
    "role": "user",
    "content": [{
      "type": "tool_result",
      "tool_use_id": "call_1",
      "content": "{\"ok\":true,\"path\":\"person.py\"}"
    }]
  },
  {"role": "assistant", "content": "已创建 Person 类"},
  {"role": "user", "content": "添加一个 greet 方法"},
  {
    "role": "assistant",
    "content": null,
    "tool_calls": [{
      "id": "call_2",
      "type": "function",
      "function": {
        "name": "edit",
        "arguments": "{...}"
      }
    }]
  },
  {
    "role": "user",
    "content": [{
      "type": "tool_result",
      "tool_use_id": "call_2",
      "content": "{\"ok\":true}"
    }]
  },
  {"role": "assistant", "content": "已添加 greet 方法"}
]
```

---

## 快速参考表

### 命令行使用

```bash
# 交互模式
oct

# 一次性问答
oct "问题"

# 指定模型
oct -m gpt-4 "问题"

# 指定会话
oct -s work "问题"

# 继续上一个会话
oct -c "继续"

# 强制非交互输出
oct -p "问题"

# 调试输出
oct --debug "问题"

# 版本和帮助
oct -v
oct -h

# 子命令
oct doctor                    # 检查依赖
oct config                    # 查看配置
oct config set .model '"gpt-4"'  # 设置模型
oct sessions                  # 列出会话
oct gateway 8080              # 启动网页服务器
```

### 交互命令

```
/help          - 显示所有命令
/exit 或 /quit - 退出程序
/model gpt-4   - 切换模型
/session work  - 切换会话
/sessions      - 列出所有会话
/clear         - 清空当前会话
/compact       - 压缩历史到最近 20 条
/tools         - 列出可用工具
```

### 环境变量设置

```bash
# API 密钥 (选一个)
export OPENAI_API_KEY="sk-..."
export DEEPSEEK_API_KEY="sk-..."

# 自定义 API 端点
export API_BASE="https://api.deepseek.com"

# 选择模型
export MODEL="gpt-4o"

# 工具调用最大轮数
export MAX_TURNS=10

# Shell 超时 (秒)
export TOOL_SHELL_TIMEOUT=30

# 启用调试
export OCTCLAW_DEBUG=1
```

### 配置文件操作

```bash
# 查看配置
oct config

# 设置配置
oct config set .model '"deepseek-chat"'
oct config set .api_base '"https://api.deepseek.com"'
oct config set .temperature '0.7'

# 直接编辑配置文件
vi ~/.octclaw/config.json

# 自定义 System Prompt
cat > ~/.octclaw/system.md << 'EOF'
你是一个专业的开发者...
EOF

# 环境变量文件
cat > ~/.octclaw/.env << 'EOF'
DEEPSEEK_API_KEY=sk-...
EOF
```

### 会话管理

```bash
# 列出所有会话
oct sessions

# 查看会话文件
cat ~/.octclaw/sessions/default.jsonl

# 删除会话
rm ~/.octclaw/sessions/work.jsonl

# 在交互中清空会话
> /clear

# 压缩会话
> /compact
```

### Web 界面

```bash
# 启动网页服务器
oct gateway 8080

# 或使用默认端口
oct gateway

# 打开浏览器
# http://localhost:8080

# API 端点
POST http://localhost:8080/api/chat
GET http://localhost:8080/api/sessions
DELETE http://localhost:8080/api/session/default
GET http://localhost:8080/api/config
```

### API 端点使用示例

```bash
# 发送消息
curl -X POST http://localhost:8080/api/chat \
  -H "Content-Type: application/json" \
  -d '{"session":"default","message":"写个快速排序"}'

# 列出会话
curl http://localhost:8080/api/sessions

# 获取配置
curl http://localhost:8080/api/config

# 更新配置
curl -X POST http://localhost:8080/api/config \
  -H "Content-Type: application/json" \
  -d '{"model":"deepseek-chat"}'

# 清空会话
curl -X DELETE http://localhost:8080/api/session/default
```

---

## 工具快速参考

### read_file 工具

```
用途: 读取文件内容
输入: {"path": "file.txt", "offset": 0, "limit": 100}
输出: {"content": "...", "lines": 100}
```

### write_file 工具

```
用途: 创建或覆盖文件
输入: {"path": "file.txt", "content": "..."}
输出: {"ok": true, "path": "file.txt"}
```

### edit 工具 (核心)

```
用途: 精确文本替换
输入: {
  "path": "file.txt",
  "old_text": "精确的旧文本",
  "new_text": "新文本"
}
输出: {"ok": true} 或 {"error": "..."}
注意: old_text 必须精确匹配，包括空白字符！
```

### shell 工具

```
用途: 执行 Shell 命令
输入: {"command": "npm test"}
输出: {"stdout": "...", "stderr": "...", "exit_code": 0}
```

### grep 工具

```
用途: 搜索文件内容
输入: {"pattern": "function", "path": "."}
输出: {"matches": [{"file": "main.js", "line": 10, "text": "function foo()"}]}
```

### find 工具

```
用途: 查找文件
输入: {"name": "*.json"}
输出: {"files": ["package.json", "config.json"]}
```

---

## 常见工作流

### 工作流 1: 创建新项目

```bash
oct -s myproject

> 初始化一个 Node.js 项目
[AI 调用 shell 工具执行 npm init]

> 创建 src/index.js
[AI 调用 write_file 工具]

> 添加 package.json 脚本
[AI 调用 edit 工具]

> /exit
```

### 工作流 2: 代码审查和修复

```bash
oct -s review

> 读取 src/main.ts
[AI 调用 read_file 工具]

> 找出性能问题
[AI 分析代码]

> 修复这个问题
[AI 调用 edit 工具]

> 运行测试
[AI 调用 shell 工具]

> /session default
[切换到默认会话，保存审查会话]
```

### 工作流 3: 学习编程

```bash
oct

> 教我如何写一个 REST API (Python Flask)
[AI 详细解释]

> 给我一个完整的例子
[AI 创建示例代码]

> 解释这段代码的中间件部分
[AI 解释]

> 让我试试看，/exit
[用户去修改代码，下次继续]

oct -c
[继续之前的会话]
```

---

## 故障排查

### 问题: "API key not found"

```bash
解决:
  export OPENAI_API_KEY="sk-..."
  或
  oct config set .api_key '"sk-..."'
```

### 问题: "jq is required but not found"

```bash
解决:
  # Ubuntu/Debian
  sudo apt install jq
  
  # macOS
  brew install jq
  
  检查:
  oct doctor
```

### 问题: "socat is required but not found" (gateway 模式)

```bash
解决:
  # Ubuntu/Debian
  sudo apt install socat
  
  # macOS
  brew install socat
  
  检查:
  oct doctor
```

### 问题: Web 服务器无法访问

```bash
检查:
  oct gateway 8080 &
  
  curl http://localhost:8080/
  
  查看防火墙:
  sudo ufw allow 8080
```

### 问题: 编辑工具说 "old_text not found"

```bash
原因: old_text 必须精确匹配
解决:
  1. 检查空白字符 (Tab vs 空格)
  2. 检查换行符 (Unix vs Windows)
  3. 提前 /read_file 查看确切的文本
  4. 使用 /grep 查找相似行
```

---

## 性能优化建议

### 1. 历史管理

```bash
# 自动压缩历史
> /compact

# 清空冗长会话
> /clear
oct -s newsession "继续任务"
```

### 2. 模型选择

```bash
# 简单任务用快速模型
oct -m gpt-3.5-turbo "生成代码框架"

# 复杂任务用强力模型
oct -m gpt-4 "设计系统架构"

# 本地快速模型
oct -m mistral "快速测试"
```

### 3. 提示词优化

```bash
# 自定义高效的 System Prompt
cat > ~/.octclaw/system.md << 'EOF'
# 角色
你是一个专业的 Python 开发者。

# 指导原则
- 回答简洁、直接
- 代码优先，说明其次
- 总是包含错误处理
- 使用最佳实践

# 禁止
- 冗长解释
- 过度设计
- 忽视安全性
EOF
```

---

## 总结

| 层级 | 组件 | 责任 |
|------|------|------|
| **用户界面** | CLI / Web / Telegram | 接收用户输入，显示结果 |
| **业务逻辑** | Agent Loop | 执行工具调用循环 |
| **API 集成** | call_api | 与 LLM 通信 |
| **数据管理** | Session / Config | 持久化状态 |
| **工具系统** | 6 tools | 执行实际操作 |
| **支持系统** | Prompt / Utils | 辅助功能 |

**核心优势**:
- ✅ 纯 Bash 实现，易于审计
- ✅ 工具调用循环，自动化工作
- ✅ 多运行模式，灵活使用
- ✅ 会话持久化，保存进度
- ✅ 项目上下文，智能处理

**使用场景**:
- 代码生成和编辑
- 项目快速启动
- 代码审查和优化
- 学习和教学
- 自动化脚本生成
