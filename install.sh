#!/usr/bin/env bash
set -Eeuo pipefail

REPO_URL="${ASTRONVIM_CONFIG_REPO:-https://github.com/tuxnode/AstroNvim-config.git}"
BRANCH="${ASTRONVIM_CONFIG_BRANCH:-main}"

ASSUME_YES=0
INSTALL_DEPS=1
DO_BACKUP=1
INSTALL_FONT=0

TMP_DIRS=()
cleanup() {
  local dir
  for dir in "${TMP_DIRS[@]:-}"; do
    if [[ -n "$dir" ]]; then
      rm -rf "$dir"
    fi
  done
  return 0
}
trap cleanup EXIT

if [[ -t 1 ]]; then
  C_RESET=$'\033[0m'
  C_INFO=$'\033[32m'
  C_WARN=$'\033[33m'
  C_ERROR=$'\033[31m'
  C_BOLD=$'\033[1m'
else
  C_RESET=""
  C_INFO=""
  C_WARN=""
  C_ERROR=""
  C_BOLD=""
fi

info() { printf '%s==>%s %s\n' "$C_INFO" "$C_RESET" "$*"; }
warn() { printf '%s警告:%s %s\n' "$C_WARN" "$C_RESET" "$*" >&2; }
die() {
  printf '%s错误:%s %s\n' "$C_ERROR" "$C_RESET" "$*" >&2
  exit 1
}

usage() {
  cat <<'EOF'
AstroNvim 配置一键安装脚本

用法:
  bash install.sh [选项]

选项:
  -y, --yes          不询问，直接开始安装
  --branch <名称>    指定仓库分支 (默认: main)
  --repo <地址>      指定仓库地址
  --no-deps          跳过依赖和 Neovim 的自动安装
  --no-backup        不备份已有的 nvim 目录
  --with-font        额外安装 JetBrainsMono Nerd Font
  -h, --help         显示帮助

也可以通过环境变量指定:
  ASTRONVIM_CONFIG_REPO    仓库地址
  ASTRONVIM_CONFIG_BRANCH  分支名称
EOF
}

while (($#)); do
  case "$1" in
    -y|--yes) ASSUME_YES=1 ;;
    --branch)
      [[ $# -ge 2 ]] || die "--branch 需要一个值"
      BRANCH="$2"
      shift
      ;;
    --branch=*) BRANCH="${1#*=}" ;;
    --repo)
      [[ $# -ge 2 ]] || die "--repo 需要一个值"
      REPO_URL="$2"
      shift
      ;;
    --repo=*) REPO_URL="${1#*=}" ;;
    --no-deps) INSTALL_DEPS=0 ;;
    --no-backup) DO_BACKUP=0 ;;
    --with-font) INSTALL_FONT=1 ;;
    -h|--help)
      usage
      exit 0
      ;;
    *) die "未知参数: $1 (使用 --help 查看帮助)" ;;
  esac
  shift
done

confirm() {
  local prompt="$1" reply
  if ((ASSUME_YES)); then return 0; fi
  if [[ -t 0 ]]; then
    read -r -p "$prompt [y/N] " reply || return 1
  elif [[ -r /dev/tty ]]; then
    read -r -p "$prompt [y/N] " reply </dev/tty || return 1
  else
    warn "当前不是交互式终端，请使用 --yes 确认安装"
    return 1
  fi
  [[ "$reply" =~ ^[Yy]$ ]]
}

new_tmpdir() {
  local dir
  dir="$(mktemp -d)"
  TMP_DIRS+=("$dir")
  printf '%s\n' "$dir"
}

OS="$(uname -s)"
case "$OS" in
  Linux|Darwin) ;;
  *) die "仅支持 Linux 和 macOS，当前系统: $OS" ;;
esac

CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
NVIM_CONFIG="$CONFIG_HOME/nvim"

SCRIPT_DIR=""
if [[ -n "${BASH_SOURCE[0]:-}" && -f "${BASH_SOURCE[0]}" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
fi

LOCAL_SOURCE=0
if [[ -n "$SCRIPT_DIR" && -f "$SCRIPT_DIR/init.lua" && -d "$SCRIPT_DIR/lua" ]]; then
  LOCAL_SOURCE=1
fi

IN_PLACE=0
if ((LOCAL_SOURCE)) && [[ "$SCRIPT_DIR" == "$NVIM_CONFIG" ]]; then
  IN_PLACE=1
fi

PKG_MANAGER=""
detect_pkg_manager() {
  if [[ "$OS" == "Darwin" ]]; then
    if command -v brew >/dev/null 2>&1; then
      PKG_MANAGER="brew"
    fi
    return
  fi
  local pm
  for pm in apt-get dnf yum pacman zypper apk; do
    if command -v "$pm" >/dev/null 2>&1; then
      PKG_MANAGER="$pm"
      return
    fi
  done
}

run_as_root() {
  if [[ "$(id -u)" -eq 0 ]]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    die "需要 root 权限安装依赖，但系统没有 sudo"
  fi
}

pkg_install() {
  local pkgs=("$@")
  ((${#pkgs[@]})) || return 0
  [[ -n "$PKG_MANAGER" ]] || return 1
  case "$PKG_MANAGER" in
    apt-get)
      run_as_root apt-get update || warn "apt-get update 失败，继续尝试安装"
      run_as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y "${pkgs[@]}"
      ;;
    dnf) run_as_root dnf install -y "${pkgs[@]}" ;;
    yum) run_as_root yum install -y "${pkgs[@]}" ;;
    pacman) run_as_root pacman -Sy --needed --noconfirm "${pkgs[@]}" ;;
    zypper) run_as_root zypper --non-interactive install -y "${pkgs[@]}" ;;
    apk) run_as_root apk add --no-cache "${pkgs[@]}" ;;
    brew) brew install "${pkgs[@]}" ;;
    *) return 1 ;;
  esac
}

ensure_local_bin_path() {
  local bin="$HOME/.local/bin"
  case ":$PATH:" in
    *":$bin:"*) ;;
    *) export PATH="$bin:$PATH" ;;
  esac
  local line='export PATH="$HOME/.local/bin:$PATH"'
  local rc found=0
  for rc in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
    [[ -f "$rc" ]] || continue
    found=1
    if ! grep -qxF "$line" "$rc" 2>/dev/null; then
      printf '\n# Added by AstroNvim config installer\n%s\n' "$line" >>"$rc"
    fi
  done
  if ((!found)); then
    printf '\n# Added by AstroNvim config installer\n%s\n' "$line" >"$HOME/.profile"
  fi
}

install_system_deps() {
  detect_pkg_manager

  local missing_bootstrap=()
  local cmd
  for cmd in git curl tar unzip; do
    command -v "$cmd" >/dev/null 2>&1 || missing_bootstrap+=("$cmd")
  done

  local need_tools=0
  command -v rg >/dev/null 2>&1 || need_tools=1
  command -v fd >/dev/null 2>&1 || command -v fdfind >/dev/null 2>&1 || need_tools=1
  command -v cc >/dev/null 2>&1 || command -v gcc >/dev/null 2>&1 || need_tools=1
  command -v make >/dev/null 2>&1 || need_tools=1

  if ((${#missing_bootstrap[@]} == 0)) && ((need_tools == 0)); then
    return
  fi

  if [[ -z "$PKG_MANAGER" ]]; then
    warn "未找到包管理器，请手动安装: git curl tar unzip ripgrep fd 编译工具"
    return
  fi

  local bootstrap_pkgs=() tool_pkgs=()
  case "$PKG_MANAGER" in
    apt-get)
      bootstrap_pkgs=(git curl ca-certificates tar unzip)
      tool_pkgs=(ripgrep fd-find build-essential)
      ;;
    dnf|yum)
      bootstrap_pkgs=(git curl ca-certificates tar unzip)
      tool_pkgs=(ripgrep fd-find gcc gcc-c++ make)
      ;;
    pacman)
      bootstrap_pkgs=(git curl ca-certificates tar unzip)
      tool_pkgs=(ripgrep fd base-devel)
      ;;
    zypper)
      bootstrap_pkgs=(git curl ca-certificates tar unzip)
      tool_pkgs=(ripgrep fd gcc gcc-c++ make)
      ;;
    apk)
      bootstrap_pkgs=(git curl ca-certificates tar unzip)
      tool_pkgs=(ripgrep fd build-base)
      ;;
    brew)
      bootstrap_pkgs=(git curl tar unzip)
      tool_pkgs=(ripgrep fd)
      ;;
  esac

  if ((${#missing_bootstrap[@]})); then
    info "安装基础依赖: ${missing_bootstrap[*]}"
    pkg_install "${bootstrap_pkgs[@]}" || warn "基础依赖安装失败，请检查网络或手动安装"
  fi

  if ((need_tools)); then
    info "安装编辑器和 Treesitter 所需工具..."
    pkg_install "${tool_pkgs[@]}" || warn "部分工具安装失败，Neovim 仍可继续安装"
  fi

  if ! command -v fd >/dev/null 2>&1 && command -v fdfind >/dev/null 2>&1; then
    mkdir -p "$HOME/.local/bin"
    ln -sfn "$(command -v fdfind)" "$HOME/.local/bin/fd"
    ensure_local_bin_path
  fi

  hash -r 2>/dev/null || true
}

version_ge() {
  local IFS=.
  local -a current=($1) required=($2)
  local i av bv
  for ((i = 0; i < ${#required[@]}; i++)); do
    av="${current[i]:-0}"
    bv="${required[i]:-0}"
    av="${av%%[!0-9]*}"
    bv="${bv%%[!0-9]*}"
    av="${av:-0}"
    bv="${bv:-0}"
    ((10#$av > 10#$bv)) && return 0
    ((10#$av < 10#$bv)) && return 1
  done
  return 0
}

nvim_version() {
  nvim --version 2>/dev/null | awk 'NR==1 { sub(/^NVIM v/, ""); print $1 }'
}

install_nvim() {
  info "未检测到 Neovim 0.11+，开始安装..."
  if [[ "$OS" == "Darwin" ]]; then
    if command -v brew >/dev/null 2>&1; then
      brew install neovim
      hash -r 2>/dev/null || true
      return
    fi
    die "请先安装 Homebrew 或手动安装 Neovim 0.11+"
  fi

  local arch asset url tmp extracted
  case "$(uname -m)" in
    x86_64|amd64) arch="x86_64" ;;
    aarch64|arm64) arch="arm64" ;;
    *) die "不支持的 CPU 架构: $(uname -m)" ;;
  esac

  asset="nvim-linux-${arch}.tar.gz"
  url="https://github.com/neovim/neovim/releases/latest/download/${asset}"
  tmp="$(new_tmpdir)"

  info "下载 Neovim: $url"
  curl -fL --retry 3 --retry-delay 2 "$url" -o "$tmp/$asset"
  tar -xzf "$tmp/$asset" -C "$tmp"
  extracted="$tmp/nvim-linux-${arch}"
  [[ -d "$extracted" ]] || die "Neovim 压缩包解压失败"

  mkdir -p "$HOME/.local/opt" "$HOME/.local/bin"
  rm -rf "$HOME/.local/opt/nvim"
  mv "$extracted" "$HOME/.local/opt/nvim"
  ln -sfn "$HOME/.local/opt/nvim/bin/nvim" "$HOME/.local/bin/nvim"
  ensure_local_bin_path
  hash -r 2>/dev/null || true
}

check_neovim() {
  if ! command -v nvim >/dev/null 2>&1; then
    if ((INSTALL_DEPS)); then
      install_nvim
    else
      die "未找到 nvim，请先安装 Neovim 0.11+"
    fi
  fi

  local version
  version="$(nvim_version)"
  if [[ -z "$version" ]] || ! version_ge "$version" "0.11.0"; then
    if ((INSTALL_DEPS)); then
      install_nvim
    else
      die "Neovim 版本过低 (当前: ${version:-未知})，需要 0.11+"
    fi
  fi

  command -v nvim >/dev/null 2>&1 || die "Neovim 安装失败"
  version="$(nvim_version)"
  version_ge "$version" "0.11.0" || die "Neovim 版本仍低于 0.11: $version"
  info "Neovim 版本: $version"
}

backup_if_exists() {
  local path="$1"
  [[ -e "$path" || -L "$path" ]] || return 0
  local dest="${path}.bak.$(date +%Y%m%d-%H%M%S)"
  local n=1
  while [[ -e "$dest" || -L "$dest" ]]; do
    dest="${path}.bak.$(date +%Y%m%d-%H%M%S)-$n"
    n=$((n + 1))
  done
  mv "$path" "$dest"
  info "已备份 $path -> $dest"
}

install_config() {
  mkdir -p "$CONFIG_HOME"

  if ((IN_PLACE)); then
    info "当前正从配置目录运行，跳过配置复制"
    return
  fi

  if ((LOCAL_SOURCE)); then
    info "从本地目录安装配置: $SCRIPT_DIR"
    if [[ "$SCRIPT_DIR" != "$NVIM_CONFIG" ]]; then
      mkdir -p "$NVIM_CONFIG"
      cp -a "$SCRIPT_DIR/." "$NVIM_CONFIG/"
    fi
  else
    info "克隆配置仓库: $REPO_URL ($BRANCH)"
    git clone --branch "$BRANCH" "$REPO_URL" "$NVIM_CONFIG"
  fi
}

run_with_timeout() {
  local seconds="$1"
  shift
  if command -v timeout >/dev/null 2>&1; then
    timeout "$seconds" "$@"
  elif command -v gtimeout >/dev/null 2>&1; then
    gtimeout "$seconds" "$@"
  else
    "$@"
  fi
}

bootstrap_plugins() {
  info "同步 lazy.nvim 插件，首次安装可能需要几分钟..."
  if ! run_with_timeout 900 nvim --headless "+Lazy! sync" +qa; then
    warn "插件同步未完全成功，稍后可在 Neovim 中执行 :Lazy sync"
  fi

  info "安装 Mason 工具..."
  if ! run_with_timeout 900 nvim --headless "+MasonToolsInstallSync" +qa; then
    warn "Mason 工具安装未完成，稍后可在 Neovim 中执行 :MasonToolsInstall"
  fi
}

install_font() {
  info "安装 JetBrainsMono Nerd Font..."
  local tmp url dir
  tmp="$(new_tmpdir)"
  url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
  curl -fL --retry 3 --retry-delay 2 "$url" -o "$tmp/font.zip"

  if [[ "$OS" == "Darwin" ]]; then
    dir="$HOME/Library/Fonts"
  else
    dir="$HOME/.local/share/fonts"
  fi
  mkdir -p "$dir"
  unzip -o -q "$tmp/font.zip" '*.ttf' -d "$dir" || warn "字体解压出现问题"
  if command -v fc-cache >/dev/null 2>&1; then
    fc-cache -f "$dir" >/dev/null 2>&1 || true
  fi
  info "字体已安装到 $dir"
}

main() {
  info "AstroNvim 配置一键安装"
  printf '  仓库:     %s\n' "$REPO_URL"
  printf '  分支:     %s\n' "$BRANCH"
  printf '  配置目录: %s\n' "$NVIM_CONFIG"

  if ((IN_PLACE)); then
    printf '  模式:     原地更新（不会替换配置目录）\n'
  fi

  if pgrep -x nvim >/dev/null 2>&1; then
    warn "检测到 Neovim 正在运行，建议先退出以避免文件冲突"
    confirm "仍然继续吗？" || die "已取消"
  fi

  confirm "确认开始安装吗？" || {
    info "已取消"
    exit 0
  }

  if ((INSTALL_DEPS)); then
    install_system_deps
  fi
  command -v git >/dev/null 2>&1 || die "缺少 git，请先安装"

  check_neovim

  if ((DO_BACKUP)); then
    info "备份已有 Neovim 目录..."
    if ((!IN_PLACE)); then
      backup_if_exists "$NVIM_CONFIG"
    fi
    backup_if_exists "$DATA_HOME/nvim"
    backup_if_exists "$STATE_HOME/nvim"
    backup_if_exists "$CACHE_HOME/nvim"
  fi

  install_config
  bootstrap_plugins

  if ((INSTALL_FONT)); then
    install_font
  fi

  info "安装完成"
  printf '\n启动 Neovim:\n  %snvim%s\n' "$C_BOLD" "$C_RESET"
  printf '如遇插件未装完整，可在 Neovim 中运行 :Lazy sync 和 :MasonToolsInstall\n'
}

main "$@"
