# 🐙 OctClaw

单文件 AI 编码助手，纯 Bash 实现。

## 安装

**自动安装**（推荐）：

```bash
curl -fsSL https://raw.githubusercontent.com/2045max/octclaw/main/install.sh | bash
```

**手动安装**：

```bash
curl -fsSL https://raw.githubusercontent.com/2045max/octclaw/main/oct -o ~/.local/bin/oct
chmod +x ~/.local/bin/oct
```

检查依赖：

```bash
oct doctor  # 需要：bash + jq + curl，gateway 额外需要 socat
```

## 配置

```bash
# API 密钥（任选一种）
export API_KEY="sk-..."
export OPENAI_API_KEY="sk-..."
export DEEPSEEK_API_KEY="sk-..."

# 切换模型/接口
oct config set .model '"deepseek-chat"'
oct config set .api_base '"https://api.deepseek.com"'
```

支持所有 OpenAI 兼容 API。

## 使用

```bash
# 默认：交互模式
oct

# 有消息：一次性输出
oct "写个快速排序"

# flags
oct -m deepseek-chat "hello"     # 指定模型
oct -s myproject "fix the bug"   # 指定会话
oct -c "then what?"              # 续上次会话

# 子命令
oct gateway 8080                 # Web 界面
oct doctor                       # 检查依赖
oct config                       # 查看配置
oct sessions                     # 列出会话
```

## 交互 /命令

在交互模式中输入：

```
/model <name>    切换模型
/session <name>  切换会话
/sessions        列出会话
/clear           清空会话
/compact         压缩历史
/tools           列出工具
/help            帮助
/exit            退出
```

## 工具

6 个编码工具：

| 工具 | 用途 |
|------|------|
| `read_file` | 读取文件，支持分页 |
| `write_file` | 创建/覆盖文件 |
| `edit` | 精确匹配替换（核心） |
| `shell` | 执行命令 |
| `grep` | 搜索代码 |
| `find` | 查找文件 |

## 项目上下文

在项目根目录放以下文件会自动加载：

- `AGENTS.md`
- `.octclaw/context.md`
- `.github/copilot-instructions.md`

## 许可证

MIT
