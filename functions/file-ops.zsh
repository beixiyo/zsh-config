# 目录 / 文件与批量删除

mkcd() { mkdir -p "$@" && cd "$@"; }

## 树形列表（可传递归层级，默认 2）。用法：lt [层级] [路径...]
lt() {
  local level=2
  [[ "$1" == <-> ]] && { level=$1; shift }
  eza -l -a --icons --group-directories-first -h --time-style=long-iso --git --git-ignore \
    --ignore-glob "node_modules|.git|.next|dist|.turbo" --tree --level=$level "$@"
}

## 在根目录下按文件名模式递归查找并确认后删除。用法：rmr <根目录> <模式1> [模式2] ...
rmr() {
  if (($# < 2)); then
    echo "用法: rmr <根目录> <文件名模式1> [模式2] ..."
    return 1
  fi
  local root=$1
  shift
  if [[ ! -d "$root" ]]; then
    echo "❌ 目录不存在: $root"
    return 1
  fi
  echo "🔍 在 $root 中搜索匹配: $*"
  local targets
  targets=()
  for pattern in "$@"; do
    while IFS= read -r -d '' f; do
      targets+=("$f")
    done < <(find "$root" -name "$pattern" -print0 2>/dev/null)
  done
  if (($#targets == 0)); then
    echo "🗂️  未找到匹配的文件"
    return 0
  fi
  echo "🗑️  将删除以下文件 (共 $#targets 个):"
  printf '   %s\n' "${targets[@]}"
  echo
  read "reply?⚠️  确认删除? [y/N] "
  if [[ ! "$reply" =~ ^[Yy]$ ]]; then
    echo "❌ 操作已取消"
    return 0
  fi
  echo "🚀 开始删除..."
  for f in "${targets[@]}"; do
    echo "   删除: $f"
    rm -rf "$f"
  done
  echo "🎉 删除完成！"
}

## 删除当前目录除指定名称外的所有项。用法：rme <要保留的文件名1> [文件名2] ...
rme() {
  if (($# == 0)); then
    echo "用法: rme <要保留的文件名1> [文件名2] ..."
    echo "示例: rme .git README.md package.json"
    return 1
  fi
  echo "🔍 将删除当前目录除以下文件外的所有内容:"
  for name in "$@"; do
    echo "   ✓ $name"
  done
  echo
  read "reply?⚠️  确认删除? [y/N] "
  if [[ ! "$reply" =~ ^[Yy]$ ]]; then
    echo "❌ 操作已取消"
    return 0
  fi
  local args=(-mindepth 1 -maxdepth 1)
  for name in "$@"; do
    args+=('!' -name "$name")
  done
  find . "${args[@]}" -exec rm -rf {} +
  echo "🎉 删除完成！"
}
