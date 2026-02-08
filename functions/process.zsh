# 进程管理：fp 选杀、按名/按端口杀

## 显示进程信息并确认后先 TERM 再 KILL
confirm_kill() {
  local pids=$1
  local msg=$2
  if [[ -z "$pids" ]]; then
    echo "未找到匹配的进程"
    return 1
  fi
  echo "找到进程:"
  ps -p ${=pids} -o pid,ppid,user,comm,args
  echo
  read "reply?⚠️  $msg [y/N] "
  if [[ "$reply" =~ ^[Yy]$ ]]; then
    kill ${=pids} 2>/dev/null
    sleep 2
    local remaining
    remaining=()
    for pid in ${=pids}; do
      kill -0 $pid 2>/dev/null && remaining+=($pid)
    done
    if (($#remaining)); then
      echo "⚠️  部分进程未响应 TERM 信号，使用强制终止..."
      kill -9 $remaining 2>/dev/null
      sleep 1
    fi
    local final
    final=()
    for pid in ${=pids}; do
      kill -0 $pid 2>/dev/null && final+=($pid)
    done
    if (($#final)); then
      echo "❌ 以下进程未能终止: $final"
      return 1
    else
      echo "✅ 进程已成功终止"
      return 0
    fi
  else
    echo "❌ 已取消"
    return 1
  fi
}

## 按进程名杀（匹配命令行）
killByName() {
  if (($# == 0)); then
    echo "用法: killByName <进程名称>"
    return 1
  fi
  local pids
  pids=$(pgrep -f "$1" 2>/dev/null)
  confirm_kill "$pids" "确认杀死所有匹配 '$1' 的进程?"
}

## 按端口杀（依赖 lsof）
killByPort() {
  if (($# == 0)); then
    echo "用法: killByPort <端口号>"
    return 1
  fi
  local port=$1
  if [[ ! "$port" =~ ^[0-9]+$ ]]; then
    echo "❌ 端口号必须是数字"
    return 1
  fi
  if ! command -v lsof &>/dev/null; then
    echo "❌ 未找到 lsof 命令"
    return 1
  fi
  local pids
  pids=$(lsof -ti :$port 2>/dev/null)
  confirm_kill "$pids" "确认杀死监听端口 $port 的进程?"
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
          exe=$(readlink -f /proc/$pid/exe 2>/dev/null)
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
  fi
  [[ -z "$pids" ]] && return
  echo "$pids" | xargs -r kill -15 2>/dev/null
  sleep 2
  echo "$pids" | xargs -r kill -9 2>/dev/null
}
