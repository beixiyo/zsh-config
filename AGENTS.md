# 开发指南：Zsh & Bun 协作规范

本目录采用 **"Zsh 为壳，Bun 为核"**：Zsh 负责 TTY 交互与 UI（fzf），Bun 负责逻辑与数据处理

## 核心分工

| 维度 | **Zsh** | **Bun** |
| :--- | :--- | :--- |
| 场景 | fzf、cd/export、execute 内交互命令 | 列表生成、JSON、复杂逻辑 |
| 位置 | `functions/*.zsh` | `functions/bun/src/*.ts` |

慎用 Bun：简单文件操作（用原生）、execute() 内再起交互式子进程（易 TTY 争用）、高频循环（启动开销）

---

## Bun + fzf 正确用法（避免 TTY/预览坑）

用代码说明：**什么会踩坑、怎么写才对**

### 1. 数据源：用 reload(bun)，不要 bun | fzf

**❌ 错误**：Bun 在管道左侧，与 fzf 争用 TTY → 快捷键失效、终端打出 ^[[B

```bash
# 错误：bun 长期在管道里，占 TTY
bun run git-log.ts "$@" | fzf --bind "ctrl-j:preview-down" ...
```

**✅ 正确**：Bun 只做「输出列表后退出」，放在 **reload** 或 **初始 eval**，不占 TTY

```bash
# 正确：初始列表 + 刷新都用 bun，Bun 输出完即退出
_dir="${${(%):-%x}:A:h}"
gen_list="bun run \"$_dir/bun/src/git-status-list.ts\" 2>/dev/null"
# 管道左侧与 reload 均加 < /dev/null，见下文
gen_list_bind="${gen_list//\"/\\\"} < /dev/null"
eval "$gen_list" < /dev/null | fzf --ansi \
  --bind "ctrl-s:execute(git add -- {3})+reload:${gen_list_bind}" \
  --bind "enter:execute(${EDITOR:-nvim} {3} < /dev/tty)+abort"
```

execute 里仍是 Zsh/原生命令（`git add`、`nvim`），不交给 Bun

### 2. 管道左侧与 reload 必须关闭 stdin（避免概率性 ^[[B）

管道只重定向 **stdout**，左侧进程的 **stdin 仍接在 TTY**。若左侧或 reload 子进程也从 TTY 读，按键会被 fzf 与左侧/reload 争抢，表现为**概率性**：有时正常，有时方向键/快捷键被当成普通字符回显（如 `^[[B`）。与 Bun 冷启动、reload 时机等有关

**处理**：左侧用 `eval "$gen_list" < /dev/null | fzf`；传入 `--bind "reload:..."` 的命令末尾加 ` < /dev/null`（若 gen_list 含双引号，先赋给 `gen_list_bind` 再拼进 bind，避免引号截断）

### 3. 预览随选中行变化：用 `{}`，不要 `{q}`

**❌ 错误**：`{q}` 是搜索框内容，上下移动时不变 → 右侧预览不更新

```bash
--preview "git show \$(echo {q} | grep -o '[a-f0-9]\{7,40\}' | head -1) | delta ..."
```

**✅ 正确**：`{}` 是当前选中行，移动光标会变

```bash
--preview "git show \$(echo {} | grep -o '[a-f0-9]\{7,40\}' | head -1) | delta ..."
```

### 4. Bun 脚本作为 fzf 数据源时的约定

- 用 **`process.stdout.write(line + '\n')`**，不用 `console.log`（避免缓冲/换行导致 fzf 错行）
- 结尾 **`process.exit(0)`**，保证输出刷到管道
- 若脚本内 spawn 子进程且要继承 TTY，用 `shared.ts` 的 `runWithTty`；仅需捕获 stdout 时用 `` $`cmd` `` 或 `Bun.spawn` 且 stdout 为 pipe

---

## shared.ts 使用时机

- **需要**：脚本内执行**依赖 TTY 的子进程**（如 `npm run dev`、`flutter test`）→ 用 `runWithTty(cwd, cmd)`，否则子进程拿不到 TTY
- **不需要**：只捕获子进程 stdout 做解析、或不执行子进程 → 不必引用 shared

---

## 实现模板

**模式 A：Bun 输出 Shell 片段，Zsh eval 执行**（改环境、取数据）

```typescript
// logic.ts
console.log(`export PROXY_URL="http://127.0.0.1:7890"`);
```

```bash
my_cmd() { eval "$(bun run ~/.zsh/functions/bun/src/logic.ts "$@")"; }
```

**模式 B：fzf + Bun 数据源**（列表/刷新用 Bun，execute 用 Zsh）

```bash
# 数据源 / reload 用 bun；按键动作用原生；左侧与 reload 关 stdin 防 TTY 争用
gen_list="bun run \"$_dir/bun/src/list.ts\" 2>/dev/null"
gen_list_bind="${gen_list//\"/\\\"} < /dev/null"
eval "$gen_list" < /dev/null | fzf --bind "ctrl-r:reload:${gen_list_bind}" \
  --bind "enter:execute(nvim {})"
```

---

## 避坑速查

| 现象 | 原因 | 处理 |
|------|------|------|
| Alt/Ctrl 失效、终端出现 ^[[B | Bun 在 `bun \| fzf` 管道左侧占 TTY | 改用 `reload(bun ...)` 或 `eval "$(bun ...)" \| fzf`，execute 用 Zsh |
| **概率性**出现 ^[[B、快捷键时灵时不灵 | 管道左侧或 reload 子进程 stdin 仍接 TTY，与 fzf 争抢按键 | 左侧：`eval "$gen_list" < /dev/null \| fzf`；reload 命令末尾加 ` < /dev/null` |
| 预览不随上下键更新 | 预览用了 `{q}`（搜索框） | 改为 `{}`（当前行） |
| fzf 列表错行/重复 | 用 `console.log` 或未 flush | 用 `process.stdout.write` + `process.exit(0)` |
