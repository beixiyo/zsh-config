# 把当前脚本路径先转成绝对路径，再取它的目录
local _zsh_functions_dir="${${(%):-%x}:A:h}"

# 统一加载所有函数模块（按依赖顺序：dir-file → fzf → process → docker）
source "$_zsh_functions_dir/dir-file.zsh"
source "$_zsh_functions_dir/fzf.zsh"
source "$_zsh_functions_dir/process.zsh"
source "$_zsh_functions_dir/docker.zsh"
