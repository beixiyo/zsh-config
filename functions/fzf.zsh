# Find File / Find String (fzf)
# 公共选项（复用）
## 跨平台复制：macOS pbcopy，WSL clip.exe，Linux xclip/wl-copy
if command -v pbcopy &>/dev/null; then
  _fzf_copy_cmd='pbcopy'
elif command -v clip.exe &>/dev/null; then
  _fzf_copy_cmd='clip.exe'
elif command -v xclip &>/dev/null; then
  _fzf_copy_cmd='xclip -selection clipboard'
elif command -v wl-copy &>/dev/null; then
  _fzf_copy_cmd='wl-copy'
else
  _fzf_copy_cmd='cat'
fi
_fzf_bun_dir="${${(%):-%x}:A:h}/bun/src"

## 文件预览：如果是目录用 lsd，否则用 bat
_ff_preview="if [ -d {} ]; then lsd --tree --depth 3 --color always --icon always --group-directories-first -a {}; else bat --color=always --style=numbers --line-range=:500 {}; fi"
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
_fzf_base_header="CTRL-O: Code | ${_fzf_option}-O: nvim"$'\n'"CTRL-J/K: 切换 | ${_fzf_option}-J/K: 滚动预览"
_fzf_fs_header="${_fzf_base_header}"$'\n'"${_fzf_option}-C: 复制路径:行号 | Ctrl-Alt-C: 绝对路径"
_fzf_ff_header="${_fzf_base_header}"$'\n'"${_fzf_option}-C: 复制路径 | Ctrl-Alt-C: 绝对路径"$'\n'"${_fzf_option}-F/D/A: 文件/目录/全部"

_fzf_bind_file=(
  --bind "${fzfCmdBind}-o:execute(code {})"
  --bind "${fzfOptionBind}-o:execute(nvim {} < /dev/tty)"
)
_fzf_bind_file_line=(
  --bind "${fzfCmdBind}-o:execute(code -g {1}:{2})"
  --bind "${fzfOptionBind}-o:execute(nvim +{2} {1} < /dev/tty)"
  --bind "${fzfOptionBind}-c:execute(echo {1}:{2} | $_fzf_copy_cmd)"
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
    fd . "$dir" "${fd_type[@]}" --color=always --follow --hidden --exclude .git | sort -V
  else
    local find_type=""
    [[ "$type_filter" == "d" ]] && find_type="-type d"
    [[ "$type_filter" == "f" ]] && find_type="-type f"
    find "$dir" $find_type -not -path '*/.git' -not -path '*/.git/*' | sort -V
  fi
}

## Find File Open 选文件后 Alt-O 用 nvim 打开，Ctrl-O 用 VSCode 打开（列表带 Nerd Font 图标，Bun 生成）
ff() {
  local dir="."
  local type_flag="" # 默认全部
  local args=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -d|--dir) type_flag="-d"; shift ;;
      -f|--file) type_flag="-f"; shift ;;
      -a|--all) type_flag="-a"; shift ;;
      --) shift; args+=("$@"); break ;;
      -*) shift ;;
      *) args+=("$1"); shift ;;
    esac
  done
  [[ ${#args[@]} -gt 0 ]] && dir="${args[1]}"

  local _dir="${${(%):-%x}:A:h}"
  local type_arg="a"
  [[ "$type_flag" == "-d" ]] && type_arg="d"
  [[ "$type_flag" == "-f" ]] && type_arg="f"
  local gen_list="bun run \"$_dir/bun/src/ff-list.ts\" --dir \"$dir\" --type $type_arg 2>/dev/null"
  local reload_f="bun run \"$_dir/bun/src/ff-list.ts\" --dir \"$dir\" --type f 2>/dev/null < /dev/null"
  local reload_d="bun run \"$_dir/bun/src/ff-list.ts\" --dir \"$dir\" --type d 2>/dev/null < /dev/null"
  local reload_a="bun run \"$_dir/bun/src/ff-list.ts\" --dir \"$dir\" --type a 2>/dev/null < /dev/null"
  local ff_preview_path="if [ -d {2} ]; then lsd --tree --depth 3 --color always --icon always --group-directories-first -a {2}; else bat --color=always --style=numbers --line-range=:500 {2}; fi"
  local _abs_ff="bun run \"$_fzf_bun_dir/path.ts\" abs {+2} 2>/dev/null | $_fzf_copy_cmd"
  local bind_file_ff=(
    --bind "${fzfCmdBind}-o:execute(code {2})"
    --bind "${fzfOptionBind}-o:execute(nvim {2} < /dev/tty)"
    --bind "${fzfOptionBind}-c:execute(echo {2} | $_fzf_copy_cmd)"
    --bind "ctrl-alt-c:execute($_abs_ff)"
  )
  eval "$gen_list" < /dev/null | fzf \
    --delimiter $'\x01' \
    --with-nth 1,2 \
    --preview "$ff_preview_path" \
    --header "$_fzf_ff_header" \
    --bind "$_fzf_scroll_binds" \
    "${bind_file_ff[@]}" \
    --ansi \
    --bind "${fzfOptionBind}-f:reload($reload_f)" \
    --bind "${fzfOptionBind}-d:reload($reload_d)" \
    --bind "${fzfOptionBind}-a:reload($reload_a)"
}

## Find String Open 搜到内容后 Alt-O 用 nvim 打开并跳到行，Ctrl-O 用 VSCode 打开（列表带文件类型图标，Bun 过滤）
fs() {
  local dir="."
  [[ -d "$1" ]] && dir="$1"
  local _dir="${${(%):-%x}:A:h}"
  local rg_cmd="rg --column --line-number --no-heading --color=never --smart-case"
  local fs_gen="$rg_cmd \"\" \"$dir\" < /dev/null | bun run \"$_dir/bun/src/fs-list.ts\" 2>/dev/null"
  local reload_start="eval \"$rg_cmd \\\"\\\" \\\"$dir\\\" < /dev/null | bun run \\\"$_dir/bun/src/fs-list.ts\\\" 2>/dev/null\""
  local reload_change="$rg_cmd {q} \"$dir\" < /dev/null | bun run \"$_dir/bun/src/fs-list.ts\" 2>/dev/null || true"
  local _fs_preview_icon='p=$(echo {2} | cut -d: -f1); l=$(echo {2} | cut -d: -f2); bat --color=always --style=numbers --theme=base16 --highlight-line "$l" "$p"'
  local _abs_fs="bun run \"$_fzf_bun_dir/path.ts\" abs {+2} 2>/dev/null | $_fzf_copy_cmd"
  local bind_fs_line=(
    --bind "${fzfCmdBind}-o:execute(code -g \"\$(echo {2} | cut -d: -f1):\$(echo {2} | cut -d: -f2)\")"
    --bind "${fzfOptionBind}-o:execute(nvim \"+\$(echo {2} | cut -d: -f2)\" \"\$(echo {2} | cut -d: -f1)\" < /dev/tty)"
    --bind "${fzfOptionBind}-c:execute(echo {2} | cut -d: -f1,2 | $_fzf_copy_cmd)"
    --bind "ctrl-alt-c:execute($_abs_fs)"
  )
  eval "$fs_gen" | fzf --disabled --ansi \
    --delimiter $'\x01' \
    --with-nth 1,2 \
    --preview "$_fs_preview_icon" \
    --preview-window "right:60%:border-left" \
    --bind "start:reload($reload_start)" \
    --bind "change:reload($reload_change)" \
    --header "$_fzf_fs_header" \
    --bind "$_fzf_scroll_binds" \
    "${bind_fs_line[@]}"
}
