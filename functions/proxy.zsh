#!/usr/bin/env zsh

# HTTP/HTTPS 与 git 代理开关（bun 版本封装）
#
# 设计依据：
# - `plan/bun-migration.md`
# - `functions/bun/src/proxy.ts`
#   bun 脚本负责：
#     - 解析参数（端口 / URL / no-proxy 列表）
#     - 生成 export / unset / git config 等 shell 片段
#   本 zsh 脚本只负责：
#     - 保留原有函数名：setProxy / unsetProxy
#     - 调用 bun 脚本，并在当前 shell 中 eval 其输出

() {
  local dir="${${(%):-%x}:A:h}"
  PROXY_BUN_SCRIPT="$dir/bun/src/proxy.ts"
}

setProxy() {
  eval "$(bun run "$PROXY_BUN_SCRIPT" set "$@")"
}

unsetProxy() {
  eval "$(bun run "$PROXY_BUN_SCRIPT" unset "$@")"
}