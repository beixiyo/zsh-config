# Docker：Zsh 为壳（fzf / execute），Bun 为核（列表生成、Docker Hub API）
# 逻辑与格式见 functions/bun/src/docker.ts

() {
  local dir="${${(%):-%x}:A:h}"
  DOCKER_BUN_SCRIPT="$dir/bun/src/docker.ts"
}

# Docker Hub v2 API：仓库 / tag / 当前 arch·os 的 digest·size
# 用法: dinfo <repo> <tag> [arch] [os]，例: dinfo clickhouse/clickhouse-server 26.1.2
dinfo() {
  bun run "$DOCKER_BUN_SCRIPT" dinfo "$@"
}

# 操作指南（语义化快捷键）
_fd_guide="Tab:多选 | l:Logs | e:Exec | c:Copy-ID | s:Stop | r:Run | R:Restart
d:Rm-Cont(Stop+Rm) | i:Rm-Img(rmi，仅镜像)"

# 统一 Docker 面板：容器 + 镜像，数据源与按键逻辑均在 Bun（docker.ts list / dispatch）
# 进入 fzf 前先在本 shell 完成 sudo 认证，否则管道内 bun→sudo 无 TTY 无法输入密码
dd() {
  sudo -v || return 1
  local choice gen_list gen_list_bind dispatch_cmd
  gen_list="bun run \"$DOCKER_BUN_SCRIPT\" list 2>/dev/null"
  gen_list_bind="${gen_list//\"/\\\"} < /dev/null"
  dispatch_cmd="bun run \"$DOCKER_BUN_SCRIPT\" dispatch"

  choice=$(eval "$gen_list" < /dev/null | fzf -m --bind tab:toggle \
    --with-nth 2.. \
    --header "$_fd_guide" \
    --header-lines 0 \
    --bind "l:execute($dispatch_cmd logs {+} </dev/tty)+abort" \
    --bind "e:execute($dispatch_cmd exec {+} </dev/tty)+abort" \
    --bind "c:execute($dispatch_cmd copy {+})+abort" \
    --bind "s:execute($dispatch_cmd stop {+})+abort" \
    --bind "r:execute($dispatch_cmd run {+})+abort" \
    --bind "R:execute($dispatch_cmd restart {+})+abort" \
    --bind "d:execute($dispatch_cmd delete {+})+abort" \
    --bind "i:execute($dispatch_cmd image {+})+abort" \
    --bind "ctrl-r:reload:${gen_list_bind}" \
    | cut -f3- | awk -F'\t' '{print $1}'
  )

  [[ -n "$choice" ]] && echo "Selected: $choice"
}

# 选一个运行中容器 → exec 进去（默认 bash，无则 sh）
dex() {
  sudo -v || return 1
  local line id gen_list
  gen_list="bun run \"$DOCKER_BUN_SCRIPT\" list containers 2>/dev/null"
  line=$(eval "$gen_list" < /dev/null | fzf --header "Select container to exec into" --header-lines 0)
  [[ -z "$line" ]] && return
  id=$(echo "$line" | cut -f1)
  sudo docker exec -it "$id" bash 2>/dev/null || sudo docker exec -it "$id" sh
}

# 选一个容器 → 实时看 logs（-f）
dlogs() {
  sudo -v || return 1
  local line id gen_list
  gen_list="bun run \"$DOCKER_BUN_SCRIPT\" list containers --all 2>/dev/null"
  line=$(eval "$gen_list" < /dev/null | fzf --header "Select container for logs -f" --header-lines 0)
  [[ -z "$line" ]] && return
  id=$(echo "$line" | cut -f1)
  sudo docker logs -f "$id"
}

# 选一个容器 → 复制 ID 到剪贴板（WSL: clip.exe）
dcp() {
  sudo -v || return 1
  local line id gen_list
  gen_list="bun run \"$DOCKER_BUN_SCRIPT\" list containers --all 2>/dev/null"
  line=$(eval "$gen_list" < /dev/null | fzf --header "Select container (copy ID)" --header-lines 0)
  [[ -z "$line" ]] && return
  id=$(echo "$line" | cut -f1)
  if command -v clip.exe &>/dev/null; then
    printf '%s' "$id" | clip.exe
    echo "Copied: $id"
  else
    echo "$id"
  fi
}

# 启动一串 hello-world 级测试容器（约 13KB 镜像 + 1 个常驻），用完可 dclean-test 清理
dtest() {
  sudo -v || return 1
  echo "Creating hello-world level test containers..."
  sudo docker run --name dtest-hw1 hello-world
  sudo docker run --name dtest-hw2 hello-world
  sudo docker run --name dtest-hw3 hello-world
  # 唯一常驻：busybox ~1MB，用于 dex/stop/restart
  sudo docker run -d --name dtest-run busybox:latest sleep infinity
  echo "Started: dtest-hw1, dtest-hw2, dtest-hw3 (exited), dtest-run (running)"
  echo "Try: dd (panel, 加 --all 看 exited) | dex/dlogs/dcp 选 dtest-run"
}

# 停止并删除所有 dtest-* 容器
dclean-test() {
  sudo -v || return 1
  local ids
  ids=$(sudo docker ps -aq -f name=^dtest- 2>/dev/null)
  if [[ -z "$ids" ]]; then
    echo "No dtest-* containers found."
    return 0
  fi
  echo "Stopping and removing: $(echo $ids | tr '\n' ' ')"
  sudo docker rm -f $ids
  echo "Done."
}
