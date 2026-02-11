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
_fzf_base_header="ENTER: 确认 | CTRL-O: Code | ${_fzf_mod}-O: nvim"
_fzf_ff_header="${_fzf_base_header}"$'\n'"${_fzf_mod}-F: 文件 | ${_fzf_mod}-D: 目录 | ${_fzf_mod}-A: 全部"

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
  local type_filter=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -d|--dir) type_filter="d"; shift ;;
      -f|--file) type_filter="f"; shift ;;
      -a|--all) type_filter=""; shift ;;
      -*) shift ;; # 忽略未知选项
      *) dir="$1"; shift ;;
    esac
  done

  local fd_type=()
  [[ "$type_filter" == "d" ]] && fd_type=(--type d)
  [[ "$type_filter" == "f" ]] && fd_type=(--type f)

  if command -v fd > /dev/null; then
    fd . "$dir" "${fd_type[@]}" --color=always --follow --exclude .git | sort -V
  else
    local find_type=""
    [[ "$type_filter" == "d" ]] && find_type="-type d"
    [[ "$type_filter" == "f" ]] && find_type="-type f"
    find "$dir" $find_type -not -path '*/.*' | sort -V
  fi
}

## Find File Open 选文件后 Alt-O 用 nvim 打开，Ctrl-O 用 VSCode 打开
ff() {
  local dir="."
  local type_flag="-d" # 默认仅展示目录
  local args=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -d|--dir) type_flag="-d"; shift ;;
      -f|--file) type_flag="-f"; shift ;;
      -a|--all) type_flag="-a"; shift ;;
      --) shift; args+=("$@"); break ;;
      -*) shift ;; # 忽略未知参数
      *) args+=("$1"); shift ;;
    esac
  done

  # 如果有位置参数，取第一个作为目录
  [[ ${#args[@]} -gt 0 ]] && dir="${args[1]}"

  local list_args=()
  [[ -n "$type_flag" ]] && list_args+=("$type_flag")
  list_args+=("$dir")

  _fzf_list_files "${list_args[@]}" | fzf \
    --preview "$_ff_preview" \
    --header "$_fzf_ff_header" \
    "${_fzf_bind_file[@]}" \
    --ansi \
    --bind "alt-f:reload(fd . \"$dir\" --type f --color=always --follow --exclude .git | sort -V || find \"$dir\" -type f -not -path '*/.*' | sort -V)" \
    --bind "alt-d:reload(fd . \"$dir\" --type d --color=always --follow --exclude .git | sort -V || find \"$dir\" -type d -not -path '*/.*' | sort -V)" \
    --bind "alt-a:reload(fd . \"$dir\" --color=always --follow --exclude .git | sort -V || find \"$dir\" -not -path '*/.*' | sort -V)"
}

## Find String Open 搜到内容后 Alt-O 用 nvim 打开并跳到行，Ctrl-O 用 VSCode 打开
fs() {
  local dir="."
  [[ -d "$1" ]] && dir="$1"

  fzf "${_fs_opts[@]}" \
    --preview-window "right:60%:border-left:+{2}-10" \
    --header "$_fzf_base_header"$'\n'"搜索目录: $dir" \
    "${_fzf_bind_file_line[@]}" \
    --bind "start:reload:rg --column --line-number --no-heading --color=always --smart-case \"\" \"$dir\"" \
    --bind "change:reload:rg --column --line-number --no-heading --color=always --smart-case {q} \"$dir\" || true"
}
