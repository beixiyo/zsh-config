# Find Process
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
