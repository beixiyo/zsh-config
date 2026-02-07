ZSH_PLUGIN_DIR="${ZSH_PLUGIN_DIR:-$HOME/.zsh/plugins}"
if [[ ! -d "$ZSH_PLUGIN_DIR/zsh-history-substring-search" ]]; then
  git clone --depth=1 --single-branch --no-tags \
    https://github.com/zsh-users/zsh-history-substring-search \
    "$ZSH_PLUGIN_DIR/zsh-history-substring-search"
fi
source "$ZSH_PLUGIN_DIR/zsh-history-substring-search/zsh-history-substring-search.zsh"
