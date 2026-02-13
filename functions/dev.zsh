#!/usr/bin/env zsh

# 开发 / 构建 / 安装 / 测试：转发到 bun 脚本
#
# 设计与约定：
# - 业务逻辑在 `functions/bun/src/dev.ts`
# - zsh 只做「胶水层」，负责保持 d / b / i / t 这些函数名不变
# - 统一通过 `bun run <ts>` 调用，避免直接执行 ts 文件带来的权限 / shebang 问题
#
# 对比：
# - `proxy.zsh` 需要修改当前 shell（export / unset），所以用：
#     eval "$(bun run "$PROXY_BUN_SCRIPT" set "$@")"
# - 本文件只调用外部命令，不改 shell 状态，所以直接 `bun run` 即可
#
DEV_BUN_SCRIPT="${HOME}/.zsh/functions/bun/src/dev.ts"

d() {
  bun run "$DEV_BUN_SCRIPT" d "$@"
}

b() {
  bun run "$DEV_BUN_SCRIPT" b "$@"
}

i() {
  bun run "$DEV_BUN_SCRIPT" i "$@"
}

t() {
  bun run "$DEV_BUN_SCRIPT" t "$@"
}