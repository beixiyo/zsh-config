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

import { $ } from 'bun'

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
    switch (pm) {
      case 'pnpm':
        console.log('+ pnpm dev')
        await $`pnpm dev`
        return
      case 'bun':
        console.log('+ bun run dev')
        await $`bun run dev`
        return
      case 'yarn':
        console.log('+ yarn dev')
        await $`yarn dev`
        return
      default:
        console.log('+ npm run dev')
        await $`npm run dev`
        return
    }
  }

  if (await Bun.file(`${cwd}/pom.xml`).exists()) {
    console.log('🚀 启动 Java 开发服务器...')
    console.log('+ nodemon -w ./controller/**/* -e java -x "mvn spring-boot:run"')
    await $`nodemon -w ./controller/**/* -e java -x "mvn spring-boot:run"`
    return
  }

  if (await Bun.file(`${cwd}/pubspec.yaml`).exists()) {
    console.log('🚀 启动 Flutter...')
    console.log('+ flutter run')
    await $`flutter run`
    return
  }

  console.error('❌ 未找到支持的项目文件')
  process.exit(1)
}

async function runBuild(cwd: string) {
  if (await Bun.file(`${cwd}/package.json`).exists()) {
    const pm = await detectPm(cwd)
    console.log('📦 构建 Node.js 项目...')
    switch (pm) {
      case 'pnpm':
        console.log('+ pnpm build')
        await $`pnpm build`
        return
      case 'bun':
        console.log('+ bun run build')
        await $`bun run build`
        return
      case 'yarn':
        console.log('+ yarn build')
        await $`yarn build`
        return
      default:
        console.log('+ npm run build')
        await $`npm run build`
        return
    }
  }

  if (await Bun.file(`${cwd}/pom.xml`).exists()) {
    console.log('📦 构建 Java 项目...')
    console.log('+ mvn clean package')
    await $`mvn clean package`
    return
  }

  if (await Bun.file(`${cwd}/pubspec.yaml`).exists()) {
    console.log('📦 构建 Flutter 项目...')
    console.log('+ flutter clean && flutter build')
    await $`flutter clean`
    await $`flutter build`
    return
  }

  console.error('❌ 未找到支持的项目文件')
  process.exit(1)
}

async function runInstall(cwd: string, args: string[]) {
  if (await Bun.file(`${cwd}/package.json`).exists()) {
    const pm = await detectPm(cwd)
    const hasPkgs = args.length > 0
    if (hasPkgs) {
      console.log(`🔍 安装依赖: ${args.join(' ')}`)
      switch (pm) {
        case 'pnpm':
          console.log('+ pnpm add', args.join(' '))
          await $`pnpm add ${args}`
          return
        case 'bun':
          console.log('+ bun add', args.join(' '))
          await $`bun add ${args}`
          return
        case 'yarn':
          console.log('+ yarn add', args.join(' '))
          await $`yarn add ${args}`
          return
        default:
          console.log('+ npm install', args.join(' '))
          await $`npm install ${args}`
          return
      }
    }
    else {
      console.log('🔍 安装所有依赖...')
      switch (pm) {
        case 'pnpm':
          console.log('+ pnpm install')
          await $`pnpm install`
          return
        case 'bun':
          console.log('+ bun install')
          await $`bun install`
          return
        case 'yarn':
          console.log('+ yarn install')
          await $`yarn install`
          return
        default:
          console.log('+ npm install')
          await $`npm install`
          return
      }
    }
  }

  if (await Bun.file(`${cwd}/pom.xml`).exists()) {
    console.log('🔍 安装 Maven 依赖...')
    console.log('+ mvn clean install')
    await $`mvn clean install`
    return
  }

  if (await Bun.file(`${cwd}/pubspec.yaml`).exists()) {
    if (args.length > 0) {
      console.log(`🔍 添加依赖: ${args.join(' ')}`)
      console.log('+ flutter pub add', args.join(' '))
      await $`flutter pub add ${args}`
    }
    else {
      console.log('🔍 获取 Flutter 依赖...')
      console.log('+ flutter pub get')
      await $`flutter pub get`
    }
    return
  }

  console.error('❌ 未找到支持的项目文件')
  process.exit(1)
}

async function runTest(cwd: string) {
  if (await Bun.file(`${cwd}/package.json`).exists()) {
    const pm = await detectPm(cwd)
    console.log('🧪 运行测试...')
    switch (pm) {
      case 'pnpm':
        console.log('+ pnpm test')
        await $`pnpm test`
        return
      case 'bun':
        console.log('+ bun test')
        await $`bun test`
        return
      case 'yarn':
        console.log('+ yarn test')
        await $`yarn test`
        return
      default:
        console.log('+ npm run test')
        await $`npm run test`
        return
    }
  }

  if (await Bun.file(`${cwd}/pom.xml`).exists()) {
    console.log('🧪 运行 Maven 测试...')
    console.log('+ mvn test')
    await $`mvn test`
    return
  }

  if (await Bun.file(`${cwd}/pubspec.yaml`).exists()) {
    console.log('🧪 运行 Flutter 测试...')
    console.log('+ flutter test')
    await $`flutter test`
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
