#!/usr/bin/env zsh

# git-diff.zsh - A VS Code-like git diff tool using fzf and delta
# Requirements: delta (https://github.com/dandavison/delta), fzf

# 统一预览配置
_git_preview_window="right:75%:border-left:wrap"
# 滚动绑定：使用 Ctrl-j/k 类似 Vim 习惯滚动预览
_git_scroll_binds="ctrl-d:preview-page-down,ctrl-u:preview-page-up,ctrl-j:preview-down,ctrl-k:preview-up"

function gdiff() {
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Error: Not a git repository."
    return 1
  fi

  # Preview command: 动态判断。如果有 diff 则用 delta，否则（如未跟踪或新文件无 diff）用 bat
  local preview_cmd='
    file={2}
    diff=$(git diff --color=always HEAD -- "$file" 2>/dev/null)
    if [[ -n "$diff" ]]; then
      # FZF_PREVIEW_COLUMNS 可能为空，给 delta 一个安全的默认宽度
      echo "$diff" | delta --side-by-side --width=${FZF_PREVIEW_COLUMNS:-80}
    else
      bat --color=always --style=numbers "$file" 2>/dev/null || echo "No diff available for $file"
    fi'

  local header=$'ENTER: 打开\nCTRL-S: Stage | CTRL-U: Unstage\nCTRL-J/K: 滚动预览'

  local gen_list='git -c core.quotepath=false status --short | awk "{ s=substr(\$0,1,3); f=substr(\$0,4); print s \"\t\" f }"'

  eval "$gen_list" | fzf --ansi \
    --header "$header" \
    --header-first \
    --with-nth=2 \
    --delimiter="\t" \
    --no-multi \
    --preview "$preview_cmd" \
    --preview-window "$_git_preview_window" \
    --bind "$_git_scroll_binds" \
    --bind "ctrl-s:execute(git add -- {2})+reload($gen_list)" \
    --bind "ctrl-u:execute(git reset -- {2})+reload($gen_list)" \
    --bind "enter:execute(${EDITOR:-nvim} {2} < /dev/tty)+abort"
}

# 浏览 Git Log 并查看详情
function glog() {
  local log_format="%C(auto)%h%d %s %C(black)%C(bold)%cr"
  git log --graph --color=always --format="$log_format" "$@" | \
  fzf --ansi --no-sort --reverse --tiebreak=index \
    --preview "echo {} | grep -o '[a-f0-9]\{7\}' | head -1 | xargs -I % sh -c 'git show --color=always \"\$1\" 2>/dev/null | delta --width=\${FZF_PREVIEW_COLUMNS:-80}' _ %" \
    --preview-window "$_git_preview_window" \
    --bind "$_git_scroll_binds" \
    --header "CTRL-J/K: 滚动预览"
}
