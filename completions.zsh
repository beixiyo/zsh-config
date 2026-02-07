setopt prompt_subst          # 允许 PROMPT 中执行命令替换

autoload -Uz compinit
zmodload zsh/complist
compinit

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list \
  'm:{a-zA-Z}={A-Za-z}' \
  'r:|[._-]=* r:|=*'

# 统一 ls / 补全颜色（dircolors 由系统或 ~/.dircolors 提供）
command -v dircolors >/dev/null 2>&1 && eval "$(dircolors -b)"
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
