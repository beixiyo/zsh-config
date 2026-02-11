# Docker Hub v2 API
# - repo 形如: clickhouse/clickhouse-server
# - tag  形如: 26.1.2 / latest
#
# 用法:
#   dinfo clickhouse/clickhouse-server 26.1.2
#   dinfo clickhouse/clickhouse-server 26.1.2 arm64 linux
#
# 输出(依次):
#   1) 仓库信息(JSON)
#   2) tag 信息(JSON)
#   3) 当前 arch/os 下的 digest + size(MiB)
dinfo() {
  if [[ -z "$1" || "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Usage: dinfo <repo> <tag> [arch] [os]"
    echo "Example: dinfo clickhouse/clickhouse-server 26.1.2 arm64 linux"
    return 0
  fi

  local repo="$1"
  local tag="${2:?tag required (e.g. 26.1.2)}"
  local arch="${3:-amd64}"
  local os="${4:-linux}"

  echo "== repo: ${repo} =="
  curl -fsSL "https://hub.docker.com/v2/repositories/${repo}" | jq .
  echo

  echo "== tag: ${repo}:${tag} =="
  curl -fsSL "https://hub.docker.com/v2/repositories/${repo}/tags/${tag}" | jq .
  echo

  echo "== images (os=${os}, arch=${arch}) =="
  curl -fsSL "https://hub.docker.com/v2/repositories/${repo}/tags/${tag}" \
  | jq -r --arg arch "$arch" --arg os "$os" '
      .images[]
      | select(.architecture==$arch and .os==$os)
      | "\(.digest)  \(.size/1024/1024) MiB"
    '
}

# Docker + fzf（统一查看与操作）
_fd_ps_format='table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Names}}'
_fd_ps_running='table {{.ID}}\t{{.Image}}\t{{.Names}}'
_fd_img_format='table {{.ID}}\t{{.Repository}}\t{{.Tag}}\t{{.Size}}'

## 操作指南（语义化快捷键）
#  Tab    多选
#  l      Logs     看日志（-f，仅容器）
#  e      Exec     进入容器（仅容器）
#  c      Copy     复制 ID 到剪贴板
#  s      Stop     停止容器
#  r      Run      运行容器
#  R      Restart  重启容器
#  d      Rm-Cont  删除容器（先 stop 再 rm）
#  i      Rm-Img   删除镜像 (rmi)
#  F      Force    强制删除镜像及其关联容器
_fd_guide="Tab:多选 | l:Logs | e:Exec | c:Copy-ID | s:Stop | r:Run | R:Restart
d:Rm-Cont(Stop+Rm) | i:Rm-Img(rmi) | F:Rm-Img-Force(Img+Conts)"

## 统一 Docker 面板：容器 + 镜像，Tab 多选，快捷键执行操作（内部逻辑在 functions/docker-dispatch.zsh，仅子进程 source，不提升全局）
dd() {
  local data choice _fd_src
  _fd_src=~/.zsh/functions/docker-dispatch.zsh

  data=$(
    echo "=== CONTAINERS ==="
    sudo docker ps -a --format "$_fd_ps_format" | while IFS= read -r line; do echo "C	${line}"; done
    echo ""
    echo "=== IMAGES ==="
    sudo docker images --format "$_fd_img_format" | while IFS= read -r line; do echo "I	${line}"; done
  )

  choice=$(echo "$data" | fzf -m --bind tab:toggle \
    --header "$_fd_guide" \
    --header-lines 0 \
    --bind "l:execute(zsh -c 'source $_fd_src 2>/dev/null; _fd_do logs \"\$@\"' _ {+} </dev/tty)+abort" \
    --bind "e:execute(zsh -c 'source $_fd_src 2>/dev/null; _fd_do exec \"\$@\"' _ {+} </dev/tty)+abort" \
    --bind "c:execute(zsh -c 'source $_fd_src 2>/dev/null; _fd_do copy \"\$@\"' _ {+})+abort" \
    --bind "s:execute(zsh -c 'source $_fd_src 2>/dev/null; _fd_do stop \"\$@\"' _ {+})+abort" \
    --bind "r:execute(zsh -c 'source $_fd_src 2>/dev/null; _fd_do run \"\$@\"' _ {+})+abort" \
    --bind "R:execute(zsh -c 'source $_fd_src 2>/dev/null; _fd_do restart \"\$@\"' _ {+})+abort" \
    --bind "d:execute(zsh -c 'source $_fd_src 2>/dev/null; _fd_do delete \"\$@\"' _ {+})+abort" \
    --bind "i:execute(zsh -c 'source $_fd_src 2>/dev/null; _fd_do image \"\$@\"' _ {+})+abort" \
    --bind "F:execute(zsh -c 'source $_fd_src 2>/dev/null; _fd_do force \"\$@\"' _ {+})+abort" \
    | sed 's/^[CI]\t//' | awk -F'\t' '{print $1}'
  )

  [[ -n "$choice" ]] && echo "Selected: $choice"
}

## 选一个运行中容器 → exec 进去（默认 bash，无则 sh）
dex() {
  local line
  line=$(sudo docker ps --format "$_fd_ps_running" | fzf --header "Select container to exec into" --header-lines 1)
  [[ -z "$line" ]] && return
  local id=$(echo "$line" | awk '{print $1}')
  sudo docker exec -it "$id" bash 2>/dev/null || sudo docker exec -it "$id" sh
}

## 选一个容器 → 实时看 logs（-f）
dlogs() {
  local line
  line=$(sudo docker ps -a --format "$_fd_ps_format" | fzf --header "Select container for logs -f" --header-lines 1)
  [[ -z "$line" ]] && return
  local id=$(echo "$line" | awk '{print $1}')
  sudo docker logs -f "$id"
}

## 选一个容器 → 复制 ID 到剪贴板（WSL: clip.exe）
dcp() {
  local line
  line=$(sudo docker ps -a --format "$_fd_ps_format" | fzf --header "Select container (copy ID)" --header-lines 1)
  [[ -z "$line" ]] && return
  local id=$(echo "$line" | awk '{print $1}')
  if command -v clip.exe &>/dev/null; then
    printf '%s' "$id" | clip.exe
    echo "Copied: $id"
  else
    echo "$id"
  fi
}
