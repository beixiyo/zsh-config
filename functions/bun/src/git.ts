#!/usr/bin/env bun

/**
 * 输出 git status --short 的列表，供 fzf 使用。
 * 格式：icon \t status(3) \t path，按 path 排序。
 * 约定：process.stdout.write + process.exit(0)，避免 fzf 错行。
 */

import { $ } from 'bun'
import { COLORS } from './shared';

const ICON_STAGED = `${COLORS.Green}${COLORS.Reset}`
const ICON_OTHER = `${COLORS.Red}${COLORS.Reset}`

function parsePath(raw: string): string {
  let f = raw.replace(/^[\s\t]+|[\s\t]+$/g, '')
  if (f.startsWith('"')) {
    f = f.slice(1, f.length - 1).replace(/\\\\/g, '\\')
  }
  return f
}

async function main(): Promise<void> {
  const result = await $`git -c core.quotepath=false status --short`.nothrow().quiet()
  if (result.exitCode !== 0) {
    process.exit(1)
  }
  const stdout = result.stdout.toString()
  const lines = stdout.split('\n').filter(line => line.length > 0)

  const rows: [string, string, string][] = []
  for (const line of lines) {
    const s = line.slice(0, 3)
    const pathRaw = line.slice(3)
    const path = parsePath(pathRaw)
    const idx = s[0]
    const icon = idx !== ' ' && idx !== '?'
      ? ICON_STAGED
      : ICON_OTHER
    rows.push([icon, s, path])
  }

  rows.sort((a, b) => a[2].localeCompare(b[2], 'en'))

  for (const [icon, status, path] of rows) {
    process.stdout.write(`${icon}\t${status}\t${path}\n`)
  }
  process.exit(0)
}

main().catch(() => process.exit(1))
