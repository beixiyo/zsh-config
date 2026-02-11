# Find File / Find String (fzf)
# 公共选项（复用）
## 文件预览：如果是目录用 eza，否则用 bat
_ff_preview="if [ -d {} ]; then eza --tree --level=3 --color=always --icons --group-directories-first -a {}; else bat --color=always --style=numbers --line-range=:500 {}; fi"
## 行预览（用于 rg 结果 file:line）
_fs_preview="bat --color=always --style=numbers --theme=base16 --highlight-line {2} {1}"
_fs_opts=(
  --disabled --ansi
  --bind "start:reload:rg --column --line-number --no-heading --color=always --smart-case \"\""
  --bind "change:reload:rg --column --line-number --no-heading --color=always --smart-case {q} || true"
  --delimiter :
  --preview "$_fs_preview"
  --preview-window "right:60%:border-left"
)

## 打开方式提示与绑定：仅改此处即可统一 nvim/code
## 按系统设置修饰键显示名（Mac=Option，其它=Alt），header 随环境变化
[[ "$(uname -s)" == Darwin ]] && _fzf_mod=Option || _fzf_mod=Alt
_fzf_open_header="ENTER: 输出 | CTRL-O: Code | ${_fzf_mod}-O: nvim | ${_fzf_mod}-F: 文件 | ${_fzf_mod}-D: 目录"
_fzf_bind_file=(
  --bind "ctrl-o:execute(code {})"
  --bind "alt-o:execute(nvim {} < /dev/tty)"
)
_fzf_bind_file_line=(
  --bind "ctrl-o:execute(code -g {1}:{2})"
  --bind "alt-o:execute(nvim +{2} {1} < /dev/tty)"
)

## Helper: List files with optional dir and type filtering
_fzf_list_files() {
  local dir="."
  local type_args=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -d) type_args+=(--type d); shift ;;
      -f) type_args+=(--type f); shift ;;
      -*) echo "Unknown option: $1"; return 1 ;;
      *) dir="$1"; shift ;;
    esac
  done

  if command -v fd > /dev/null; then
    fd . "$dir" "${type_args[@]}" --color=always --follow --exclude .git
  else
    local find_type=""
    [[ "${type_args[*]}" == *"--type d"* ]] && find_type="-type d"
    [[ "${type_args[*]}" == *"--type f"* ]] && find_type="-type f"
    find "$dir" $find_type -not -path '*/.*'
  fi
}

## Find File Open 选文件后 Alt-O 用 nvim 打开，Ctrl-O 用 VSCode 打开
ff() {
  local dir="."
  [[ -d "$1" ]] && dir="$1"

  _fzf_list_files "$@" | fzf \
    --preview "$_ff_preview" \
    --header "$_fzf_open_header" \
    "${_fzf_bind_file[@]}" \
    --ansi \
    --bind "alt-f:reload(fd . \"$dir\" --type f --color=always --follow --exclude .git || find \"$dir\" -type f -not -path '*/.*')" \
    --bind "alt-d:reload(fd . \"$dir\" --type d --color=always --follow --exclude .git || find \"$dir\" -type d -not -path '*/.*')"
}

## Find String Open 搜到内容后 Alt-O 用 nvim 打开并跳到行，Ctrl-O 用 VSCode 打开
fs() {
  local dir="."
  [[ -d "$1" ]] && dir="$1"

  fzf "${_fs_opts[@]}" \
    --preview-window "right:60%:border-left:+{2}-10" \
    --header "$_fzf_open_header in $dir" \
    "${_fzf_bind_file_line[@]}" \
    --bind "start:reload:rg --column --line-number --no-heading --color=always --smart-case \"\" \"$dir\"" \
    --bind "change:reload:rg --column --line-number --no-heading --color=always --smart-case {q} \"$dir\" || true"
}
