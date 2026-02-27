# Docker
alias dps='sudo docker ps -a --format "table {{.ID}}\t{{.Image}}\t{{.Ports}}\t{{.Status}}\t{{.Names}}"'
alias dis='sudo docker images'
# 见 functions.zsh：dd 统一 Docker 操作面板

# nvim
alias vi='nvim'
alias vim='nvim'

# WSL 调用宿主机 PowerShell
alias p='pwsh.exe -Command'

# command
alias sys='sudo systemctl'

# Dir
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias mkdir="mkdir -p"

alias rm='safe-rm'
# ls 精简（多列、图标、目录优先）
alias ls='lsd -a --icon always --group-directories-first -h'
# ll 详细（列表+git+目录大小，显示全部）
alias ll='lsd -l -a --icon always --group-directories-first -h --total-size --git'
# lt 见 functions.zsh：树形列表，可传递归层级

# Tools
alias top='btop'
alias cat='bat'
alias fzf='fzf --ansi'
alias jq='jq -C'   # 终端下彩色输出
