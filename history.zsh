HISTFILE=~/.zsh_history      # 历史文件路径
HISTSIZE=10000               # 内存中保留的历史条数
SAVEHIST=10000               # 写入文件的历史条数

setopt hist_ignore_all_dups  # 删除重复历史
setopt share_history         # 多终端共享历史
setopt inc_append_history    # 每条命令立即写入 HISTFILE
setopt hist_reduce_blanks    # 压缩多余空格
