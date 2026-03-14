# 通用安装：按发行版/包管理器执行 install，用法：ins <包名...>

# 根据系统选择安装命令并执行，未识别则报错
ins() {
  if (( ! $# )); then
    echo "用法: ins <包名> [...]"
    return 1
  fi

  local cmd
  if [[ -r /etc/os-release ]]; then
    local id id_like
    id=$(grep -E '^ID=' /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"')
    id_like=$(grep -E '^ID_LIKE=' /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"')

    case "$id $id_like" in
      *arch*)    cmd=(sudo pacman -S --needed --noconfirm) ;;
      *debian*|*ubuntu*|*mint*|*pop*)  cmd=(sudo apt install -y) ;;
      *fedora*|*rhel*|*centos*) cmd=(sudo dnf install -y) ;;
      *opensuse*|*suse*) cmd=(sudo zypper install -y) ;;
      *alpine*)  cmd=(sudo apk add) ;;
      *)
        # 未从 os-release 识别，按包管理器存在性回退
        if command -v pacman &>/dev/null; then
          cmd=(sudo pacman -S --needed --noconfirm)
        elif command -v apt &>/dev/null; then
          cmd=(sudo apt install -y)
        elif command -v dnf &>/dev/null; then
          cmd=(sudo dnf install -y)
        elif command -v zypper &>/dev/null; then
          cmd=(sudo zypper install -y)
        elif command -v apk &>/dev/null; then
          cmd=(sudo apk add)
        else
          echo "未识别的发行版，且未找到 pacman/apt/dnf/zypper/apk"
          return 1
        fi
        ;;
    esac
  elif [[ "$(uname)" == Darwin ]] && command -v brew &>/dev/null; then
    cmd=(brew install)
  else
    echo "未识别的系统（非 Linux /etc/os-release 且非 macOS brew）"
    return 1
  fi

  "${cmd[@]}" "$@"
}
