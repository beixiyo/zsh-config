#!/usr/bin/env zsh

# git-diff.zsh - A VS Code-like git diff tool using fzf and delta
# Requirements: delta (https://github.com/dandavison/delta), fzf

# 统一预览配置
_git_preview_window="right:75%:border-left:wrap"
# 滚动绑定：键位来自 env（fzfCmdBind/fzfOptionBind）；Ctrl-j/k 滚动，Option/Alt-j/k 多行大步滚动
# fzf 不支持 preview-down,10 这种带参数写法，只能通过重复 action 实现“多行”
_git_scroll_binds="${fzfCmdBind}-j:preview-down,${fzfCmdBind}-k:preview-up,${fzfOptionBind}-j:preview-down+preview-down+preview-down+preview-down+preview-down,${fzfOptionBind}-k:preview-up+preview-up+preview-up+preview-up+preview-up"
_git_option_label="${(C)optionKey}"

function gdiff() {
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Error: Not a git repository."
    return 1
  fi

  # Preview command: 动态判断。如果有 diff 则用 delta，否则（如未跟踪或新文件无 diff）用 bat
  local preview_cmd='
    file={4}
    diff=$(git diff --color=always HEAD -- "$file" 2>/dev/null)
    if [[ -n "$diff" ]]; then
      # FZF_PREVIEW_COLUMNS 可能为空，给 delta 一个安全的默认宽度
      echo "$diff" | delta --side-by-side --width=${FZF_PREVIEW_COLUMNS:-80}
    else
      bat --color=always --style=numbers "$file" 2>/dev/null || echo "No diff available for $file"
    fi'

  local header="ENTER: 打开"$'\n'"CTRL-S: Stage | CTRL-U: Unstage"$'\n'"CTRL-J/K: 滚动 | ${_git_option_label}-J/K: 快速滚动"

  # 列: sortkey(0=已暂存,1=未暂存) \t icon \t status \t path；排序后已暂存在上、未暂存在下；--with-nth=2,4 只显示 icon+path
  local gen_list='git -c core.quotepath=false status --short | awk "
    {
      s = substr(\$0, 1, 3)
      f = substr(\$0, 4)
      idx = substr(s, 1, 1)   # index
      # 有暂存用 plus_box，否则用 minus_box（未暂存或未跟踪）
      if (idx != \" \" && idx != \"?\") { icon = \"\357\220\225\"; key = 0 }
      else { icon = \"\357\214\264\"; key = 1 }
      print key \"\t\" icon \"\t\" s \"\t\" f
    }" | sort -k1,1n'

  eval "$gen_list" | fzf --ansi \
    --header "$header" \
    --header-first \
    --with-nth=2,4 \
    --delimiter="\t" \
    --no-multi \
    --preview "$preview_cmd" \
    --preview-window "$_git_preview_window" \
    --bind "$_git_scroll_binds" \
    --bind "${fzfCmdBind}-s:execute(git add -- {4})+reload($gen_list)" \
    --bind "${fzfCmdBind}-u:execute(git reset -- {4})+reload($gen_list)" \
    --bind "enter:execute(${EDITOR:-nvim} {4} < /dev/tty)+abort"
}

# 浏览 Git Log 并查看详情
function glog() {
  local log_format="%C(auto)%h%d %s %C(black)%C(bold)%cr"
  git log --graph --color=always --format="$log_format" "$@" | \
  fzf --ansi --no-sort --reverse --tiebreak=index \
    --preview "echo {} | grep -o '[a-f0-9]\{7\}' | head -1 | xargs -I % sh -c 'git show --color=always \"\$1\" 2>/dev/null | delta --width=\${FZF_PREVIEW_COLUMNS:-80}' _ %" \
    --preview-window "$_git_preview_window" \
    --bind "$_git_scroll_binds" \
    --header "CTRL-J/K: 滚动预览（${_git_option_label}-J/K: 快速滚动）"
}
