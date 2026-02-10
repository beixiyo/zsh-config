# 把当前脚本路径先转成绝对路径，再取它的目录
local _zsh_functions_dir="${${(%):-%x}:A:h}"

source "$_zsh_functions_dir/file-ops.zsh"
source "$_zsh_functions_dir/fzf.zsh"
source "$_zsh_functions_dir/yazi.zsh"
source "$_zsh_functions_dir/process.zsh"
source "$_zsh_functions_dir/docker.zsh"
source "$_zsh_functions_dir/dev.zsh"
source "$_zsh_functions_dir/proxy.zsh"
