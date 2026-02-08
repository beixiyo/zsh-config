# 目录 / 文件
mkcd() { mkdir -p "$@" && cd "$@"; }

## 树形列表（可传递归层级，默认 2）。用法：lt [层级] [路径...]
lt() {
  local level=2
  [[ "$1" == <-> ]] && { level=$1; shift }
  eza -l -a --icons --group-directories-first -h --time-style=long-iso --git --git-ignore \
    --ignore-glob "node_modules|.git|.next|dist|.turbo" --tree --level=$level "$@"
}
