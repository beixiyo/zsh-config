#!/usr/bin/env zsh

# 进程管理：fp 选杀、按名/按端口杀
#
# 设计与约定：
# - 进程查询与 kill 逻辑迁移到 Bun + TypeScript（见 `functions/bun/src/process.ts`）
# - 本文件只负责：
#   - 保留原有函数名：killByName / killByPort / fp
#   - 对接 fzf 交互（fp）
#   - 调用 bun 脚本执行实际的 kill 逻辑（TERM + KILL + 检查）

() {
  local dir="${${(%):-%x}:A:h}"
  PROCESS_BUN_SCRIPT="$dir/bun/src/process.ts"
}

## 按进程名杀（匹配命令行）
killByName() {
  bun run "$PROCESS_BUN_SCRIPT" kill-by-name "$@"
}

## 按端口杀（依赖 lsof）
killByPort() {
  bun run "$PROCESS_BUN_SCRIPT" kill-by-port "$@"
}

# Find Process
## 杀进程（Tab 多选，Enter 先 SIGTERM 再 SIGKILL）
## 无参：全部进程
## fp <端口>：仅该端口监听进程（依赖 lsof）
fp() {
  local pids
  if (($# == 1)) && [[ "$1" =~ ^[0-9]+$ ]]; then
    local port=$1
    if ! command -v lsof &>/dev/null; then
      echo "❌ 未找到 lsof 命令"
      return 1
    fi
    local list
    list=$(lsof -ti :$port 2>/dev/null)
    if [[ -z "$list" ]]; then
      echo "未找到监听端口 $port 的进程"
      return 0
    fi
    pids=$(
      (
        echo "PID	MEM(MB)	EXE	COMMAND"
        for pid in ${=list}; do
          local exe args r
          # macOS 与 Linux 通用：直接用 ps 的 comm / args 字段
          exe=$(ps -p $pid -o comm= 2>/dev/null)
          r=$(ps -p $pid -o rss= 2>/dev/null)
          args=$(ps -p $pid -o args= 2>/dev/null)
          printf "%s\t%.1f\t%s\t%s\n" "$pid" "$(($r/1024))" "$exe" "$args"
        done
      ) | fzf -m --bind tab:toggle --header "端口 $port | Tab: 多选 | Enter: 先 SIGTERM 再 SIGKILL" --header-lines 1 --reverse | awk -F'\t' '$1 ~ /^[0-9]+$/ {print $1}'
    )
  else
    pids=$(
      (
        echo "PID	MEM(MB)	EXE	COMMAND"
        # 使用 pid / rss / comm / args，兼容 macOS / Linux
        ps axo pid,rss,comm,args | awk '
          NR == 1 { next }
          {
            pid = $1
            rss = $2
            exe = $3
            # 第四列开始是完整命令行
            $1=""; $2=""; $3=""
            sub(/^[ \t]+/, "", $0)
            args = $0
            printf "%s\t%.1f\t%s\t%s\n", pid, rss/1024, exe, args
          }
        ' | sort -k2,2nr
      ) | fzf -m --bind tab:toggle --header "Tab: 多选 | Enter: 先 SIGTERM 再 SIGKILL" --header-lines 1 --reverse | awk -F'\t' '$1 ~ /^[0-9]+$/ {print $1}'
    )
  fi
  [[ -z "$pids" ]] && return

  # 使用 bun 脚本执行「先 TERM 再 KILL 并检查」的逻辑
  bun run "$PROCESS_BUN_SCRIPT" kill ${=pids}
}
