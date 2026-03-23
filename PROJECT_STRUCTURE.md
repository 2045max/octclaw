# OctClaw 项目结构

```
octclaw/
├── oct                          # 主入口脚本
├── install.sh                   # 一键安装脚本
├── cli.sh                       # CLI 核心逻辑
├── .env.example                 # 环境变量模板
│
├── lib/                         # 核心库目录
│   ├── agent.sh                 # AI 代理引擎
│   ├── api.sh                   # API 调用封装
│   ├── config.sh                # 配置管理
│   ├── session.sh               # 会话持久化
│   ├── prompt.sh                # 提示词构建
│   ├── tools.sh                 # 工具调度
│   ├── ui.sh                    # 界面渲染
│   ├── utils.sh                 # 通用工具函数
│   ├── telegram.sh              # Telegram 集成
│   ├── gateway.sh               # Web 网关
│   └── tools/                   # 内置工具
│       ├── read.sh              # 文件读取
│       ├── write.sh             # 文件写入
│       ├── edit.sh              # 文件编辑
│       ├── shell.sh             # Shell 执行
│       ├── find.sh              # 文件查找
│       └── grep.sh              # 代码搜索
│
├── docs/                        # 文档
│   ├── README.md                # 主文档
│   ├── ARCHITECTURE_AND_REFERENCE.md
│   ├── DOC.md
│   └── GITHUB_PAGES_SETUP.md
│
├── web/                         # Web 界面
│   ├── index.html
│   └── octclaw_website.html
│
└── .github/                     # GitHub Actions
    └── workflows/
        └── deploy.yml

## 安装后的目录结构

安装后文件分布：

~/.octclaw/                      # 数据和库目录
├── lib/                         # (从仓库复制)
├── cli.sh                       # (从仓库复制)
├── config.json                  # 配置文件
├── .env                         # 环境变量
├── sessions/                    # 会话历史
│   └── default.jsonl
└── skills/                      # 用户技能

~/.local/bin/oct                 # 可执行文件 (从仓库复制)

## 核心组件关系

```
oct (入口)
 │
 ├─> 设置 OCT_ROOT=$HOME/.octclaw
 │
 ├─> source lib/utils.sh         (工具函数)
 ├─> source lib/config.sh        (读取配置)
 ├─> source lib/session.sh       (加载会话)
 ├─> source lib/api.sh           (API 调用)
 ├─> source lib/tools.sh         (工具管理)
 ├─> source lib/prompt.sh        (构建提示)
 ├─> source lib/agent.sh         (AI 引擎)
 ├─> source lib/telegram.sh      (消息平台)
 ├─> source lib/gateway.sh       (Web 服务)
 ├─> source lib/ui.sh            (界面)
 └─> source cli.sh               (启动 CLI)
      └─> main "$@"
```

## 为什么分两个目录？

| 目录 | 作用 | 原因 |
|-----|------|------|
| `~/.local/bin/` | 可执行文件 | 在 PATH 中，可以直接运行 `oct` |
| `~/.octclaw/` | 库和数据 | 集中管理，不污染 PATH |

这是标准的 Unix 约定：
- `/usr/bin/` 存放可执行文件
- `/usr/lib/` 存放库文件
- `/var/lib/` 存放数据文件
