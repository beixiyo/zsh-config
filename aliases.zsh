# Docker
alias dps='sudo docker ps -a --format "table {{.ID}}\t{{.Image}}\t{{.Ports}}\t{{.Status}}\t{{.Names}}"'
alias dis='sudo docker images'

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
alias ls='eza -a --icons --group-directories-first -h'
# ll 详细（列表+时间+git+目录大小，显示全部）
alias ll='eza -l -a --icons --group-directories-first -h --time-style=long-iso --git --total-size'
# lt 见 functions.zsh：树形列表，可传递归层级

# Tools
alias top='btop'
alias cat='bat'
alias fzf='fzf --ansi'

# Scripts
alias setProxy='source $HOME/bin/setProxy'
alias unsetProxy='source $HOME/bin/unsetProxy'
