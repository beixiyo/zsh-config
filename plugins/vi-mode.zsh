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
