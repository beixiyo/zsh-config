# Find File / Find String (fzf)
# 公共选项（复用）
## 文件预览：如果是目录用 eza，否则用 bat
_ff_preview="if [ -d {} ]; then eza --tree --level=3 --color=always --icons --group-directories-first -a {}; else bat --color=always --style=numbers --line-range=:500 {}; fi"
## 行预览（用于 rg 结果 file:line）
_fs_preview="bat --color=always --style=numbers --theme=base16 --highlight-line {2} {1}"
_fs_opts=(
  --disabled --ansi
  --bind "start:reload:rg --column --line-number --no-heading --color=always --smart-case \"\" < /dev/null"
  --bind "change:reload:rg --column --line-number --no-heading --color=always --smart-case {q} || true < /dev/null"
  --delimiter :
  --preview "$_fs_preview"
  --preview-window "right:60%:border-left"
)

## 打开方式提示与绑定：修饰键来自 env
## header：fzf 不支持 cmd，实际按的是 ctrl，故 Code 用 Ctrl；Option/Alt 仍按平台显示
_fzf_option="${(C)optionKey}"
_fzf_cmd="${fzfCmdBind:-ctrl}"
_fzf_opt="${fzfOptionBind:-alt}"
_fzf_scroll_binds="${_fzf_cmd}-j:down,${_fzf_cmd}-k:up,${_fzf_opt}-j:preview-down+preview-down+preview-down+preview-down+preview-down,${_fzf_opt}-k:preview-up+preview-up+preview-up+preview-up+preview-up"
_fzf_base_header="ENTER: 确认"$'\n'"CTRL-O: Code | ${_fzf_option}-O: nvim"$'\n'"CTRL-J/K: 切换 | ${_fzf_option}-J/K: 滚动预览"
_fzf_fs_header="${_fzf_base_header}"$'\n'"${_fzf_option}-C: 复制路径:行号"
_fzf_ff_header="${_fzf_base_header}"$'\n'"${_fzf_option}-F: 文件 | ${_fzf_option}-D: 目录 | ${_fzf_option}-A: 全部"

_fzf_bind_file=(
  --bind "${fzfCmdBind}-o:execute(code {})"
  --bind "${fzfOptionBind}-o:execute(nvim {} < /dev/tty)"
)
_fzf_bind_file_line=(
  --bind "${fzfCmdBind}-o:execute(code -g {1}:{2})"
  --bind "${fzfOptionBind}-o:execute(nvim +{2} {1} < /dev/tty)"
  --bind "${fzfOptionBind}-c:execute(echo {1}:{2} | pbcopy)"
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
  local type_flag="" # 默认仅展示目录
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

  _fzf_list_files "${list_args[@]}" < /dev/null | fzf \
    --preview "$_ff_preview" \
    --header "$_fzf_ff_header" \
    --bind "$_fzf_scroll_binds" \
    "${_fzf_bind_file[@]}" \
    --ansi \
    --bind "${fzfOptionBind}-f:reload(fd . \"$dir\" --type f --color=always --follow --exclude .git < /dev/null | sort -V || find \"$dir\" -type f -not -path '*/.*' < /dev/null | sort -V)" \
    --bind "${fzfOptionBind}-d:reload(fd . \"$dir\" --type d --color=always --follow --exclude .git < /dev/null | sort -V || find \"$dir\" -type d -not -path '*/.*' < /dev/null | sort -V)" \
    --bind "${fzfOptionBind}-a:reload(fd . \"$dir\" --color=always --follow --exclude .git < /dev/null | sort -V || find \"$dir\" -not -path '*/.*' < /dev/null | sort -V)"
}

## Find String Open 搜到内容后 Alt-O 用 nvim 打开并跳到行，Ctrl-O 用 VSCode 打开
fs() {
  local dir="."
  [[ -d "$1" ]] && dir="$1"

  fzf "${_fs_opts[@]}" \
    --preview-window "right:60%:border-left:+{2}-10" \
    --header "$_fzf_fs_header" \
    --bind "$_fzf_scroll_binds" \
    "${_fzf_bind_file_line[@]}" \
    --bind "start:reload:rg --column --line-number --no-heading --color=always --smart-case \"\" \"$dir\" < /dev/null" \
    --bind "change:reload:rg --column --line-number --no-heading --color=always --smart-case {q} \"$dir\" || true < /dev/null"
}
