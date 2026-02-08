# 环境变量与密钥：在所有 shell 中加载（脚本、cron、GUI 子进程等也能用到 PATH 等）
source ~/.zsh/env.zsh
[[ -f ~/.zsh/secret.zsh ]] && source ~/.zsh/secret.zsh

# 以下仅在交互式 shell 中执行
[[ -o interactive ]] || return

source ~/.zsh/init.zsh
source ~/.zsh/aliases.zsh
source ~/.zsh/functions/index.zsh

source ~/.zsh/history.zsh
source ~/.zsh/completions.zsh
source ~/.zsh/plugins.zsh

# keybindings 必须在 plugins 之后，否则 history-substring-search 的 bindkey 会失效
source ~/.zsh/keybindings.zsh
source ~/.zsh/prompt.zsh
