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

export const COLORS = {
  Red: '\x1b[31m',
  Green: '\x1b[32m',
  Yellow: '\x1b[33m',
  Blue: '\x1b[34m',
  Magenta: '\x1b[35m',
  Cyan: '\x1b[36m',
  White: '\x1b[37m',
  Reset: '\x1b[0m',
}

/**
 * Nerd Font 图标映射（Unicode 私用区），来源：ryanoasis/nerd-fonts glyphnames.json
 * @link https://github.com/ryanoasis/nerd-fonts/blob/master/glyphnames.json
 * 用法示例：`${COLORS.Blue}${ICONS.docker}${COLORS.Reset}`
 */
export const ICONS = {
  docker: '\uE7B0',       // dev-docker
  git: '\uE702',          // dev-git
  git_merge: '\uE727',    // dev-git_merge
  git_commit: '\uEafc',   // cod-git_commit
  git_branch: '\uE725',   // dev-git_branch
  folder: '\uEa83',       // cod-folder
  folder_opened: '\uEaf7', // cod-folder_opened
  diff_added: '\uEadc',   // cod-diff_added（绿）
  diff_modified: '\uEade', // cod-diff_modified（黄）
  diff_removed: '\uEadf', // cod-diff_removed（红）
  container: '\uEa7a',    // cod-vm（容器/VM）
  // 文件类型（与 FILE_ICON_BY_EXT 一致，eza-community/eza src/output/icons.rs）
  file_pdf: '\uF1C2',     // DOCUMENT
  file_image: '\uF1C5',   // IMAGE
  file_audio: '\uF001',   // AUDIO
  file_video: '\uF03D',   // VIDEO
  file_js: '\uE74E',      // LANG_JAVASCRIPT
  file_ts: '\uE628',      // LANG_TYPESCRIPT
  file_ts_def: '\uE628',  // .d.ts 同 TS
  file_jsx: '\uE7BA',     // REACT
  file_tsx: '\uE7BA',     // REACT（tsx 与 jsx 同图标）
  file_py: '\uE606',      // LANG_PYTHON
  file_rs: '\uE68B',      // LANG_RUST
  file_java: '\uE256',    // LANG_JAVA
  file_json: '\uE60B',    // JSON
  file_default: '\uF15B', // FILE
} as const

/**
 * @link https://github.com/eza-community/eza/blob/main/src/output/icons.rs
 * 扩展名（小写、无点）→ 图标字符。来源：eza-community/eza icons.rs EXTENSION_ICONS
 * 用法：getFileIcon('pdf') => 图标；对 .d.ts 可用 getFileIcon(name) 先判断 endsWith('.d.ts')
 */
export const FILE_ICON_BY_EXT: Record<string, string> = {
  pdf: ICONS.file_pdf,
  png: ICONS.file_image,
  jpg: ICONS.file_image,
  jpeg: ICONS.file_image,
  gif: ICONS.file_image,
  webp: ICONS.file_image,
  avif: ICONS.file_image,
  ico: ICONS.file_image,
  svg: ICONS.file_image,
  wav: ICONS.file_audio,
  mp3: ICONS.file_audio,
  flac: ICONS.file_audio,
  aac: ICONS.file_audio,
  ogg: ICONS.file_audio,
  m4a: ICONS.file_audio,
  mp4: ICONS.file_video,
  mov: ICONS.file_video,
  avi: ICONS.file_video,
  mkv: ICONS.file_video,
  webm: ICONS.file_video,
  mpeg: ICONS.file_video,
  mpg: ICONS.file_video,
  js: ICONS.file_js,
  mjs: ICONS.file_js,
  cjs: ICONS.file_js,
  ts: ICONS.file_ts,
  mts: ICONS.file_ts,
  cts: ICONS.file_ts,
  jsx: ICONS.file_jsx,
  tsx: ICONS.file_tsx,
  py: ICONS.file_py,
  rs: ICONS.file_rs,
  java: ICONS.file_java,
  json: ICONS.file_json,
  jsonc: ICONS.file_json,
  json5: ICONS.file_json,
}

/**
 * 按文件名取图标：先看是否 .d.ts，再取扩展名映射，否则返回默认文件图标
 */
export function getFileIcon(name: string): string {
  const lower = name.toLowerCase()
  if (lower.endsWith('.d.ts')) return ICONS.file_ts_def
  const ext = lower.includes('.')
    ? lower.slice(lower.lastIndexOf('.') + 1)
    : ''
  return FILE_ICON_BY_EXT[ext] ?? ICONS.file_default
}
