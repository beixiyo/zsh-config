#!/usr/bin/env bun

import { stat } from 'node:fs/promises'
import readline from 'node:readline'
import { $ } from 'bun'

type FileOpsCommand = 'rmr' | 'rme'

async function pathExistsDir(path: string): Promise<boolean> {
  try {
    const s = await stat(path)
    return s.isDirectory()
  }
  catch {
    return false
  }
}

async function confirm(prompt: string): Promise<boolean> {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  })

  return await new Promise((resolve) => {
    rl.question(prompt, (answer) => {
      rl.close()
      resolve(/^[Yy]$/.test(answer.trim()))
    })
  })
}

async function runRmr(root: string, patterns: string[]) {
  if (!root || patterns.length === 0) {
    console.error('用法: rmr <根目录> <文件名模式1> [模式2] ...')
    process.exit(1)
  }

  if (!await pathExistsDir(root)) {
    console.error(`❌ 目录不存在: ${root}`)
    process.exit(1)
  }

  console.log(`🔍 在 ${root} 中搜索匹配: ${patterns.join(' ')}`)

  const targets = new Set<string>()

  for (const pattern of patterns) {
    const result = await $`fd --glob ${pattern} ${root} --unrestricted --color never`.nothrow()
    const stdout = result.stdout.toString()
    for (const line of stdout.split('\n')) {
      const trimmed = line.trim()
      if (trimmed.length > 0)
        targets.add(trimmed)
    }
  }

  const list = Array.from(targets)

  if (list.length === 0) {
    console.log('🗂️  未找到匹配的文件')
    return
  }

  console.log(`🗑️  将删除以下文件 (共 ${list.length} 个):`)
  for (const f of list)
    console.log(`   ${f}`)
  console.log()

  const ok = await confirm('⚠️  确认删除? [y/N] ')
  if (!ok) {
    console.log('❌ 操作已取消')
    return
  }

  console.log('🚀 开始删除...')
  for (const f of list) {
    console.log(`   删除: ${f}`)
    await $`rm -rf ${f}`.nothrow()
  }
  console.log('🎉 删除完成！')
}

async function runRme(keepNames: string[]) {
  if (keepNames.length === 0) {
    console.error('用法: rme <要保留的文件名1> [文件名2] ...')
    console.error('示例: rme .git README.md package.json')
    process.exit(1)
  }

  console.log('🔍 将删除当前目录除以下文件外的所有内容:')
  for (const name of keepNames)
    console.log(`   ✓ ${name}`)
  console.log()

  const ok = await confirm('⚠️  确认删除? [y/N] ')
  if (!ok) {
    console.log('❌ 操作已取消')
    return
  }

  const args: string[] = ['.', '-mindepth', '1', '-maxdepth', '1']
  for (const name of keepNames) {
    args.push('!', '-name', name)
  }

  console.log('🚀 开始删除...')
  await $`find ${args} -exec rm -rf {} +`.nothrow()
  console.log('🎉 删除完成！')
}

function printUsage() {
  console.error(
    [
      '用法:',
      '  file-ops.ts rmr <根目录> <文件名模式1> [模式2] ...',
      '  file-ops.ts rme <要保留的文件名1> [文件名2] ...',
      '',
      '建议在 zsh 中保留原有函数名:',
      '  rmr() { bun run ~/.zsh/functions/bun/src/file-ops.ts rmr "$@" }',
      '  rme() { bun run ~/.zsh/functions/bun/src/file-ops.ts rme "$@" }',
    ].join('\n'),
  )
}

async function main() {
  const [, , sub, ...rest] = process.argv

  if (!sub || sub === '-h' || sub === '--help') {
    printUsage()
    process.exit(sub ? 0 : 1)
  }

  const cmd = sub as FileOpsCommand

  switch (cmd) {
    case 'rmr': {
      const [root, ...patterns] = rest
      await runRmr(root, patterns)
      break
    }
    case 'rme':
      await runRme(rest)
      break
    default:
      printUsage()
      process.exit(1)
  }
}

main()

