# 开发指南：Zsh & Bun 协作规范

本目录采用 **"Zsh 为壳，Bun 为核"** 的混合架构。Zsh 负责 TTY 交互与 UI 渲染，Bun 负责业务逻辑与数据处理

## 核心分工原则

| 维度 | **Zsh (Glue Layer)** | **Bun (Logic Layer)** |
| :--- | :--- | :--- |
| **擅长场景** | UI 渲染 (fzf)、TTY 交互、环境变更 (cd/export) | 复杂逻辑、API 调用、JSON 解析、类型安全 |
| **性能开销** | 极低 (0ms 启动) | 中等 (20-50ms 启动开销) |
| **交互能力** | **完美** 处理 `stdin/stdout` | **不适合** 在 `fzf` 绑定中处理交互 |
| **文件位置** | `functions/*.zsh` | `functions/bun/src/*.ts` |

❌ **严禁使用 Bun 的场景：**
- **FZF Action 内部**：严禁在 `fzf --bind "ctrl-x:execute(bun ...)"` 中使用 Bun，这会导致 **TTY 争夺** 和 **快捷键失效**（Escape 序列丢失）
- **简单文件操作**：`rm -rf` 或 `mkdir` 这种原生命令更快的场景
- **高频循环**：启动开销会积少成多导致明显的卡顿

## 自定义函数实现模板

### 模式 A：纯逻辑计算（Bun 输出，Zsh 执行）
适用于需要修改当前 Shell 环境（如 `cd`, `export`）或获取复杂数据的场景

**Bun (logic.ts):**
```typescript
// 只负责计算并输出 Shell 语句
console.log(`export PROXY_URL="http://127.0.0.1:7890"`);
```

**Zsh (logic.zsh):**
```bash
my_cmd() {
  # 使用 eval 捕获 Bun 的输出并应用到当前 shell
  eval "$(bun run ~/.zsh/functions/bun/src/logic.ts "$@")"
}
```

### 模式 B：混合 UI 模式 (The Hybrid Pattern)
适用于 `fzf` 驱动的工具。**数据源由 Bun 提供，交互动作由 Zsh 原生执行。**

**Zsh (ui.zsh):**
```bash
dd() {
  # 1. Bun 仅作为数据源（Source）提供流
  bun run ~/.zsh/functions/bun/src/data_provider.ts list | fzf \
    --ansi \
    --header "Action Guide" \
    # 2. 绑定动作必须直接调用原生命令，确保 TTY 响应是瞬时的
    --bind "ctrl-e:execute(id=\$(echo {} | awk '{print \$1}'); docker exec -it \$id bash)+abort"
}
```

## 避坑指南

1. **TTY 稳定性**：如果你发现 `Alt` 快捷键失效，通常是因为 `fzf` 的子进程（Bun）启动太慢，劫持了终端序列。请将 `execute` 里的指令改为原生 Zsh 指令
2. **输出缓冲与数据完整性**：
   - 当 Bun 作为 `fzf` 的数据源时，**务必使用 `process.stdout.write` 替代 `console.log`**
   - `console.log` 会进行额外的格式化检查并自动添加换行符，且具有异步缓冲特性，容易导致 `fzf` 渲染出现行重复或跳行
   - `process.stdout.write` 提供无损、原始的流输出，对 ANSI 颜色序列更友好
3. **显式退出**：在脚本末尾使用 `process.exit(0)`，确保所有异步输出流已被排空（Flush）到管道中
