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
  Black: '\x1b[30m',
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
 * Nerd Font 图标映射（Unicode 私用区）。
 *
 * 源头：Cheat Sheet 与 glyphnames.json 一致，均为官方数据。
 * - 网页查图标：https://www.nerdfonts.com/cheat-sheet（可搜索 glyph 名）
 * - 程序用映射：https://github.com/ryanoasis/nerd-fonts/blob/master/glyphnames.json
 *   格式 {"glyph-name": {"char":"…", "code":"xxxx"}}，code 为 4 位十六进制（BMP），
 *   辅助平面图标为 UTF-16  surrogate pair，对应 \uDxxx\uDxxx。
 * - eza 参考：https://github.com/eza-community/eza/blob/main/src/output/icons.rs
 *
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
  // 文件类型（与 FILE_RULES_BY_EXT 一致，用户指定 glyph）
  file_pdf: '\uf1c1',     // DOCUMENT
  file_word: '\uf1c2',    // fa-file-word-o
  file_excel: '\uf1c3',   // fa-file-excel-o
  file_pptx: '\uf1c4',    // fa-file-powerpoint-o
  file_image: '\uF4E5',   // 图片 jpg|jpeg|png...
  file_audio: '\uDB80\uDF87', // 音频 mp3|flac|wav...
  file_video: '\uE69F',   // 视频 mp4...
  file_js: '\uDB80\uDF99',   // js
  file_ts: '\uE69D',      // ts
  file_ts_def: '\uE69D',  // .d.ts 同 TS
  file_jsx: '\uE7BA',     // jsx 黄
  file_tsx: '\uE7BA',     // tsx 蓝（同图标不同色）
  file_svg: '\uDB81\uDF21',   // svg
  file_py: '\uE73C',      // py
  file_rs: '\uE7A8',      // rs
  file_java: '\uE256',    // LANG_JAVA
  file_json: '\uE60B',    // JSON
  file_md: '\uEB1D',      // cod-markdown
  file_shell: '\uE691',   // sh|bash|fish|zsh...
  file_yml: '\uEB51',     // cod-settings_gear（yaml/yml 配置）
  file_html: '\uE736',    // dev-html5
  file_css: '\uE749',     // dev-css3
  file_toml: '\uE6B2',    // toml
  file_xml: '\uEAE9',     // cod-file_code
  file_sql: '\uEACE',     // cod-database
  file_lua: '\uE620',     // dev-lua
  file_lock: '\uEA75',    // cod-lock（通用 lock）
  file_lock_bun: '\uE76F',    // bun.lock
  file_lock_pnpm: '\uE865',   // pnpm-lock
  file_package: '\uEB29',  // cod-package（package.json 等）
  file_npmrc: '\uE71E',   // .npmrc
  file_docker: '\uE7B0',  // dev-docker（Dockerfile）
  file_make: '\uEB6D',    // cod-tools（Makefile 等）
  file_go: '\uE627',      // go 蓝
  file_ruby: '\uE605',    // custom-ruby
  file_dart: '\uE798',    // dev-dart
  file_php: '\uE73D',     // dev-php
  file_c: '\uE61E',       // c
  file_cpp: '\uE61D',     // c++|cpp
  file_csharp: '\uE7B2',  // csharp
  file_env: '\uE615',     // .env(.*)
  file_github: '\uE709',  // .github 黑
  file_tailwind: '\uDB84\uDFFF', // 来自 cheat-sheet（tailwind，辅助平面）
  file_vite: '\uE8D7',    // 来自 cheat-sheet（vite）
  file_vitest: '\uE8D9',  // 来自 cheat-sheet（vitest）
  file_default: '\uF15B', // FILE
} as const

/**
 * 扩展名（小写、无点）→ 图标 + 颜色，按组定义减少重复。顺序即优先级。
 * 用法：getFileIcon / getFileIconColored 会遍历找到 exts 包含该后缀的项。
 */
export const FILE_RULES_BY_EXT: ReadonlyArray<{
  exts: readonly string[]
  icon: string
  color: string
}> = [
  { exts: ['md', 'markdown', 'mdx'], icon: ICONS.file_md, color: COLORS.Blue },
  { exts: ['pdf'], icon: ICONS.file_pdf, color: COLORS.Red },
  { exts: ['doc', 'docx'], icon: ICONS.file_word, color: COLORS.Blue },
  { exts: ['xls', 'xlsx'], icon: ICONS.file_excel, color: COLORS.Green },
  { exts: ['ppt', 'pptx'], icon: ICONS.file_pptx, color: COLORS.Red },
  { exts: ['png', 'jpg', 'jpeg', 'gif', 'webp', 'avif', 'ico'], icon: ICONS.file_image, color: COLORS.Magenta },
  { exts: ['svg'], icon: ICONS.file_svg, color: COLORS.Magenta },
  { exts: ['wav', 'mp3', 'flac', 'aac', 'ogg', 'm4a'], icon: ICONS.file_audio, color: COLORS.Cyan },
  { exts: ['mp4', 'mov', 'avi', 'mkv', 'webm', 'mpeg', 'mpg'], icon: ICONS.file_video, color: COLORS.Magenta },
  { exts: ['js', 'mjs', 'cjs'], icon: ICONS.file_js, color: COLORS.Yellow },
  { exts: ['ts', 'mts', 'cts'], icon: ICONS.file_ts, color: COLORS.Blue },
  { exts: ['jsx'], icon: ICONS.file_jsx, color: COLORS.Yellow },
  { exts: ['tsx'], icon: ICONS.file_tsx, color: COLORS.Blue },
  { exts: ['py'], icon: ICONS.file_py, color: COLORS.Green },
  { exts: ['rs'], icon: ICONS.file_rs, color: COLORS.White },
  { exts: ['c', 'h'], icon: ICONS.file_c, color: COLORS.White },
  { exts: ['cpp', 'cc', 'cxx', 'hpp', 'hxx'], icon: ICONS.file_cpp, color: COLORS.White },
  { exts: ['cs'], icon: ICONS.file_csharp, color: COLORS.Magenta },
  { exts: ['go'], icon: ICONS.file_go, color: COLORS.Blue },
  { exts: ['java'], icon: ICONS.file_java, color: COLORS.Red },
  { exts: ['json', 'jsonc', 'json5'], icon: ICONS.file_json, color: COLORS.Yellow },
  { exts: ['sh', 'bash', 'zsh', 'fish', 'ksh', 'csh'], icon: ICONS.file_shell, color: COLORS.Green },
  { exts: ['yml', 'yaml', 'env'], icon: ICONS.file_yml, color: COLORS.Magenta },
  { exts: ['html'], icon: ICONS.file_html, color: COLORS.Red },
  { exts: ['htm'], icon: ICONS.file_html, color: COLORS.Magenta },
  { exts: ['css', 'less'], icon: ICONS.file_css, color: COLORS.Blue },
  { exts: ['scss', 'sass'], icon: ICONS.file_css, color: COLORS.Magenta },
  { exts: ['toml'], icon: ICONS.file_toml, color: COLORS.White },
  { exts: ['xml'], icon: ICONS.file_xml, color: COLORS.Yellow },
  { exts: ['sql'], icon: ICONS.file_sql, color: COLORS.Cyan },
  { exts: ['lock'], icon: ICONS.file_lock, color: COLORS.Yellow },
  { exts: ['lua'], icon: ICONS.file_lua, color: COLORS.Blue },
]

/**
 * 按 basename 正则匹配的知名文件 → 图标 + 颜色。顺序即优先级（更具体的放前）。
 * 用正则可一条覆盖多种变体，如 vite.config.(js|ts|mjs) 、.*config.(c|m)?(j|t)s。
 */
export const FILE_MATCH_BY_PATTERN: ReadonlyArray<{
  pattern: RegExp
  icon: string
  color: string
}> = [
  // 精确/关键文件
  { pattern: /^package\.json$/, icon: ICONS.file_package, color: COLORS.Yellow },
  { pattern: /^package-lock\.json$/, icon: ICONS.file_lock, color: COLORS.White },
  { pattern: /^yarn\.lock$/, icon: ICONS.file_lock, color: COLORS.Cyan },
  { pattern: /^bun\.lock$/, icon: ICONS.file_lock_bun, color: COLORS.White },
  { pattern: /^pnpm-lock\.yaml$/, icon: ICONS.file_lock_pnpm, color: COLORS.Yellow },
  { pattern: /^(cargo|gemfile|poetry)\.lock$/, icon: ICONS.file_lock, color: COLORS.White },
  { pattern: /^\.(bashrc|bash_profile|bash_logout|zshrc|zprofile|zshenv|zlogin)$/, icon: ICONS.file_shell, color: COLORS.Green },
  { pattern: /^dockerfile$/, icon: ICONS.file_docker, color: COLORS.Blue },
  { pattern: /^makefile$/, icon: ICONS.file_make, color: COLORS.White },
  { pattern: /^\.git(ignore|attributes)$/, icon: ICONS.git, color: COLORS.Red },
  { pattern: /^\.?github$/, icon: ICONS.file_github, color: COLORS.Black },
  { pattern: /^\.env(\.(local|development|production|test))?$/, icon: ICONS.file_env, color: COLORS.Magenta },
  // TS/JS 配置：vite / tailwind / next / nuxt / vitest / jest 等用正则一次覆盖 (c|m)?(j|t)s
  { pattern: /^vite\.config\.(c|m)?(j|t)s$/, icon: ICONS.file_vite, color: COLORS.Cyan },
  { pattern: /^tailwind\.config\.(c|m)?(j|t)s$/, icon: ICONS.file_tailwind, color: COLORS.Cyan },
  { pattern: /^vitest\.config\.(c|m)?(j|t)s$/, icon: ICONS.file_vitest, color: COLORS.Cyan },
  { pattern: /^next\.config\.(c|m)?(j|t)s$/, icon: ICONS.file_js, color: COLORS.Yellow },
  { pattern: /^nuxt\.config\.(c|m)?(j|t)s$/, icon: ICONS.file_js, color: COLORS.Green },
  { pattern: /^jest\.config\.(c|m)?(j|t)s$/, icon: ICONS.file_js, color: COLORS.Yellow },
  { pattern: /^webpack\.config\.(c|m)?(j|t)s$/, icon: ICONS.file_ts, color: COLORS.Cyan },
  { pattern: /^rollup\.config\.(c|m)?(j|t)s$/, icon: ICONS.file_js, color: COLORS.Yellow },
  { pattern: /^babel\.config\.js$/, icon: ICONS.file_js, color: COLORS.Yellow },
  // 其它知名文件（.json 除下列外统一走扩展名 → file_json）
  { pattern: /^cargo\.toml$/, icon: ICONS.file_rs, color: COLORS.White },
  { pattern: /^go\.(mod|sum)$/, icon: ICONS.file_go, color: COLORS.Cyan },
  { pattern: /^gemfile\.lock$/, icon: ICONS.file_lock, color: COLORS.White },
  { pattern: /^gemfile$/, icon: ICONS.file_ruby, color: COLORS.Red },
  { pattern: /^pubspec\.yaml$/, icon: ICONS.file_dart, color: COLORS.Blue },
  { pattern: /^composer\.json$/, icon: ICONS.file_php, color: COLORS.Magenta },
  { pattern: /^pyproject\.toml$/, icon: ICONS.file_py, color: COLORS.Green },
  { pattern: /^requirements\.txt$/, icon: ICONS.file_py, color: COLORS.Green },
  { pattern: /^docker-compose\.(yml|yaml)$/, icon: ICONS.file_docker, color: COLORS.Blue },
  { pattern: /^\.(eslintrc|prettierrc)(\.(js|json))?$/, icon: ICONS.file_js, color: COLORS.Yellow },
  { pattern: /^\.(editorconfig|tool-versions)$/, icon: ICONS.file_yml, color: COLORS.Magenta },
  { pattern: /^\.(nvmrc|node-version)$/, icon: ICONS.file_js, color: COLORS.Green },
  { pattern: /^\.(npmrc|yarnrc)(\.yml)?$/, icon: ICONS.file_npmrc, color: COLORS.Red },
  { pattern: /^\.dockerignore$/, icon: ICONS.file_docker, color: COLORS.Blue },
  { pattern: /^\.cursorignore$/, icon: ICONS.file_default, color: COLORS.White },
  { pattern: /^\.ruby-version$/, icon: ICONS.file_ruby, color: COLORS.Red },
  { pattern: /^\.python-version$/, icon: ICONS.file_py, color: COLORS.Green },
  { pattern: /^procfile$/, icon: ICONS.file_shell, color: COLORS.Green },
  { pattern: /^rakefile$/, icon: ICONS.file_ruby, color: COLORS.Red },
  { pattern: /^(justfile|cmakelists\.txt)$/, icon: ICONS.file_make, color: COLORS.White },
]

function matchFileByExt(ext: string): { icon: string; color: string } | null {
  for (const rule of FILE_RULES_BY_EXT) {
    if (rule.exts.includes(ext)) return { icon: rule.icon, color: rule.color }
  }
  return null
}

/** 取路径最后一段，先去掉尾随 / 再切（避免 fd 输出 ./.github/ 得到空串） */
function basename(path: string): string {
  const trimmed = path.replace(/\/+$/, '')
  const i = trimmed.lastIndexOf('/')
  return i >= 0 ? trimmed.slice(i + 1) : trimmed
}

function matchFileByPattern(base: string): { icon: string; color: string } | null {
  for (const { pattern, icon, color } of FILE_MATCH_BY_PATTERN) {
    if (pattern.test(base)) return { icon, color }
  }
  return null
}

/**
 * 按文件名取图标：先正则匹配知名文件，再 .d.ts，再扩展名，否则默认
 */
export function getFileIcon(name: string): string {
  const lower = name.toLowerCase()
  const base = basename(lower)
  const match = matchFileByPattern(base)
  if (match) return match.icon
  if (lower.endsWith('.d.ts')) return ICONS.file_ts_def
  const ext = lower.includes('.') ? lower.slice(lower.lastIndexOf('.') + 1) : ''
  return matchFileByExt(ext)?.icon ?? ICONS.file_default
}

/** 目录图标颜色 */
export const DIR_ICON_COLOR = COLORS.Blue

/**
 * 带颜色的图标，用于 ff-list：目录先按正则匹配（如 .github）再默认蓝文件夹；文件先按正则再按扩展名
 */
export function getFileIconColored(name: string, isDir: boolean): string {
  const lower = name.toLowerCase()
  const base = basename(lower)
  const match = matchFileByPattern(base)

  if (isDir) {
    const icon = match ? match.icon : ICONS.folder
    const color = match ? match.color : DIR_ICON_COLOR
    return `${color}${icon}${COLORS.Reset}`
  }

  const icon = match ? match.icon : getFileIcon(name)
  const ext = lower.includes('.') ? lower.slice(lower.lastIndexOf('.') + 1) : ''
  const color = match ? match.color : (matchFileByExt(ext)?.color ?? COLORS.White)
  return `${color}${icon}${COLORS.Reset}`
}
