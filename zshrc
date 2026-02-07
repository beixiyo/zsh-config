# 仅在交互式 shell 中执行
[[ -o interactive ]] || return

# keybindings 必须在 plugins 之后，否则 history-substring-search 的 bindkey 会失效
source ~/.zsh/env.zsh
source ~/.zsh/init.zsh
source ~/.zsh/aliases.zsh
source ~/.zsh/functions.zsh
source ~/.zsh/history.zsh
source ~/.zsh/completions.zsh
source ~/.zsh/plugins.zsh
source ~/.zsh/keybindings.zsh
source ~/.zsh/prompt.zsh
