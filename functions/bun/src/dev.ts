#!/usr/bin/env bun

/**
 * Dev helper for zsh: d / b / i / t
 *
 * 设计用法（在 zsh 中）：
 *
 *   d() { ~/.zsh/functions/bun/dev.ts d "$@"; }
 *   b() { ~/.zsh/functions/bun/dev.ts b "$@"; }
 *   i() { ~/.zsh/functions/bun/dev.ts i "$@"; }
 *   t() { ~/.zsh/functions/bun/dev.ts t "$@"; }
 *
 * 行为与原 `dev.zsh` 尽量保持一致。
 */

import { runWithTty } from './shared'

type DevCommand = 'd' | 'b' | 'i' | 't'

type PackageManager = 'pnpm' | 'bun' | 'yarn' | 'npm'

async function detectPm(cwd: string): Promise<PackageManager> {
  const path = (name: string) => `${cwd}/${name}`

  const exists = async (p: string) => {
    try {
      const stat = await Bun.file(p).stat()
      return stat.size >= 0
    }
    catch {
      return false
    }
  }

  if (await exists(path('pnpm-lock.yaml'))) {
    if (Bun.which('pnpm'))
      return 'pnpm'
  }
  if ((await exists(path('bun.lockb'))) || (await exists(path('bun.lock')))) {
    if (Bun.which('bun'))
      return 'bun'
  }
  if (await exists(path('yarn.lock'))) {
    if (Bun.which('yarn'))
      return 'yarn'
  }

  for (const p of ['pnpm', 'bun', 'yarn'] as const) {
    if (Bun.which(p))
      return p
  }

  return 'npm'
}

async function runDev(cwd: string) {
  if (await Bun.file(`${cwd}/package.json`).exists()) {
    const pm = await detectPm(cwd)
    console.log('🚀 启动 Node.js 开发服务器...')
    let code: number
    switch (pm) {
      case 'pnpm':
        console.log('+ pnpm dev')
        code = await runWithTty(cwd, ['pnpm', 'dev'])
        break
      case 'bun':
        console.log('+ bun run dev')
        code = await runWithTty(cwd, ['bun', 'run', 'dev'])
        break
      case 'yarn':
        console.log('+ yarn dev')
        code = await runWithTty(cwd, ['yarn', 'dev'])
        break
      default:
        console.log('+ npm run dev')
        code = await runWithTty(cwd, ['npm', 'run', 'dev'])
        break
    }
    if (code !== 0)
      process.exit(code)
    return
  }

  if (await Bun.file(`${cwd}/pom.xml`).exists()) {
    console.log('🚀 启动 Java 开发服务器...')
    console.log('+ nodemon -w ./controller/**/* -e java -x "mvn spring-boot:run"')
    const code = await runWithTty(cwd, [
      'nodemon', '-w', './controller/**/*', '-e', 'java', '-x', 'mvn spring-boot:run',
    ])
    if (code !== 0)
      process.exit(code)
    return
  }

  if (await Bun.file(`${cwd}/pubspec.yaml`).exists()) {
    console.log('🚀 启动 Flutter...')
    console.log('+ flutter run')
    const code = await runWithTty(cwd, ['flutter', 'run'])
    if (code !== 0)
      process.exit(code)
    return
  }

  console.error('❌ 未找到支持的项目文件')
  process.exit(1)
}

async function runBuild(cwd: string) {
  if (await Bun.file(`${cwd}/package.json`).exists()) {
    const pm = await detectPm(cwd)
    console.log('📦 构建 Node.js 项目...')
    let exitCode: number
    switch (pm) {
      case 'pnpm':
        console.log('+ pnpm build')
        exitCode = await runWithTty(cwd, ['pnpm', 'build'])
        break
      case 'bun':
        console.log('+ bun run build')
        exitCode = await runWithTty(cwd, ['bun', 'run', 'build'])
        break
      case 'yarn':
        console.log('+ yarn build')
        exitCode = await runWithTty(cwd, ['yarn', 'build'])
        break
      default:
        console.log('+ npm run build')
        exitCode = await runWithTty(cwd, ['npm', 'run', 'build'])
        break
    }
    if (exitCode !== 0)
      process.exit(exitCode)
    return
  }

  if (await Bun.file(`${cwd}/pom.xml`).exists()) {
    console.log('📦 构建 Java 项目...')
    console.log('+ mvn clean package')
    const code = await runWithTty(cwd, ['mvn', 'clean', 'package'])
    if (code !== 0)
      process.exit(code)
    return
  }

  if (await Bun.file(`${cwd}/pubspec.yaml`).exists()) {
    console.log('📦 构建 Flutter 项目...')
    console.log('+ flutter clean && flutter build')
    let code = await runWithTty(cwd, ['flutter', 'clean'])
    if (code !== 0)
      process.exit(code)
    code = await runWithTty(cwd, ['flutter', 'build'])
    if (code !== 0)
      process.exit(code)
    return
  }

  console.error('❌ 未找到支持的项目文件')
  process.exit(1)
}

async function runInstall(cwd: string, args: string[]) {
  if (await Bun.file(`${cwd}/package.json`).exists()) {
    const pm = await detectPm(cwd)
    const hasPkgs = args.length > 0
    let code: number
    if (hasPkgs) {
      console.log(`🔍 安装依赖: ${args.join(' ')}`)
      switch (pm) {
        case 'pnpm':
          console.log('+ pnpm add', args.join(' '))
          code = await runWithTty(cwd, ['pnpm', 'add', ...args])
          break
        case 'bun':
          console.log('+ bun add', args.join(' '))
          code = await runWithTty(cwd, ['bun', 'add', ...args])
          break
        case 'yarn':
          console.log('+ yarn add', args.join(' '))
          code = await runWithTty(cwd, ['yarn', 'add', ...args])
          break
        default:
          console.log('+ npm install', args.join(' '))
          code = await runWithTty(cwd, ['npm', 'install', ...args])
          break
      }
    }
    else {
      console.log('🔍 安装所有依赖...')
      switch (pm) {
        case 'pnpm':
          console.log('+ pnpm install')
          code = await runWithTty(cwd, ['pnpm', 'install'])
          break
        case 'bun':
          console.log('+ bun install')
          code = await runWithTty(cwd, ['bun', 'install'])
          break
        case 'yarn':
          console.log('+ yarn install')
          code = await runWithTty(cwd, ['yarn', 'install'])
          break
        default:
          console.log('+ npm install')
          code = await runWithTty(cwd, ['npm', 'install'])
          break
      }
    }
    if (code !== 0)
      process.exit(code)
    return
  }

  if (await Bun.file(`${cwd}/pom.xml`).exists()) {
    console.log('🔍 安装 Maven 依赖...')
    console.log('+ mvn clean install')
    const code = await runWithTty(cwd, ['mvn', 'clean', 'install'])
    if (code !== 0)
      process.exit(code)
    return
  }

  if (await Bun.file(`${cwd}/pubspec.yaml`).exists()) {
    let code: number
    if (args.length > 0) {
      console.log(`🔍 添加依赖: ${args.join(' ')}`)
      console.log('+ flutter pub add', args.join(' '))
      code = await runWithTty(cwd, ['flutter', 'pub', 'add', ...args])
    }
    else {
      console.log('🔍 获取 Flutter 依赖...')
      console.log('+ flutter pub get')
      code = await runWithTty(cwd, ['flutter', 'pub', 'get'])
    }
    if (code !== 0)
      process.exit(code)
    return
  }

  console.error('❌ 未找到支持的项目文件')
  process.exit(1)
}

async function runTest(cwd: string) {
  if (await Bun.file(`${cwd}/package.json`).exists()) {
    const pm = await detectPm(cwd)
    console.log('🧪 运行测试...')
    let code: number
    switch (pm) {
      case 'pnpm':
        console.log('+ pnpm test')
        code = await runWithTty(cwd, ['pnpm', 'test'])
        break
      case 'bun':
        console.log('+ bun test')
        code = await runWithTty(cwd, ['bun', 'test'])
        break
      case 'yarn':
        console.log('+ yarn test')
        code = await runWithTty(cwd, ['yarn', 'test'])
        break
      default:
        console.log('+ npm run test')
        code = await runWithTty(cwd, ['npm', 'run', 'test'])
        break
    }
    if (code !== 0)
      process.exit(code)
    return
  }

  if (await Bun.file(`${cwd}/pom.xml`).exists()) {
    console.log('🧪 运行 Maven 测试...')
    console.log('+ mvn test')
    const code = await runWithTty(cwd, ['mvn', 'test'])
    if (code !== 0)
      process.exit(code)
    return
  }

  if (await Bun.file(`${cwd}/pubspec.yaml`).exists()) {
    console.log('🧪 运行 Flutter 测试...')
    console.log('+ flutter test')
    const code = await runWithTty(cwd, ['flutter', 'test'])
    if (code !== 0)
      process.exit(code)
    return
  }

  console.error('❌ 未找到支持的项目文件')
  process.exit(1)
}

function printUsage() {
  console.error(
    [
      '用法:',
      '  dev.ts d [args...]  # 启动开发服务器',
      '  dev.ts b            # 构建项目',
      '  dev.ts i [pkg...]   # 安装依赖（可附加包名）',
      '  dev.ts t            # 运行测试',
      '',
      '建议在 zsh 中包一层函数保持原有命令名:',
      '  d() { ~/.zsh/functions/bun/dev.ts d "$@" }',
      '  b() { ~/.zsh/functions/bun/dev.ts b "$@" }',
      '  i() { ~/.zsh/functions/bun/dev.ts i "$@" }',
      '  t() { ~/.zsh/functions/bun/dev.ts t "$@" }',
    ].join('\n'),
  )
}

async function main() {
  const [, , sub, ...rest] = process.argv
  const cwd = process.cwd()

  if (!sub || sub === '-h' || sub === '--help') {
    printUsage()
    process.exit(sub
      ? 0
      : 1)
  }

  const cmd = sub as DevCommand

  switch (cmd) {
    case 'd':
      await runDev(cwd)
      break
    case 'b':
      await runBuild(cwd)
      break
    case 'i':
      await runInstall(cwd, rest)
      break
    case 't':
      await runTest(cwd)
      break
    default:
      printUsage()
      process.exit(1)
  }
  process.exit(0)
}

main()
