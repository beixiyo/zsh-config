mkcd() { mkdir -p "$@" && cd "$@"; }

# 树形列表（可传递归层级，默认 2）。用法：lt [层级] [路径...]
lt() {
  local level=2
  [[ "$1" == <-> ]] && { level=$1; shift }
  eza -l -a --icons --group-directories-first -h --time-style=long-iso --git --git-ignore \
    --ignore-glob "node_modules|.git|.next|dist|.turbo" --tree --level=$level "$@"
}

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
