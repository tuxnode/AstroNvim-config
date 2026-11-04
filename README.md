# AstroNvim 个人配置

基于 [AstroNvim](https://github.com/AstroNvim/AstroNvim) v6 的个人配置，附带一键安装脚本，方便在新设备上快速部署。

## 一键安装

Linux / macOS：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/tuxnode/AstroNvim-config/main/install.sh)
```

也可以先克隆仓库再运行：

```bash
git clone https://github.com/tuxnode/AstroNvim-config.git
cd AstroNvim-config
bash install.sh
```

安装脚本会自动完成：

- 识别 Linux / macOS 及对应的包管理器
- 安装缺失的 `git`、`curl`、`ripgrep`、`fd`、C 编译器等依赖
- 检测 Neovim，低于 0.11 时自动下载官方版本到 `~/.local` 并配置 PATH
- 备份已有的 `~/.config/nvim`、`~/.local/share/nvim`、`~/.local/state/nvim`、`~/.cache/nvim`
- 安装本仓库配置
- 通过 `Lazy.nvim` 同步插件，并通过 `Mason` 安装配置中声明的工具

> 如果仓库是私有的，`raw.githubusercontent.com` 无法直接访问，请使用克隆后运行的方式。

### GitHub 访问较慢时使用镜像

脚本内置了 GitHub 镜像支持，默认镜像为 `https://gh-proxy.com`：

```bash
bash install.sh --mirror
```

也可以同时用镜像下载安装脚本本身：

```bash
bash <(curl -fsSL https://gh-proxy.com/https://raw.githubusercontent.com/tuxnode/AstroNvim-config/main/install.sh) --mirror
```

使用自定义镜像：

```bash
bash install.sh --mirror https://your-mirror.example
```

镜像会用于配置仓库、Neovim 和字体等 GitHub Release 下载，以及 Lazy.nvim 插件克隆。已设置镜像时可用 `--no-mirror` 临时禁用。

## 常用参数

```bash
bash install.sh --help
```

| 参数 | 说明 |
| --- | --- |
| `-y, --yes` | 不询问，直接安装 |
| `--branch <名称>` | 指定分支，默认 `main` |
| `--repo <地址>` | 指定仓库地址 |
| `--no-deps` | 跳过依赖和 Neovim 的自动安装 |
| `--no-backup` | 不备份已有 Neovim 目录 |
| `--with-font` | 额外安装 JetBrainsMono Nerd Font |
| `--mirror [地址]` | 使用 GitHub 镜像，不填地址时使用默认镜像 |
| `--no-mirror` | 禁用 GitHub 镜像 |

也可以通过环境变量 `GITHUB_MIRROR=https://your-mirror.example` 指定镜像。

例如无人值守安装、使用镜像并安装字体：

```bash
bash install.sh --yes --mirror --with-font
```

## 更新配置

```bash
cd ~/.config/nvim
git pull
nvim --headless "+Lazy! sync" +qa
```

然后在 Neovim 中按需执行 `:MasonToolsInstall` 和 `:TSUpdate`。

## 手动安装（不使用脚本）

```bash
mv ~/.config/nvim ~/.config/nvim.bak.$(date +%Y%m%d-%H%M%S)
mv ~/.local/share/nvim ~/.local/share/nvim.bak.$(date +%Y%m%d-%H%M%S)
mv ~/.local/state/nvim ~/.local/state/nvim.bak.$(date +%Y%m%d-%H%M%S)
mv ~/.cache/nvim ~/.cache/nvim.bak.$(date +%Y%m%d-%H%M%S)

git clone https://github.com/tuxnode/AstroNvim-config.git ~/.config/nvim
nvim
```

## 恢复备份

安装脚本会生成 `*.bak.<时间戳>` 形式的备份，例如：

```bash
mv ~/.config/nvim ~/.config/nvim.new
mv ~/.config/nvim.bak.20261104-200938 ~/.config/nvim
```

对 `~/.local/share/nvim`、`~/.local/state/nvim`、`~/.cache/nvim` 同理。
