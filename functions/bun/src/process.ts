#!/usr/bin/env bun

import readline from 'node:readline'
import { $ } from 'bun'

type ProcessCommand = 'kill-by-name' | 'kill-by-port' | 'kill'

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

function ensureNumeric(value: string, label: string): void {
  if (!/^[0-9]+$/.test(value)) {
    throw new Error(`❌ ${label} 必须是数字: ${value}`)
  }
}

async function commandExists(name: string): Promise<boolean> {
  return !!Bun.which(name)
}

async function getPidsByName(pattern: string): Promise<string[]> {
  if (!await commandExists('pgrep')) {
    throw new Error('❌ 未找到 pgrep 命令')
  }

  const result = await $`pgrep -f ${pattern}`.nothrow()
  const stdout = result.stdout.toString()
  const pids = stdout
    .split('\n')
    .map(line => line.trim())
    .filter(Boolean)

  return pids
}

async function getPidsByPort(port: string): Promise<string[]> {
  ensureNumeric(port, '端口号')

  if (!await commandExists('lsof')) {
    throw new Error('❌ 未找到 lsof 命令')
  }

  const result = await $`lsof -ti :${port}`.nothrow()
  const stdout = result.stdout.toString()
  const pids = stdout
    .split('\n')
    .map(line => line.trim())
    .filter(Boolean)

  return pids
}

async function showProcesses(pids: string[]): Promise<void> {
  if (pids.length === 0)
    return

  const result = await $`ps -p ${pids} -o pid,ppid,user,comm,args`.nothrow()
  const stdout = result.stdout.toString().trim()

  if (stdout.length === 0) {
    console.log('未找到匹配的进程')
    return
  }

  console.log('找到进程:')
  console.log(stdout)
  console.log()
}

async function sleep(ms: number): Promise<void> {
  await new Promise(resolve => setTimeout(resolve, ms))
}

async function filterAlivePids(pids: string[]): Promise<string[]> {
  const alive: string[] = []

  for (const pid of pids) {
    const result = await $`kill -0 ${pid}`.nothrow()
    if (result.exitCode === 0)
      alive.push(pid)
  }

  return alive
}

async function terminateAndKill(pids: string[], message: string): Promise<void> {
  if (pids.length === 0) {
    console.log('未找到匹配的进程')
    return
  }

  await showProcesses(pids)

  const ok = await confirm(`⚠️  ${message} [y/N] `)
  if (!ok) {
    console.log('❌ 已取消')
    return
  }

  await $`kill ${pids}`.nothrow()
  await sleep(2000)

  let remaining = await filterAlivePids(pids)

  if (remaining.length > 0) {
    console.log('⚠️  部分进程未响应 TERM 信号，使用强制终止...')
    await $`kill -9 ${remaining}`.nothrow()
    await sleep(1000)
  }

  const final = await filterAlivePids(pids)

  if (final.length > 0) {
    console.log(`❌ 以下进程未能终止: ${final.join(' ')}`)
  }
  else {
    console.log('✅ 进程已成功终止')
  }
}

async function runKillByName(pattern: string): Promise<void> {
  if (!pattern) {
    console.error('用法: process.ts kill-by-name <进程名称>')
    process.exit(1)
  }

  const pids = await getPidsByName(pattern)
  await terminateAndKill(pids, `确认杀死所有匹配 '${pattern}' 的进程?`)
}

async function runKillByPort(port: string): Promise<void> {
  if (!port) {
    console.error('用法: process.ts kill-by-port <端口号>')
    process.exit(1)
  }

  const pids = await getPidsByPort(port)
  await terminateAndKill(pids, `确认杀死监听端口 ${port} 的进程?`)
}

async function runKill(pids: string[]): Promise<void> {
  if (pids.length === 0) {
    console.error('用法: process.ts kill <PID1> [PID2] ...')
    process.exit(1)
  }

  for (const pid of pids)
    ensureNumeric(pid, 'PID')

  await terminateAndKill(pids, `确认杀死进程: ${pids.join(' ')}?`)
}

function printUsage(): void {
  console.error(
    [
      '用法:',
      '  process.ts kill-by-name <进程名称>',
      '  process.ts kill-by-port <端口号>',
      '  process.ts kill <PID1> [PID2] ...',
      '',
      '建议在 zsh 中封装原有函数名:',
      '  killByName() { bun run ~/.zsh/functions/bun/src/process.ts kill-by-name "$@" }',
      '  killByPort() { bun run ~/.zsh/functions/bun/src/process.ts kill-by-port "$@" }',
      '  # fp 中使用 fzf 选出 PID 后调用:',
      '  # bun run ~/.zsh/functions/bun/src/process.ts kill <PID...>',
    ].join('\n'),
  )
}

async function main() {
  const [, , sub, ...rest] = process.argv

  if (!sub || sub === '-h' || sub === '--help') {
    printUsage()
    process.exit(sub ? 0 : 1)
  }

  const cmd = sub as ProcessCommand

  try {
    switch (cmd) {
      case 'kill-by-name':
        await runKillByName(rest[0] ?? '')
        break
      case 'kill-by-port':
        await runKillByPort(rest[0] ?? '')
        break
      case 'kill': {
        await runKill(rest)
        break
      }
      default:
        printUsage()
        process.exit(1)
    }
  }
  catch (err) {
    console.error((err as Error).message)
    process.exit(1)
  }
}

main()
