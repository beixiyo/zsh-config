## 背景

- 现有 `functions/*.zsh` 脚本功能丰富，但 zsh 脚本可读性、可维护性较差
- 目标：让 zsh 只做「胶水层」，主要业务逻辑迁移到 bun + TypeScript
- 同时尽量保持现有命令名与交互体验（如 `gdiff` / `ff` / `dd` 等）不变

## 约定与设计

- 所有 bun 脚本放在 `functions/bun/src/` 下，文件名与原模块名对应，例如：
  - `functions/git.zsh` → `functions/bun/src/git.ts`
  - `functions/proxy.zsh` → `functions/bun/src/proxy.ts`
  - `functions/dev.zsh` → `functions/bun/src/dev.ts`
- 参数解析统一使用 `node:util` 提供的 `parseArgs`，在各自脚本中封装解析逻辑（例如 `proxy.ts` 的 `parseSetArgs`
- 对于需要修改 shell 状态的能力（如 `cd`、`export` 等）：
  - bun 脚本只负责**计算与生成 shell 片段**
  - zsh wrapper 使用 `eval "$(bun ...)"` 执行这些片段，从而在当前 shell 生效
- 对于纯外部副作用（调用 docker、curl、git 等）：
  - 直接在 bun 脚本中通过 `Bun.$` 或 `child_process` 调用外部命令
  - zsh wrapper 统一使用 `bun run <脚本路径> <子命令> ...`，而不是直接执行 ts 文件

## Todo Checklist

- [x] 创建迁移总计划（本文件）
- [x] 为 `proxy.zsh` 编写 bun 版本（支持 setProxy/unsetProxy，输出 shell 片段，并在 zsh 中通过 `bun run` + `eval` 调用）
- [x] 为 `dev.zsh` 编写 bun 版本（d/b/i/t 等，根据项目类型选择包管理器，在 zsh 中通过 `bun run` 调用）
- [x] 为 `file-ops.zsh` 设计 bun 后端（如 `rmr`/`rme` 的确认与删除逻辑）
- [x] 为 `process.zsh` 设计 bun 版本（进程查询与 kill 逻辑，fzf 交互可保留在 zsh）
- [x] 为 `docker.zsh` 和 `docker-dispatch.zsh` 设计 bun 版本（docker API 调用与解析）
- [ ] 为 `git.zsh` 设计 bun 版本（gdiff/glog 的 diff / log 解析与展示逻辑）
- [ ] 为 `fzf.zsh` 设计 bun 版本（文件/内容搜索后端，fzf 层仍在 zsh）
- [ ] 在 `functions/index.zsh` 中逐步接入 bun 版本（保持命令名与现有用法）

