setopt prompt_subst          # 允许 PROMPT 中执行命令替换

# 加载并初始化 Zsh 补全系统：-Uz 按 zsh 语法加载 compinit，-i 忽略不安全目录检查（避免因权限跳过补全）
autoload -Uz compinit && compinit -i
zmodload zsh/complist
compinit

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list \
  'm:{a-zA-Z}={A-Za-z}' \
  'r:|[._-]=* r:|=*'

# 统一 ls / 补全颜色（dircolors 由系统或 ~/.dircolors 提供）
command -v dircolors >/dev/null 2>&1 && eval "$(dircolors -b)"
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
