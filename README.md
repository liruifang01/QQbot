# QQseek：DeepSeek QQ 聊天机器人

这是一个运行在 Windows 上的 QQ 官方机器人示例项目。它通过 QQ 开放平台接收私聊消息，使用 DeepSeek 进行聊天和图片理解，使用阿里云百炼生成图片，并把每位用户的聊天上下文保存在本机 SQLite 数据库中。

> 机器人不是普通个人 QQ 号客户端。能否收到私聊消息取决于 QQ 开放平台账号、机器人发布状态和 C2C 私聊权限。代码不能绕过平台权限；建议先在沙箱测试。

## 功能

- QQ 单聊收发消息；最多并行处理数由 `MAX_CONCURRENT_MESSAGES` 设置。
- DeepSeek 多轮聊天、用户图片理解、新闻/实时信息关键词触发的网页搜索。
- 阿里云百炼图片生成：支持明确的 `/画图 描述` 和自然语言自拍/生图请求。
- 从 `images/gifs/` 发送表情包，并使用 `meanings.json` 辅助匹配语义。
- 普通模式与“超级小鲸”模式有独立聊天上下文；超级模式使用独立模型和专业工作助手提示词。
- 每位用户首次私聊及使用 `/reset` 后都会看到使用说明。
- 普通模式下，简短的日常对话若由空行分成多个自然段，会拆成多条消息逐段发送；代码、列表和较长的结构化回答保持一条消息。
- SQLite 按 QQ 用户隔离保存上下文，机器人重启后仍保留。`/reset` 清除该用户两种模式的上下文，并清空 `logs/app.log`。

## 新手安装教程（Windows 10/11）

### 第一步：准备账号和权限

开始前准备以下信息，不要把密钥发给别人：

1. **QQ 开放平台机器人**：创建机器人应用，取得 AppID 和 AppSecret，并配置单聊消息事件及沙箱测试成员。需要使用生产环境时，应先确认应用已取得所需私聊权限并按平台要求发布。
2. **DeepSeek API**：在 DeepSeek 开放平台创建 API Key，确认账户有可用额度。默认模型为 `deepseek-flash`；超级小鲸默认使用 `deepseek-v4-pro`。
3. **阿里云百炼**：开通图片生成模型，创建 API Key，并记下 Workspace ID 和地域。默认图片模型为 `qwen-image-3.0-pro`。图片生成可能产生单独费用。

DeepSeek 的模型、图片输入能力和 DeepSeek Search API 以账户当前开放情况为准，参考[官方 API 文档](https://api-docs.deepseek.com/api/create-chat-completion/)与[搜索接口文档](https://api-docs.deepseek.com/guides/search/)。百炼使用 OpenAI 兼容接口，Workspace ID、地域和模型必须与百炼控制台配置一致，参考[百炼官方说明](https://help.aliyun.com/zh/model-studio/what-is-model-studio)及[图片生成文档](https://help.aliyun.com/zh/model-studio/qwen-image-api)。

### 第二步：安装软件

安装 **Git for Windows** 和 **Python 3.10 或更高版本**。推荐 Python 3.12，并在 Python 安装界面勾选将 Python 加入 PATH。安装后打开 PowerShell 检查：

```powershell
git --version
py --version
```

如果 `py` 命令不存在，重新安装 Python 并启用 Python Launcher，或用 `python --version` 确认 Python 已安装。

### 第三步：下载项目并安装依赖

在 PowerShell 中逐行执行：

```powershell
git clone https://github.com/liruifang01/QQbot.git
cd QQbot
py -3 -m venv .venv
.\.venv\Scripts\python.exe -m pip install --upgrade pip
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
Copy-Item .env.example .env
```

如果电脑没有 `py` 命令，把 `py -3` 改成 `python`。如果下载 GitHub 仓库较慢，可在网页点击 **Code → Download ZIP**，解压后在解压出的 `QQbot` 文件夹打开 PowerShell；从创建虚拟环境那一行继续。

### 第四步：填写密钥和配置

运行以下命令用记事本打开配置：

```powershell
notepad .env
```

至少填写以下项目：

| 配置项 | 填写内容 |
|---|---|
| `DEEPSEEK_API_KEY` | DeepSeek API Key |
| `QQ_BOT_APP_ID` | QQ 开放平台机器人 AppID |
| `QQ_BOT_APP_SECRET` | QQ 开放平台机器人 AppSecret |
| `BAILIAN_API_KEY` | 阿里云百炼 API Key |
| `BAILIAN_WORKSPACE_ID` | 百炼控制台的 Workspace ID |

其他常用配置：

| 配置项 | 默认值/用途 |
|---|---|
| `DEEPSEEK_BASE_URL` | `https://api.deepseek.com`，通常不用改 |
| `DEEPSEEK_MODEL` | 普通聊天及视觉理解模型，默认 `deepseek-flash`；填写账户可用的模型 ID |
| `DEEPSEEK_SUPER_MODEL` | 超级小鲸模型，默认 `deepseek-v4-pro`；该模型用于超级模式及在线搜索回答 |
| `QQ_BOT_SANDBOX` | 沙箱测试保持 `true`；切换生产环境前需先完成平台权限和发布配置 |
| `BAILIAN_REGION` | 百炼 Workspace 所在地域，默认 `cn-beijing` |
| `BAILIAN_BASE_URL` | API 地址模板，通常保持 `.env.example` 中的默认值 |
| `BAILIAN_IMAGE_MODEL` | 默认 `qwen-image-3.0-pro`；必须是当前 Workspace 已开通的模型 |
| `MAX_CONCURRENT_MESSAGES` | 同时处理消息数量，默认 5；不代表 QQ 网关连接数 |
| `DATABASE_PATH` | SQLite 聊天数据文件路径，默认 `./data/chat_history.sqlite3` |
| `CONTEXT_TURNS` | 每次请求携带的历史对话轮数，默认 20 |
| `BOT_NAME`、`BOT_PERSONALITY`、`BOT_APPEARANCE` | 普通模式名称、回复人设和绘图外观描述 |

保留 `=` 左边配置名，只替换右边内容。不要在 `.env` 中填写 QQ 登录密码。真实 `.env` 已被 Git 忽略，**不要把它上传到 GitHub、截图或发到群里**。如果密钥曾经公开，先去对应平台撤销并重新创建。

### 第五步：配置 QQ 沙箱

在 QQ 开放平台机器人控制台中：

1. 开启并订阅私聊/C2C 消息事件。
2. 把用于测试的 QQ 号添加到沙箱允许名单/测试成员。
3. 确认该测试 QQ 已按平台流程添加或打开机器人，并从单聊发送消息。
4. `.env` 中保持 `QQ_BOT_SANDBOX=true`。

如果机器人没有回复，先检查平台是否真的向机器人开放了私聊场景，以及日志中是否收到“QQ 单聊消息事件”。个人开发者权限可能受 QQ 平台规则限制；不要通过修改代码试图绕过权限。正式运行时按开放平台要求完成发布，并在确认有权限后才将沙箱配置改为 `false`。

### 第六步：启动机器人

在项目目录的 PowerShell 中执行：

```powershell
.\.venv\Scripts\python.exe main.py
```

也可以双击/右键运行 `启动机器人.ps1`。看到机器人连接成功日志后，保持窗口打开；按 `Ctrl+C` 停止。需要机器人持续在线时，运行它的电脑或服务器必须保持开机、联网，并且能够访问 QQ、DeepSeek 和阿里云 API。

### 第七步：发送测试消息

在已加入沙箱的 QQ 账号中向机器人私聊：

- `你好`：测试普通聊天。
- `超级小鲸`：切换到专业工作模式；发送 `普通模式` 可切回。
- `帮我看看这张图` 并附带图片：测试图片理解。
- `/画图 雨夜中的蓝发鲸鱼女仆，全身构图`：测试图片生成。
- `给我发一张自拍`：测试自然语言触发生图。
- `/help`：查看帮助；`/reset`：清除自己的两种模式上下文。

每位 QQ 用户首次私聊时会先收到一条使用说明，然后机器人继续处理这条消息；`/reset` 后会再次显示说明。

## 数据、日志和隐私

- 聊天上下文存放在 `data/chat_history.sqlite3`，按 QQ 用户标识隔离；重启不会自动删除。
- `/reset` 清除该用户的普通和超级模式上下文，并清空应用日志 `logs/app.log`。QQ SDK 另有 `botpy.log` 日志。
- 用户文本和图片会发送给 DeepSeek；绘图提示会发送给百炼；图片也会通过 QQ 机器人接口回传。请先告知使用者并遵守各平台的数据和隐私规则。
- API Key 由调用服务计费。图片生成、联网搜索、模型调用可能产生费用，请在 DeepSeek 与阿里云控制台设置预算/用量提醒。
- 不要把 `data/`、`.env`、日志或含真实用户信息的截图作为公开仓库内容。

## 常见问题

### 启动时提示 `Missing required .env setting(s)`

确认已经将 `.env.example` 复制为 `.env`，并且五项必填配置均已填写。注意文件名必须是 `.env`，不要被记事本保存成 `.env.txt`。可在资源管理器启用“查看 → 显示 → 文件扩展名”检查。

### QQ 没有任何回复

检查机器人控制台的私聊消息权限、事件订阅、沙箱成员名单和 `.env` 中 `QQ_BOT_SANDBOX`。确认启动窗口中有“收到 QQ 单聊消息事件”。如果没有，通常是平台没有把事件推送给应用，而不是 DeepSeek 配置问题。

### DeepSeek 报鉴权/模型错误

检查 API Key 是否正确、账户余额/额度是否可用，以及 `DEEPSEEK_MODEL` 和 `DEEPSEEK_SUPER_MODEL` 是否为账户 API 当前支持的模型 ID。不要把 API Key 粘贴到日志或 issue 中。

### 图片生成报 401、403、404 或模型不可用

检查百炼 API Key、Workspace ID、地域、模型名称是否来自同一个工作空间，并确认图片生成服务已开通、有余额/额度。可在百炼控制台先确认所选模型支持当前 OpenAI 兼容图像生成接口。

### 生成成功但 QQ 收不到图片/表情

查看 `logs/app.log` 中是否区分为百炼请求失败或 QQ 富媒体投递失败；同时检查 QQ 机器人私聊场景是否支持媒体消息、文件大小及消息频率限制。不要公开上传完整日志，因为日志可能含平台请求细节。

### 想换模型或换角色

修改 `.env` 中相应模型名、`BOT_PERSONALITY` 或 `BOT_APPEARANCE`，保存后重启机器人。模型 ID 必须在服务端账户实际开通，并与对应接口兼容。

## 技术实现

1. **QQ 接入**：使用腾讯 QQ 官方机器人 Python SDK `qq-botpy` 订阅并接收 C2C 私聊事件，通过官方机器人消息接口返回文本和富媒体。
2. **文本聊天与视觉理解**：`openai` Python SDK 以 OpenAI 兼容格式请求 DeepSeek Chat Completions；历史记录从 SQLite 按用户与模式读取，并作为上下文一并发送。图片附件以图片 URL 内容块交给视觉模型。
3. **新闻联网搜索**：识别“最新/今天/新闻/实时”等信息需求后，先调用 DeepSeek Search API 获取网页结果，再将结果和问题交给聊天模型整理回答。搜索调用与模型调用分别计费规则以 DeepSeek 控制台/官方说明为准。
4. **图片生成**：代码根据自然语言或 `/画图` 判断绘图意图；自拍请求会先让 DeepSeek 设计近几轮场景和动作，再组合 `BOT_APPEARANCE`。随后通过百炼 OpenAI 兼容图像接口生成一张图片，并通过 QQ 富媒体接口发送。`z-image-turbo` 使用单独的百炼 REST 请求分支。
5. **表情包**：`images/gifs/` 存放本地动图，`meanings.json` 保存文件名与含义；DeepSeek 根据上下文选取表情文件，程序将文件上传到 QQ 并发送。
6. **持久化与并发**：Python 内置 `sqlite3` 保存普通/超级两套上下文和模式状态；`asyncio` 处理 QQ 异步事件，线程池承载同步模型请求，Semaphore 限制消息处理并发。
7. **配置与日志**：`python-dotenv` 从本地 `.env` 读取配置；`RotatingFileHandler` 管理应用日志。`.gitignore` 忽略密钥、聊天数据库、虚拟环境和日志。

## 仓库文件

- `main.py`：机器人主程序。
- `启动机器人.ps1`：Windows 启动脚本。
- `启动说明.md`：简要的运行与平台配置说明。
- `机器人开发准备清单.md`：项目需求和方案记录。
- `index_gifs.py`：本地表情包索引相关工具。
- `images/gifs/`：随仓库分发的表情包和语义索引。
- `.env.example`：无密钥配置模板；复制为 `.env` 后填写。
- `requirements.txt`：Python 运行依赖。

表情包是粉丝二创素材，相关角色形象和具体图片版权归原作者或对应权利人；本项目非官方关联。若用于商业用途，请自行联系权利人并确认授权。可查看[表情包素材来源](https://github.com/the-beating-light-of-the-nail/deepseek-chan-meme-pack)了解来源说明。
