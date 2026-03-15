# 有 fastfetch 则启动时执行一次（系统信息概览）
command -v fastfetch &>/dev/null && fastfetch

# ------------------------------ 自动设置终端标题（兼容 WSL + WezTerm）
wezterm_set_title() {
  local dir
  dir=$(basename "$PWD")
  print -Pn "\033]0;${dir}\033\\"
}
autoload -Uz add-zsh-hook
add-zsh-hook precmd wezterm_set_title

# Prompt 美化 / 运行时管理 / 智能 cd（未安装则跳过，不报错）
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"
command -v vfox >/dev/null 2>&1 && eval "$(vfox activate zsh)"
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init --cmd cd zsh)"
command -v mise >/dev/null 2>&1 && eval "$(mise activate zsh)" # 替代 vfox

# Homebrew（Apple Silicon / Intel / Linux 常见路径，未安装则跳过）
[ -f /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv zsh)"
[ -f /usr/local/bin/brew ] && eval "$(/usr/local/bin/brew shellenv zsh)"
[ -f /home/linuxbrew/.linuxbrew/bin/brew ] && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv zsh)"

# Fzf 集成：Ctrl+R 历史、Ctrl+T 文件、Alt+C 目录预览、ssh ** Tab 等
# 已移至 plugins/vi-mode.zsh 的 zvm_after_init 中，因 vi-mode 延迟 init 会覆盖 fzf 的绑定

# Fzf 预览：cd/rm 用 lsd 预览目录（无则 ls），code/vim 等用 bat 预览文件（无则 cat）；仅当 fzf 存在时定义
if command -v fzf &>/dev/null; then
  local -a preview_dir_cmds=(cd rm)
  local -a preview_file_cmds=(code vim nvim vi bat cat nano)
  _fzf_comprun() {
    local command=$1
    shift

    if (($preview_dir_cmds[(Ie)$command])); then
      fzf --preview '(command -v lsd &>/dev/null && lsd --tree --depth 2 --color always --icon always --group-directories-first -a {} || ls -la {}) | head -200' "$@"

    elif (($preview_file_cmds[(Ie)$command])); then
      fzf --preview '(command -v bat &>/dev/null && bat --color=always --style=numbers --line-range=:500 {} || cat {})' "$@"

    else
      fzf "$@"
    fi
  }
fi
