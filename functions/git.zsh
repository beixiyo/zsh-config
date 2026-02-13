#!/usr/bin/env zsh

# git-diff.zsh - A VS Code-like git diff tool using fzf and delta
# Requirements: delta (https://github.com/dandavison/delta), fzf

# 统一预览配置
_git_preview_window="right:75%:border-left:wrap"
# 滚动绑定：使用 Ctrl-j/k 类似 Vim 习惯滚动预览；Alt-j/k 多行大步滚动
# fzf 不支持 preview-down,10 这种带参数写法，只能通过重复 action 实现“多行”
_git_scroll_binds="ctrl-j:preview-down,ctrl-k:preview-up,alt-j:preview-down+preview-down+preview-down+preview-down+preview-down,alt-k:preview-up+preview-up+preview-up+preview-up+preview-up"

function gdiff() {
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Error: Not a git repository."
    return 1
  fi

  # Preview command: 动态判断。如果有 diff 则用 delta，否则（如未跟踪或新文件无 diff）用 bat
  local preview_cmd='
    file={3}
    diff=$(git diff --color=always HEAD -- "$file" 2>/dev/null)
    if [[ -n "$diff" ]]; then
      # FZF_PREVIEW_COLUMNS 可能为空，给 delta 一个安全的默认宽度
      echo "$diff" | delta --side-by-side --width=${FZF_PREVIEW_COLUMNS:-80}
    else
      bat --color=always --style=numbers "$file" 2>/dev/null || echo "No diff available for $file"
    fi'

  local header=$'ENTER: 打开\nCTRL-S: Stage | CTRL-U: Unstage\nCTRL-J/K: 滚动 | ALT-J/K: 快速滚动'

  # 列: icon(已暂存/未暂存) \t status \t path；--with-nth=1,3 只显示 icon+path
  local gen_list='git -c core.quotepath=false status --short | awk "
    {
      s = substr(\$0, 1, 3)
      f = substr(\$0, 4)
      idx = substr(s, 1, 1)   # index
      wrk = substr(s, 2, 1)   # worktree
      # 有暂存用 plus_box，否则用 minus_box（未暂存或未跟踪）
      if (idx != \" \" && idx != \"?\") { icon = \"\357\220\225\" }
      else { icon = \"\357\214\264\" }
      print icon \"\t\" s \"\t\" f
    }"'

  eval "$gen_list" | fzf --ansi \
    --header "$header" \
    --header-first \
    --with-nth=1,3 \
    --delimiter="\t" \
    --no-multi \
    --preview "$preview_cmd" \
    --preview-window "$_git_preview_window" \
    --bind "$_git_scroll_binds" \
    --bind "ctrl-s:execute(git add -- {3})+reload($gen_list)" \
    --bind "ctrl-u:execute(git reset -- {3})+reload($gen_list)" \
    --bind "enter:execute(${EDITOR:-nvim} {3} < /dev/tty)+abort"
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
