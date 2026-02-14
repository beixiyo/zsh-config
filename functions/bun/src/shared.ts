/**
 * 在指定目录下以继承 TTY 的方式执行命令。
 * 子进程的 stdin/stdout/stderr 直接继承当前进程，保证 process.stdout.isTTY 为 true，
 * 供 Nx、交互式 dev server、watch 模式测试等 CLI 正常使用。
 *
 * @param cwd 工作目录
 * @param cmd 命令与参数，如 ['pnpm', 'build'] 或 ['npm', 'run', 'dev']
 * @param options.env 可选，与 process.env 合并后传给子进程
 * @returns 子进程退出码
 */
export async function runWithTty(
  cwd: string,
  cmd: string[],
  options?: { env?: Record<string, string | undefined> },
): Promise<number> {
  const [exe, ...args] = cmd
  const proc = Bun.spawn([exe, ...args], {
    cwd,
    stdio: ['inherit', 'inherit', 'inherit'],
    env: options?.env ? { ...process.env, ...options.env } : undefined,
  })
  return await proc.exited
}
