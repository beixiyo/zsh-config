#!/usr/bin/env zsh

# 目录 / 文件与批量删除
#
# 设计与约定：
# - 简单 shell 行为（如 mkcd / lt）仍在 zsh 中实现
# - 复杂删除逻辑（rmr / rme）迁移到 Bun + TypeScript
#   - Bun 负责：查找、列表展示、交互确认、执行 rm
#   - zsh 负责：保留函数名与调用习惯

() {
  local dir="${${(%):-%x}:A:h}"
  FILE_OPS_BUN_SCRIPT="$dir/bun/src/file-ops.ts"
}

mkcd() { mkdir -p "$@" && cd "$@"; }

## 树形列表（可传递递归层级，默认 2）。用法：lt [层级] [路径...]
lt() {
  local level=2
  [[ "$1" == <-> ]] && { level=$1; shift }
  lsd -l -a --icon always --group-directories-first -h --git \
    --ignore-glob "node_modules|.git|.next|dist|.turbo" --tree --depth "$level" --total-size "$@"
}

## 在根目录下按文件名模式递归查找并确认后删除。用法：rmr <根目录> <模式1> [模式2] ...
rmr() {
  bun run "$FILE_OPS_BUN_SCRIPT" rmr "$@"
}

## 删除当前目录除指定名称外的所有项。用法：rme <要保留的文件名1> [文件名2] ...
rme() {
  bun run "$FILE_OPS_BUN_SCRIPT" rme "$@"
}

