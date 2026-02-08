# ┌────────────────────────────────────────────────┐
# │ 目录 / 文件                                     │
# └────────────────────────────────────────────────┘
mkcd() { mkdir -p "$@" && cd "$@"; }

## 树形列表（可传递归层级，默认 2）。用法：lt [层级] [路径...]
lt() {
  local level=2
  [[ "$1" == <-> ]] && { level=$1; shift }
  eza -l -a --icons --group-directories-first -h --time-style=long-iso --git --git-ignore \
    --ignore-glob "node_modules|.git|.next|dist|.turbo" --tree --level=$level "$@"
}

# ┌────────────────────────────────────────────────┐
# │ Find File / Find String (fzf)                   │
# └────────────────────────────────────────────────┘
# 公共选项（复用）
## 文件预览：bat
_ff_preview="bat --color=always --style=numbers --line-range=:500 {}"
## 行预览（用于 rg 结果 file:line）
_fs_preview="bat --color=always --style=numbers --theme=base16 --highlight-line {2} {1}"
_fs_opts=(
  --disabled --ansi
  --bind "start:reload:rg --column --line-number --no-heading --color=always --smart-case \"\""
  --bind "change:reload:rg --column --line-number --no-heading --color=always --smart-case {q} || true"
  --delimiter :
  --preview "$_fs_preview"
  --preview-window "right:60%:border-left"
)

## 打开方式提示与绑定：仅改此处即可统一 nvim/code
_fzf_open_header="ENTER: nvim | CTRL-O: VSCode"
_fzf_bind_file=( --bind "enter:execute(nvim {} < /dev/tty)" --bind "ctrl-o:execute(code {})" )
_fzf_bind_file_line=( --bind "enter:execute(nvim +{2} {1} < /dev/tty)" --bind "ctrl-o:execute(code -g {1}:{2})" )

## Find File 在当前目录下所有文件里预览，并在右侧用 bat 实时预览
ff() { fzf --preview "$_ff_preview"; }

## Find String 在当前目录下所有文件里搜内容，并在右侧用 bat 实时预览
fs() { fzf "${_fs_opts[@]}" --header "Search Content"; }

## Find File Open 选文件后 ENTER 用 nvim 打开，Ctrl-O 用 VSCode 打开
ffo() {
  fzf --preview "$_ff_preview" --header "$_fzf_open_header" "${_fzf_bind_file[@]}"
}

## Find String Open 搜到内容后 ENTER 用 nvim 打开并跳到行，Ctrl-O 用 VSCode 打开
fso() {
  fzf "${_fs_opts[@]}" \
    --preview-window "right:60%:border-left:+{2}-10" \
    --header "$_fzf_open_header" \
    "${_fzf_bind_file_line[@]}"
}

# ┌────────────────────────────────────────────────┐
# │ Find Process                                    │
# └────────────────────────────────────────────────┘
## 杀进程（Tab 多选，Enter 先 SIGTERM 再 SIGKILL）。先 SIGTERM(15) 再 SIGKILL(9)
fp() {
  local pids
  pids=$(
    (
      echo "PID	MEM(MB)	EXE	COMMAND"
      ps -eo pid,rss,args --sort=-rss | awk '
        NR <= 1 { next }
        {
          pid = $1
          rss = $2
          match($0, /^[ \t]*[0-9]+[ \t]+[0-9]+[ \t]+/)
          args = substr($0, RLENGTH + 1)
          exe = ""
          cmd = "readlink -f /proc/" pid "/exe 2>/dev/null"
          cmd | getline exe
          close(cmd)
          printf "%s\t%.1f\t%s\t%s\n", pid, rss/1024, exe, args
        }
      '
    ) | fzf -m --bind tab:toggle --header "Tab: 多选 | Enter: 先 SIGTERM 再 SIGKILL" --header-lines 1 --reverse | awk -F'\t' '$1 ~ /^[0-9]+$/ {print $1}'
  )
  [[ -z "$pids" ]] && return
  echo "$pids" | xargs -r kill -15 2>/dev/null
  sleep 2
  echo "$pids" | xargs -r kill -9 2>/dev/null
}

# ┌────────────────────────────────────────────────┐
# │ Docker + fzf（统一查看与操作）                    │
# └────────────────────────────────────────────────┘
_fd_ps_format='table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Names}}'
_fd_ps_running='table {{.ID}}\t{{.Image}}\t{{.Names}}'
_fd_img_format='table {{.ID}}\t{{.Repository}}\t{{.Tag}}\t{{.Size}}'

## 操作指南（语义化快捷键）
#  Tab    多选
#  l      Logs  看日志（-f，仅容器）
#  e      Exec  进入容器（仅容器）
#  c      Copy  复制 ID 到剪贴板
#  s      Stop  停止容器
#  r      Run   运行容器
#  R      Restart 重启容器
#  d      Delete 删除容器（先 stop 再 rm）
#  i      delete Image 删除镜像
#  F      Force 强制删除镜像并停止关联容器
_fd_guide="Tab: 多选 | l:Logs | e:Exec | c:Copy | s:Stop | r:Run | R:Restart | d:Delete | i:Image | F:Force 强制删镜像+停容器"

## 统一 Docker 面板：容器 + 镜像，Tab 多选，快捷键执行操作（内部逻辑在 docker-dispatch.zsh，仅子进程 source，不提升全局）
dd() {
  local data choice
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
    --bind "l:execute(zsh -c 'source ~/.zsh/docker-dispatch.zsh 2>/dev/null; _fd_do logs \"\$@\"' _ {+} </dev/tty)+abort" \
    --bind "e:execute(zsh -c 'source ~/.zsh/docker-dispatch.zsh 2>/dev/null; _fd_do exec \"\$@\"' _ {+} </dev/tty)+abort" \
    --bind "c:execute(zsh -c 'source ~/.zsh/docker-dispatch.zsh 2>/dev/null; _fd_do copy \"\$@\"' _ {+})+abort" \
    --bind "s:execute(zsh -c 'source ~/.zsh/docker-dispatch.zsh 2>/dev/null; _fd_do stop \"\$@\"' _ {+})+abort" \
    --bind "r:execute(zsh -c 'source ~/.zsh/docker-dispatch.zsh 2>/dev/null; _fd_do run \"\$@\"' _ {+})+abort" \
    --bind "R:execute(zsh -c 'source ~/.zsh/docker-dispatch.zsh 2>/dev/null; _fd_do restart \"\$@\"' _ {+})+abort" \
    --bind "d:execute(zsh -c 'source ~/.zsh/docker-dispatch.zsh 2>/dev/null; _fd_do delete \"\$@\"' _ {+})+abort" \
    --bind "i:execute(zsh -c 'source ~/.zsh/docker-dispatch.zsh 2>/dev/null; _fd_do image \"\$@\"' _ {+})+abort" \
    --bind "F:execute(zsh -c 'source ~/.zsh/docker-dispatch.zsh 2>/dev/null; _fd_do force \"\$@\"' _ {+})+abort" \
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
