# 新成员工程拉取与 Godot MCP 配置指南

本文给新加入项目的伙伴使用，目标是从零把工程拉下来、用正确版本的 Godot 打开项目，并让 AI 助手通过 Godot MCP 连接到编辑器。

## 1. 推荐方式：让 AI 帮你安装和配置

如果你使用的是 Codex、Claude Code、Cursor、Cline 或其他可以操作本机终端/文件的 AI 助手，推荐直接让 AI 帮你完成大部分环境安装与配置。

下面每个安装或配置步骤下面都有一段“让 AI 帮我”的提示词。需要哪一步，就复制哪一段给 AI；如果你想自己手动处理，也可以直接按文档里的命令执行。

即使让 AI 帮忙，也建议新成员读一遍对应章节，知道 AI 正在检查什么、安装什么、修改什么。

## 2. 需要提前安装的软件

### Git

用于拉取工程代码。

下载地址：

https://git-scm.com/downloads

安装完成后，在终端中检查：

```powershell
git --version
```

如果想让 AI 帮你安装 Git，可以复制：

```text
请帮我检查并安装 Git for Windows。

请你：
1. 先在终端运行 git --version，检查本机是否已经安装 Git。
2. 如果已经安装，请告诉我当前版本，并确认 git 命令可用。
3. 如果没有安装，请帮我安装 Git for Windows。
4. 安装完成后重新打开终端或刷新 PATH，再运行 git --version。
5. 最后告诉我 Git 是否安装成功。
```

### TortoiseGit

TortoiseGit 是 Windows 上常用的 Git 图形界面工具，不是必需，但对不熟悉命令行的成员很有帮助。

下载地址：

https://tortoisegit.org/download/

如果选择安装，建议先安装 Git for Windows，再安装 TortoiseGit。

如果想让 AI 帮你安装 TortoiseGit，可以复制：

```text
请帮我检查并安装 TortoiseGit。

请你：
1. 先检查本机是否已经安装 Git for Windows。如果没有，请先提醒我安装 Git。
2. 检查本机是否已经安装 TortoiseGit。
3. 如果没有安装，请询问我是否需要安装 TortoiseGit。
4. 如果我确认需要，请帮我安装 TortoiseGit。
5. 安装完成后告诉我是否需要重启资源管理器或电脑。
```

### Node.js

Godot MCP Pro 的 server 需要 Node.js 18 或更高版本。

推荐安装 Node.js LTS 版本；如果已经安装了 Node.js 22、24 或更高版本，也可以继续使用。

下载地址：

https://nodejs.org/

安装完成后，在 PowerShell 中检查：

```powershell
node --version
npm.cmd --version
```

如果直接运行 `npm --version` 提示 `npm.ps1 cannot be loaded because running scripts is disabled on this system`，不要急着改系统策略，直接使用 `npm.cmd` 即可。

如果想让 AI 帮你安装 Node.js，可以复制：

```text
请帮我检查并安装 Node.js。

请你：
1. 运行 node --version，检查是否已经安装 Node.js。
2. 如果已安装，请确认版本是否为 18 或更高。
3. 运行 npm.cmd --version，确认 npm 可用。
4. 如果 Node.js 没有安装，或版本低于 18，请帮我安装 Node.js LTS。
5. 如果 PowerShell 里 npm 报执行策略错误，请优先使用 npm.cmd，不要直接修改整机执行策略。
6. 安装完成后告诉我 node --version 和 npm.cmd --version 的结果。
```

### Godot

本项目当前使用 Godot 4.6 系列。

推荐版本：

```text
Godot_v4.6.2-stable_win64.exe
```

推荐下载 Standard 版本，不需要 .NET 版本。

Windows 下载页：

https://godotengine.org/download/windows/

项目中的 `project.godot` 当前写入了：

```text
config/features=PackedStringArray("4.6", "Forward Plus")
```

所以请不要使用 Godot 4.5 或更低版本打开项目。不同成员尽量保持同一个 4.6.x patch 版本，避免导入缓存、场景保存格式或资源 `.import` 文件出现不必要的差异。

如果想让 AI 帮你安装 Godot，可以复制：

```text
请帮我检查并安装 Godot。

本项目需要 Godot 4.6.x，推荐版本是：
Godot_v4.6.2-stable_win64.exe

请你：
1. 检查本机是否已经有 Godot 4.6.x。
2. 如果没有，请帮我下载或安装 Godot 4.6.2 stable Windows 64-bit Standard 版本。
3. 不需要安装 .NET 版本。
4. 安装或解压完成后，告诉我 Godot 可执行文件所在路径。
5. 提醒我后续用这个 Godot 打开项目根目录里的 project.godot。
```

## 3. 拉取工程

选择一个本地工作目录，例如：

```powershell
cd E:\
mkdir ProjectEscape
cd ProjectEscape
```

克隆仓库：

```powershell
git clone https://github.com/Quincysss/ProjectEscape.git
cd ProjectEscape
```

仓库地址：

```text
https://github.com/Quincysss/ProjectEscape.git
```

如果仓库是私有仓库，需要先让项目负责人把你的 GitHub 账号加入协作者，或加入对应组织/团队。

拉取完成后检查当前状态：

```powershell
git status
```

正常情况下应该看到类似：

```text
nothing to commit, working tree clean
```

如果想让 AI 帮你拉取工程，可以复制：

```text
请帮我把 ProjectEscape 项目 clone 到本机。

仓库地址：
https://github.com/Quincysss/ProjectEscape.git

请先检查 Git 是否可用，然后选择或询问一个合适的本地目录，执行 git clone。完成后进入项目目录运行 git status，并告诉我结果。
```

## 4. 打开 Godot 工程

1. 启动 `Godot_v4.6.2-stable_win64.exe`。
2. 在 Project Manager 中选择 `Import`。
3. 选择仓库根目录下的 `project.godot`。
4. 导入并打开项目。
5. 首次打开时 Godot 会生成 `.godot/` 导入缓存，这是本地缓存，已经在 `.gitignore` 中忽略，不需要提交。

项目主场景当前是：

```text
res://scenes/base/BaseScene.tscn
```

可以点击右上角运行按钮确认工程能正常启动。

## 5. Godot MCP 的组成

Godot MCP Pro 分两部分：

1. Godot 编辑器插件：在项目内的 `addons/godot_mcp/`。
2. MCP server：在每个人本机单独放置，例如 `E:\godot\godot-mcp-pro-v1.7.0\server\build\index.js`。

本项目已经包含 Godot 编辑器插件，并且 `project.godot` 中已经启用：

```text
[editor_plugins]
enabled=PackedStringArray("res://addons/godot_mcp/plugin.cfg")
```

插件信息当前为：

```text
name="Godot MCP Pro"
version="1.12.0"
```

也就是说，新成员通常不需要手动复制 `addons/godot_mcp/`，只需要准备本机的 MCP server 路径并配置 AI 客户端即可。

## 6. 安装 Godot MCP Pro server

向项目负责人获取 Godot MCP Pro 安装包。当前项目使用的本机示例目录是：

```text
E:\godot\godot-mcp-pro-v1.7.0
```

你可以放在其他位置，例如：

```text
D:\Tools\godot-mcp-pro-v1.7.0
```

进入 server 目录：

```powershell
cd E:\godot\godot-mcp-pro-v1.7.0\server
```

安装依赖并构建：

```powershell
npm.cmd install
npm.cmd run build
```

构建成功后，应存在这个文件：

```text
server\build\index.js
```

可以检查：

```powershell
Test-Path E:\godot\godot-mcp-pro-v1.7.0\server\build\index.js
```

返回 `True` 表示路径正确。

如果想让 AI 只帮你安装和构建 MCP server，可以复制：

```text
请帮我安装并构建 Godot MCP Pro server。

我会提供或已经拥有 godot-mcp-pro-v1.7.0 文件夹。请你：
1. 找到 godot-mcp-pro-v1.7.0/server/package.json。
2. 检查 Node.js 是否是 18 或更高版本。
3. 进入 server 目录运行 npm.cmd install。
4. 运行 npm.cmd run build。
5. 检查 server/build/index.js 是否存在。
6. 最后告诉我完整的 server/build/index.js 路径，后续要写入 .mcp.json。

如果没有找到 godot-mcp-pro-v1.7.0，请告诉我需要向项目负责人获取安装包。
```

## 7. 配置 AI 客户端的 MCP

仓库根目录当前有一个 `.mcp.json` 示例：

```json
{
  "mcpServers": {
    "godot_mcp_pro": {
      "command": "node",
      "args": ["E:/godot/godot-mcp-pro-v1.7.0/server/build/index.js"]
    }
  }
}
```

每个人需要把 `args` 里的路径改成自己电脑上的实际路径。

推荐写法：

```json
{
  "mcpServers": {
    "godot_mcp_pro": {
      "command": "node",
      "args": ["D:/Tools/godot-mcp-pro-v1.7.0/server/build/index.js"],
      "env": {
        "GODOT_MCP_PORT": "6505"
      }
    }
  }
}
```

注意事项：

- JSON 路径推荐使用 `/`，例如 `D:/Tools/...`，避免 Windows 反斜杠转义问题。
- 默认端口是 `6505`。
- 如果多人本机路径不同，改完 `.mcp.json` 后不要随手提交本机路径变更。
- 如果你的 AI 客户端支持全局 MCP 配置，也可以把这段配置放到客户端全局配置里，而不是改仓库内 `.mcp.json`。

让 AI 帮你配置 MCP 时，可以复制：

```text
请帮我配置当前项目的 Godot MCP。

当前项目仓库根目录应该有 .mcp.json。请你：
1. 找到我本机 Godot MCP Pro server 的 server/build/index.js。
2. 如果找不到，请搜索常见目录，例如 E:/godot、D:/Tools、C:/Tools，或询问我安装包位置。
3. 确认 server/build/index.js 真实存在。
4. 修改当前项目 .mcp.json，让 godot_mcp_pro 的 args 指向真实路径。
5. 路径请使用正斜杠。
6. 加上 GODOT_MCP_PORT=6505。
7. 修改完成后检查 JSON 格式是否合法。
8. 提醒我重启 AI 客户端。

注意：.mcp.json 可能包含我的个人本机路径，除非我明确要求，否则不要提交这项改动。
```

## 8. 启动顺序

建议按这个顺序启动：

1. 打开 Godot 项目。
2. 确认 Godot 中 `Project -> Project Settings -> Plugins` 里 `Godot MCP Pro` 是启用状态。
3. 打开需要使用 MCP 的 AI 客户端，例如 Codex、Claude Code、Cursor、Cline 等。
4. 让 AI 客户端从仓库根目录启动，这样它可以读取 `.mcp.json`。
5. 在 AI 客户端中确认能看到 `godot_mcp_pro` 相关工具。

如果连接正常，AI 就可以通过 MCP 读取 Godot 编辑器状态、检查场景、操作节点或运行部分编辑器工具。

## 9. 常见问题

### AI 客户端看不到 Godot MCP 工具

检查：

```powershell
node --version
Test-Path D:\Tools\godot-mcp-pro-v1.7.0\server\build\index.js
```

然后确认 `.mcp.json` 中的路径和本机路径一致。

修改 `.mcp.json` 后，需要重启 AI 客户端。

### Godot 里没有 Godot MCP Pro 插件

检查项目中是否存在：

```text
addons/godot_mcp/plugin.cfg
```

如果存在，打开：

```text
Project -> Project Settings -> Plugins
```

把 `Godot MCP Pro` 启用。

### 端口冲突

默认端口是 `6505`。如果本机已有其他程序占用，可以把 `.mcp.json` 中的端口改成 `6506` 到 `6509` 之间的一个端口：

```json
{
  "mcpServers": {
    "godot_mcp_pro": {
      "command": "node",
      "args": ["D:/Tools/godot-mcp-pro-v1.7.0/server/build/index.js"],
      "env": {
        "GODOT_MCP_PORT": "6506"
      }
    }
  }
}
```

改完后重启 Godot 和 AI 客户端。

### npm 在 PowerShell 中无法运行

如果看到脚本执行策略相关报错，优先使用：

```powershell
npm.cmd install
npm.cmd run build
```

不建议为了这个问题直接修改整机 PowerShell 执行策略。

### 打开项目后出现很多 `.godot/` 文件

这是 Godot 本地导入缓存，正常现象。`.godot/` 已被 `.gitignore` 忽略，不要提交。

### 资源导入文件变化很多

如果打开项目后出现大量 `.import` 或资源元数据变化，先确认 Godot 版本是否是 4.6.x，并尽量和团队使用同一个 patch 版本，例如 `4.6.2-stable`。

## 10. 推荐的日常 Git 流程

开始工作前先同步：

```powershell
git pull
```

为自己的任务创建分支：

```powershell
git checkout -b feature/your-task-name
```

查看改动：

```powershell
git status
git diff
```

提交：

```powershell
git add .
git commit -m "Add your change summary"
```

推送：

```powershell
git push -u origin feature/your-task-name
```

然后在 GitHub 上创建 Pull Request，等待合并。

## 11. 新成员自检清单

- 已能访问 GitHub 仓库：`https://github.com/Quincysss/ProjectEscape.git`
- 已成功 `git clone` 工程。
- 已安装 Godot `4.6.2-stable` 或团队指定的 4.6.x 版本。
- 已能用 Godot 打开 `project.godot`。
- 已能运行主场景 `res://scenes/base/BaseScene.tscn`。
- 已安装 Node.js 18+。
- 已安装并构建 Godot MCP Pro server。
- 已把 AI 客户端 MCP 配置中的 server 路径改成本机路径。
- 已确认 Godot MCP Pro 插件在 Godot 中启用。
- 已重启 AI 客户端并能看到 `godot_mcp_pro` 工具。
