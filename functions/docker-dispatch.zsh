# 仅被 dd 的 fzf execute 子进程 source，不暴露到交互式 shell 全局

_fd_parse_ids() {
  local kind="$1"
  shift
  local line id
  for line in "$@"; do
    [[ -z "$line" ]] && continue
    if [[ "$line" == C* ]]; then
      [[ "$kind" != "container" ]] && continue
      id=$(echo "$line" | cut -f2)
      [[ -n "$id" ]] && echo "$id"
    elif [[ "$line" == I* ]]; then
      [[ "$kind" != "image" ]] && continue
      id=$(echo "$line" | cut -f2)
      [[ -n "$id" ]] && echo "$id"
    fi
  done
}

## 取选中行里第一个 ID（容器或镜像均可，用于 copy）
_fd_first_id() {
  local line id
  for line in "$@"; do
    [[ -z "$line" || "$line" != [CI]* ]] && continue
    id=$(echo "$line" | cut -f2)
    [[ -n "$id" ]] && { echo "$id"; return }
  done
}

_fd_do() {
  local action="$1"
  shift
  local cids iids id first
  case "$action" in
    logs)
      cids=($(_fd_parse_ids container "$@"))
      first="${cids[1]}"
      [[ -n "$first" ]] && sudo docker logs -f "$first"
      ;;
    exec)
      cids=($(_fd_parse_ids container "$@"))
      first="${cids[1]}"
      if [[ -n "$first" ]]; then
        sudo docker exec -it "$first" bash 2>/dev/null || sudo docker exec -it "$first" sh
      fi
      ;;
    copy)
      first=$(_fd_first_id "$@")
      if [[ -n "$first" ]]; then
        if command -v clip.exe &>/dev/null; then
          printf '%s' "$first" | clip.exe
          echo "Copied: $first"
        else
          echo "$first"
        fi
      fi
      ;;
    stop)
      cids=($(_fd_parse_ids container "$@"))
      [[ ${#cids[@]} -gt 0 ]] && echo "$cids" | xargs -r sudo docker stop
      ;;
    run)
      cids=($(_fd_parse_ids container "$@"))
      [[ ${#cids[@]} -gt 0 ]] && echo "$cids" | xargs -r sudo docker start
      ;;
    restart)
      cids=($(_fd_parse_ids container "$@"))
      [[ ${#cids[@]} -gt 0 ]] && echo "$cids" | xargs -r sudo docker restart
      ;;
    delete)
      cids=($(_fd_parse_ids container "$@"))
      if [[ ${#cids[@]} -gt 0 ]]; then
        echo "$cids" | xargs -r sudo docker stop 2>/dev/null
        echo "$cids" | xargs -r sudo docker rm
      fi
      ;;
    image)
      iids=($(_fd_parse_ids image "$@"))
      [[ ${#iids[@]} -gt 0 ]] && echo "$iids" | xargs -r sudo docker rmi
      ;;
    force)
      iids=($(_fd_parse_ids image "$@"))
      for id in "${iids[@]}"; do
        sudo docker ps -aq --filter "ancestor=$id" | xargs -r sudo docker stop 2>/dev/null
        sudo docker ps -aq --filter "ancestor=$id" | xargs -r sudo docker rm 2>/dev/null
        sudo docker rmi -f "$id" 2>/dev/null
      done
      ;;
  esac
}
