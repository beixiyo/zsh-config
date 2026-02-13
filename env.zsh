# WSL 默认浏览器
export BROWSER="'/mnt/c/Program Files/Google/Chrome/Application/chrome.exe'"

# 开源库 bin 目录
PATH="$HOME/.local/bin:$PATH"
# 解决 root 下找不到 code（路径不对时用 which code 查看后替换）
PATH="/mnt/c/Develop/cursor/resources/app/codeBin:$PATH"
export PATH

# 让 fzf 使用 fd 来搜索文件（快、智能、跳过忽略文件）
# --hidden: 搜索隐藏文件
# --follow: 跟随符号链接
# --exclude: 排除特定目录（作为双重保险）
## printf "%s\n" "$FZF_DEFAULT_COMMAND" 查看当前 fzf 的默认命令
## fzf --ansi 使用彩色输出，如果配合 fd --color=always 即可实现
export FZF_DEFAULT_COMMAND='fd --type f --color=always --strip-cwd-prefix --hidden --follow --exclude .git --exclude node_modules'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
# fzf 配色：对齐 Pretty Dark / Tokyo Night（与 Zed 主题一致）
# 可调项: fg/bg=正文/背景, border=边框, header=标题, info=计数, pointer=当前行, marker=多选, fg+/bg+=选中行, hl/hl+=匹配高亮
export FZF_DEFAULT_OPTS="--layout=reverse --border --ansi \
--color='fg:#c2c2c2,bg:#191815,border:#3e4452,header:#d19a66,info:#7a849c,pointer:#e05561' \
--color='marker:#d18f52,fg+:#c2c2c2,bg+:#23262c,hl:#98c379,hl+:#a5e075'"

## Brew
export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.ustc.edu.cn/brew.git"
export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.ustc.edu.cn/homebrew-core.git"
export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles"
export HOMEBREW_API_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles/api"

export EDITOR="code"

## Yazi
export YAZI_CONFIG_HOME="$HOME/.zsh/yazi"