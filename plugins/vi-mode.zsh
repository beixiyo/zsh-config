ZSH_PLUGIN_DIR="${ZSH_PLUGIN_DIR:-$HOME/.zsh/plugins}"
ZVM_VI_INSERT_ESCAPE_BINDKEY=jk
ZVM_KEYTIMEOUT=0.2

# fzf 必须在 vi-mode 完全初始化后再加载，否则 vi-mode 的延迟 init 会覆盖 Ctrl+R 等绑定
# 详见 https://github.com/jeffreytse/zsh-vi-mode/wiki/Integration#fzf
function zvm_after_init() {
  command -v fzf &>/dev/null && source <(fzf --zsh)
}

ZVM_MODE_INDICATOR_NORMAL='[N]'
ZVM_MODE_INDICATOR_INSERT='[I]'
ZVM_MODE_INDICATOR_VISUAL='[V]'
ZVM_MODE_INDICATOR_REPLACE='[R]'
ZVM_SHOW_MODE_IN_PROMPT=true

# 不完整 clone（无主文件）时删掉重试一次，避免 "no such file or directory"
if [[ ! -f "$ZSH_PLUGIN_DIR/zsh-vi-mode/zsh-vi-mode.plugin.zsh" ]]; then
  rm -rf "$ZSH_PLUGIN_DIR/zsh-vi-mode"
  git clone --depth=1 --single-branch --no-tags \
    https://github.com/jeffreytse/zsh-vi-mode \
    "$ZSH_PLUGIN_DIR/zsh-vi-mode"
fi
if [[ -f "$ZSH_PLUGIN_DIR/zsh-vi-mode/zsh-vi-mode.plugin.zsh" ]]; then
  source "$ZSH_PLUGIN_DIR/zsh-vi-mode/zsh-vi-mode.plugin.zsh"
fi
