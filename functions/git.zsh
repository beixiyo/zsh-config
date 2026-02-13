#!/usr/bin/env zsh

# git-diff.zsh - A VS Code-like git diff tool using fzf and delta
# Requirements: delta (https://github.com/dandavison/delta), fzf

# 统一预览配置
_git_preview_window="right:75%:border-left:wrap"

# 使用默认值以防环境变量未设置
_fzf_cmd="${fzfCmdBind:-ctrl}"
_fzf_opt="${fzfOptionBind:-alt}"
_git_scroll_binds="${_fzf_cmd}-j:preview-down,${_fzf_cmd}-k:preview-up,${_fzf_opt}-j:preview-down+preview-down+preview-down+preview-down+preview-down,${_fzf_opt}-k:preview-up+preview-up+preview-up+preview-up+preview-up"
_git_option_label="${(C)${optionKey:-alt}}"

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

  local header="ENTER: 打开"$'\n'"CTRL-S: Stage | CTRL-U: Unstage"$'\n'"CTRL-J/K: 滚动 | ${_git_option_label}-J/K: 快速滚动"

  # 列: icon \t status \t path；按 path 排序使列表顺序稳定，暂存/取消暂存时仅该行图标变化、行位置不变，避免 reload 后 fzf 光标错位
  # 优化：剥离 git status 输出中的引号，并修正 sort 的 tab 分隔符
  local gen_list="git -c core.quotepath=false status --short | awk '
    {
      s = substr(\$0, 1, 3)
      f = substr(\$0, 4)
      gsub(/^[ \\t]+|[ \\t]+\$/, \"\", f)
      if (f ~ /^\"/) { f = substr(f, 2, length(f)-2); gsub(/\\\\/, \"\", f) }
      idx = substr(s, 1, 1)   # index
      if (idx != \" \" && idx != \"?\") { icon = \"\357\220\225\" }
      else { icon = \"\357\214\264\" }
      printf \"%s\\t%s\\t%s\\n\", icon, s, f
    }' | sort -t\$'\\t' -k3,3"

  eval "$gen_list" | fzf --ansi \
    --header "$header" \
    --header-first \
    --with-nth=1,3 \
    --delimiter="\t" \
    --no-multi \
    --preview "$preview_cmd" \
    --preview-window "$_git_preview_window" \
    --bind "$_git_scroll_binds" \
    --bind "${_fzf_cmd}-s:execute(git add -- {3})+reload:${gen_list}" \
    --bind "${_fzf_cmd}-u:execute(git reset -- {3})+reload:${gen_list}" \
    --bind "enter:execute(${EDITOR:-nvim} {3} < /dev/tty)+abort"
}


# 浏览 Git Log 并查看详情
function glog() {
  local log_format="%C(auto)%h%d %s %C(black)%C(bold)%cr"
  git log --graph --color=always --format="$log_format" "$@" | \
  fzf --ansi --no-sort --reverse --tiebreak=index \
    --preview "git show --color=always \$(echo {q} | grep -o '[a-f0-9]\{7,40\}' | head -1) 2>/dev/null | delta --width=\${FZF_PREVIEW_COLUMNS:-80}" \
    --preview-window "$_git_preview_window" \
    --bind "$_git_scroll_binds" \
    --header "CTRL-J/K: 滚动预览（${_git_option_label}-J/K: 快速滚动）"
}
