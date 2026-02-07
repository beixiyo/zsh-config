# ------------------------------ 自动设置终端标题（兼容 WSL + WezTerm）
wezterm_set_title() {
  local dir
  dir=$(basename "$PWD")
  print -Pn "\033]0;${dir}\033\\"
}
autoload -Uz add-zsh-hook
add-zsh-hook precmd wezterm_set_title

# Prompt 美化 / 运行时管理 / 智能 cd
eval "$(starship init zsh)"
eval "$(vfox activate zsh)"
eval "$(zoxide init --cmd cd zsh)"

# Fzf 集成：Ctrl+R 历史、Ctrl+T 文件、Alt+C 目录预览、ssh ** Tab 等
source <(fzf --zsh)

# Fzf 预览：cd/rm 用 eza 预览目录，code/vim 等用 bat 预览文件
local -a preview_dir_cmds=(cd rm)
local -a preview_file_cmds=(code vim nvim vi bat cat nano)
_fzf_comprun() {
  local command=$1
  shift

  if (($preview_dir_cmds[(Ie)$command])); then
    fzf --preview 'eza -T --icons --color=always --level=2 --group-directories-first {} | head -200' "$@"

  elif (($preview_file_cmds[(Ie)$command])); then
    fzf --preview 'bat --color=always --style=numbers --line-range=:500 {}' "$@"

  else
    fzf "$@"
  fi
}
