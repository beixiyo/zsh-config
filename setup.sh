#!/usr/bin/env bash
# ============================================================
# Zsh 模块化配置安装脚本
# ============================================================

set -e

CONFIG_DIR="${HOME}/.zsh"
BACKUP_SUFFIX=".bak.$(date +%Y-%m-%d_%H)"

# ----------------------------------------
# 1. 创建目录并备份现有配置
# ----------------------------------------
mkdir -p "$CONFIG_DIR"
if [[ -f ~/.zshrc ]]; then
  mv ~/.zshrc ~/.zshrc${BACKUP_SUFFIX}
  echo "[OK] 已备份 ~/.zshrc -> ~/.zshrc${BACKUP_SUFFIX}"
fi

# ----------------------------------------
# 2. 主入口 zshrc（按加载顺序 source 各模块）
# ----------------------------------------
cat > "$CONFIG_DIR/zshrc" << 'EOF'
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
EOF

# ----------------------------------------
# 3. init.zsh：终端标题、Starship/Vfox/Zoxide/Fzf 初始化
# ----------------------------------------
cat > "$CONFIG_DIR/init.zsh" << 'EOF'
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
EOF

# ----------------------------------------
# 4. env.zsh：PATH、浏览器、Fzf 默认命令与主题
# ----------------------------------------
cat > "$CONFIG_DIR/env.zsh" << 'EOF'
# WSL 默认浏览器
export BROWSER="'/mnt/c/Program Files/Google/Chrome/Application/chrome.exe'"

# 开源库 bin 目录
PATH="$HOME/.local/bin:$PATH"
# 个人 bin 目录
PATH="$HOME/bin:$PATH"
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
export FZF_DEFAULT_OPTS="--layout=reverse --border --ansi \
--color='fg:#ebdbb2,bg:#282828,header:#fabd2f,info:#83a598,pointer:#fb4934' \
--color='marker:#fe8019,fg+:#ebdbb2,bg+:#3c3836,hl:#8ec07c,hl+:#b8bb26'"
EOF

# ----------------------------------------
# 5. aliases.zsh
# ----------------------------------------
cat > "$CONFIG_DIR/aliases.zsh" << 'EOF'
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
# ll 详细（列表+时间+git+忽略常见目录）
alias ll='eza -l -a --icons --group-directories-first -h --time-style=long-iso --git --git-ignore --ignore-glob "node_modules|.git|.next|dist|.turbo"'
alias lt='eza -l -a --icons --group-directories-first -h --time-style=long-iso --git --git-ignore --ignore-glob "node_modules|.git|.next|dist|.turbo" --tree --level=2'

# Tools
alias top='btop'
alias cat='bat'
alias fzf='fzf --ansi'

# Scripts
alias setProxy='source $HOME/bin/setProxy'
alias unsetProxy='source $HOME/bin/unsetProxy'
EOF

# ----------------------------------------
# 5.1 functions.zsh：shell 函数
# ----------------------------------------
cat > "$CONFIG_DIR/functions.zsh" << 'EOF'
mkcd() { mkdir -p "$@" && cd "$@"; }

# ---- fzf 公共选项（复用） ----
# 文件预览：bat
_ff_preview="bat --color=always --style=numbers --line-range=:500 {}"
# 行预览（用于 rg 结果 file:line）
_fs_preview="bat --color=always --style=numbers --theme=base16 --highlight-line {2} {1}"
_fs_opts=(
  --disabled --ansi
  --bind "start:reload:rg --column --line-number --no-heading --color=always --smart-case \"\""
  --bind "change:reload:rg --column --line-number --no-heading --color=always --smart-case {q} || true"
  --delimiter :
  --preview "$_fs_preview"
  --preview-window "right:60%:border-left"
)

# 打开方式提示与绑定：仅改此处即可统一 nvim/code
_fzf_open_header="ENTER: nvim | CTRL-O: VSCode"
_fzf_bind_file=( --bind "enter:execute(nvim {} < /dev/tty)" --bind "ctrl-o:execute(code {})" )
_fzf_bind_file_line=( --bind "enter:execute(nvim +{2} {1} < /dev/tty)" --bind "ctrl-o:execute(code -g {1}:{2})" )

## Find File 在当前目录下所有文件里预览，并在右侧用 bat 实时预览
ff() { fzf --preview "$_ff_preview"; }

## Find String 在当前目录下所有文件里搜内容，并在右侧用 bat 实时预览
fs() { fzf "${_fs_opts[@]}" --header "Search Content"; }

## Find File Open 选文件后 ENTER 用 nvim 打开，Ctrl-O 用 VSCode 打开
ffo() {
  fzf --preview "$_ff_preview" --header "$_fzf_open_header" "${_fzf_bind_file[@]}"
}

## Find String Open 搜到内容后 ENTER 用 nvim 打开并跳到行，Ctrl-O 用 VSCode 打开
fso() {
  fzf "${_fs_opts[@]}" \
    --preview-window "right:60%:border-left:+{2}-10" \
    --header "$_fzf_open_header" \
    "${_fzf_bind_file_line[@]}"
}

## Find Process 杀死进程
fp() {
  ps -ef | fzf --header "Kill Process" --reverse | awk '{print $2}' | xargs -r kill -9
}
EOF


# ----------------------------------------
# 6. history.zsh：历史记录与共享
# ----------------------------------------
cat > "$CONFIG_DIR/history.zsh" << 'EOF'
HISTFILE=~/.zsh_history      # 历史文件路径
HISTSIZE=10000               # 内存中保留的历史条数
SAVEHIST=10000               # 写入文件的历史条数

setopt hist_ignore_all_dups  # 删除重复历史
setopt share_history         # 多终端共享历史
setopt inc_append_history    # 每条命令立即写入 HISTFILE
setopt hist_reduce_blanks    # 压缩多余空格
EOF

# ----------------------------------------
# 7. keybindings.zsh：history-substring-search 上下键
# ----------------------------------------
cat > "$CONFIG_DIR/keybindings.zsh" << 'EOF'
# 依赖 plugins.zsh 中的 zsh-history-substring-search
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
EOF

# ----------------------------------------
# 8. completions.zsh：补全与 ls 颜色
# ----------------------------------------
cat > "$CONFIG_DIR/completions.zsh" << 'EOF'
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
EOF

# ----------------------------------------
# 9. plugins：按插件分文件，再统一加载
# ----------------------------------------
mkdir -p "$CONFIG_DIR/plugins"

# 9.1 历史灰字提示
cat > "$CONFIG_DIR/plugins/autosuggestions.zsh" << 'EOF'
ZSH_PLUGIN_DIR="${ZSH_PLUGIN_DIR:-$HOME/.zsh/plugins}"
if [[ ! -d "$ZSH_PLUGIN_DIR/zsh-autosuggestions" ]]; then
  git clone --depth=1 --single-branch --no-tags \
    https://github.com/zsh-users/zsh-autosuggestions \
    "$ZSH_PLUGIN_DIR/zsh-autosuggestions"
fi
source "$ZSH_PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh"
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
EOF

# 9.2 上下键历史子串搜索
cat > "$CONFIG_DIR/plugins/history-substring-search.zsh" << 'EOF'
ZSH_PLUGIN_DIR="${ZSH_PLUGIN_DIR:-$HOME/.zsh/plugins}"
if [[ ! -d "$ZSH_PLUGIN_DIR/zsh-history-substring-search" ]]; then
  git clone --depth=1 --single-branch --no-tags \
    https://github.com/zsh-users/zsh-history-substring-search \
    "$ZSH_PLUGIN_DIR/zsh-history-substring-search"
fi
source "$ZSH_PLUGIN_DIR/zsh-history-substring-search/zsh-history-substring-search.zsh"
EOF

# 9.3 Vi 模式（先设变量再 source）
cat > "$CONFIG_DIR/plugins/vi-mode.zsh" << 'EOF'
ZSH_PLUGIN_DIR="${ZSH_PLUGIN_DIR:-$HOME/.zsh/plugins}"
ZVM_VI_INSERT_ESCAPE_BINDKEY=jk
ZVM_KEYTIMEOUT=0.2
ZVM_MODE_INDICATOR_NORMAL='[N]'
ZVM_MODE_INDICATOR_INSERT='[I]'
ZVM_MODE_INDICATOR_VISUAL='[V]'
ZVM_MODE_INDICATOR_REPLACE='[R]'
ZVM_SHOW_MODE_IN_PROMPT=true
if [[ ! -d "$ZSH_PLUGIN_DIR/zsh-vi-mode" ]]; then
  git clone --depth=1 --single-branch --no-tags \
    https://github.com/jeffreytse/zsh-vi-mode \
    "$ZSH_PLUGIN_DIR/zsh-vi-mode"
fi
source "$ZSH_PLUGIN_DIR/zsh-vi-mode/zsh-vi-mode.plugin.zsh"
EOF

# 9.4 语法高亮（必须最后加载）
cat > "$CONFIG_DIR/plugins/syntax-highlighting.zsh" << 'EOF'
ZSH_PLUGIN_DIR="${ZSH_PLUGIN_DIR:-$HOME/.zsh/plugins}"
if [[ ! -d "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting" ]]; then
  git clone --depth=1 --single-branch --no-tags \
    https://github.com/zsh-users/zsh-syntax-highlighting \
    "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting"
fi
source "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
ZSH_HIGHLIGHT_STYLES[command]='fg=green'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=red,bold'
EOF

# 9.5 主入口：创建插件目录并按顺序加载各插件
cat > "$CONFIG_DIR/plugins.zsh" << 'EOF'
ZSH_PLUGIN_DIR="${ZSH_PLUGIN_DIR:-$HOME/.zsh/plugins}"
mkdir -p "$ZSH_PLUGIN_DIR"

# 按加载顺序 source（仓库在 ZSH_PLUGIN_DIR=~/.zsh/plugins，配置在 ~/.zsh/plugins/*.zsh）
source ~/.zsh/plugins/autosuggestions.zsh
source ~/.zsh/plugins/history-substring-search.zsh
source ~/.zsh/plugins/vi-mode.zsh
source ~/.zsh/plugins/syntax-highlighting.zsh
EOF

# ----------------------------------------
# 10. prompt.zsh：Prompt 由 Starship 接管，此处仅保留占位
# ----------------------------------------
cat > "$CONFIG_DIR/prompt.zsh" << 'EOF'
# Prompt 已由 init.zsh 中 starship init zsh 接管，无需额外配置
EOF

# ----------------------------------------
# 11. 将 ~/.zshrc 指向新配置
# ----------------------------------------
printf '%s\n' 'source ~/.zsh/zshrc' > ~/.zshrc
echo "[OK] 已写入 ~/.zshrc -> source ~/.zsh/zshrc"
echo "[OK] 模块化配置完成。重新打开终端或执行: exec zsh"