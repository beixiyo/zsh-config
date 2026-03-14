# zsh-config

## 配置

**前置依赖**

```bash
# Homebrew
brew install bat fzf fd ripgrep tree lsd zoxide btop git-delta safe-rm bun

# =============================================

# Debian/Ubuntu
sudo apt install -y bat fzf fd-find ripgrep tree lsd btop safe-rm

## bun
curl -fsSL https://bun.sh/install | bash

## zoxide 增强 cd https://crates.io/crates/zoxide
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh

# Git diff 高亮 https://github.com/dandavison/delta
wget https://github.com/dandavison/delta/releases/download/0.18.2/git-delta_0.18.2_amd64.deb -O git-delta.deb && \
sudo dpkg -i git-delta.deb

# fd/bat 链接（放 /usr/local/bin 无需改 PATH；若用 ~/.local/bin 需在 shell 配置里加 export PATH="$HOME/.local/bin:$PATH"）
sudo ln -sf $(which fdfind) /usr/local/bin/fd 2>/dev/null || true
sudo ln -sf /usr/bin/batcat /usr/local/bin/bat 2>/dev/null || true
```

**安装本配置**

```bash
git clone --depth=1 --single-branch --no-tags https://github.com/beixiyo/zsh-config.git ~/.zsh && \
([[ -f ~/.zshrc ]] && mv ~/.zshrc ~/.zshrc.bak$(date +%Y-%m-%d_%H) || true) && \
echo 'source ~/.zsh/zshrc' > ~/.zshrc
```

完成后执行 `exec zsh` 或重新打开终端。之后可用内置命令 **`ins`** 按发行版一键装包（见下方「内置好用工具」）

---

## 目录结构

```
~/.zsh/
├── AGENTS.md              # 开发规范：Zsh (UI/交互) & Bun (逻辑/计算) 协作指南
├── functions/
│   ├── bun/src            # Bun 实现的业务逻辑 (TypeScript)
│   ├── index.zsh          # 函数加载总入口
│   └── ...                # 各模块的 Zsh 胶水层实现
├── env.zsh               # 环境变量、PATH、Fzf 默认命令与主题、Yazi 配置路径
├── init.zsh              # 终端标题、Starship/Zoxide/Mise、Fzf 预览（lsd/bat）
├── aliases.zsh           # 别名（Docker/nvim/Dir/Tools；ls→lsd, cat→bat, top→btop, rm→safe-rm）
├── history.zsh           # 历史记录
├── completions.zsh       # 补全配置
├── plugins.zsh           # 插件加载入口
├── keybindings.zsh       # 快捷键（↑↓ 子串历史搜索）
├── prompt.zsh            # Prompt 占位（由 Starship 接管）
├── plugins/              # 插件配置与仓库
│   ├── autosuggestions.zsh
│   ├── history-substring-search.zsh
│   ├── vi-mode.zsh       # 内含 fzf --zsh 延迟加载确保快捷键 Ctrl-r 正常注册
│   ├── syntax-highlighting.zsh
│   └── zsh-*/            # 各插件 git 仓库
└── yazi/                 # Yazi 配置（YAZI_CONFIG_HOME 指向此处）
    ├── yazi.toml
    ├── theme.toml
    └── ...
```

---

## 模块说明

| 文件 / 目录 | 功能 |
|-------------|------|
| `env.zsh` | PATH、BROWSER、平台键位、Fzf 默认命令与主题色、HOMEBREW 镜像、YAZI_CONFIG_HOME |
| `init.zsh` | WezTerm 标题、Starship/Zoxide/Mise 初始化；cd/rm/code/nvim 的 Fzf 预览（lsd/bat） |
| `aliases.zsh` | Docker/nvim/Dir/Tools 等别名；`ls`→lsd、`cat`→bat、`top`→btop、`rm`→safe-rm |
| `functions/` | `index.zsh` 按序加载 file-ops、fzf、git、yazi、process、docker、dev、proxy、pkg；内置命令见下表「内置好用工具」 |
| `history.zsh` | 10000 条历史、多终端共享、去重 |
| `completions.zsh` | compinit、菜单选择、dircolors |
| `plugins.zsh` | 加载 autosuggestions、history-substring-search、syntax-highlighting、vi-mode（vi-mode 内加载 fzf） |
| `keybindings.zsh` | ↑↓ 子串历史搜索（须在 plugins 之后） |

---

## 内置好用工具

加载本配置后可直接使用的命令（按模块分类）：

| 命令 | 说明 |
|------|------|
| **文件与目录** | |
| `mkcd <dir>...` | 创建目录并进入 |
| `lt [层级] [路径...]` | 树形列表（默认深度 2，依赖 lsd） |
| `rmr <根目录> <模式...>` | 按文件名模式递归查找并确认后删除（Bun） |
| `rme <保留名...>` | 删除当前目录除指定名称外的所有项（Bun） |
| `open [路径]` | 用系统文件管理器打开目录（WSL→explorer，macOS→Finder，Linux→xdg-open） |
| **搜索与打开** | |
| `ff [-d\|-f\|-a] [路径]` | Fzf 选文件/目录，Alt-O nvim、Ctrl-O VSCode（Bun 列表） |
| `fs [路径]` | Fzf 搜内容（rg），选行后 Alt-O/Ctrl-O 打开并跳行（Bun） |
| **Git** | |
| `gdiff` | Fzf 选文件看 diff，Stage/Unstage（delta 预览） |
| **进程** | |
| `fp [端口]` | Fzf 选进程杀（无参全部，有参仅该端口；依赖 lsof） |
| `killByName <名>` / `killByPort <端口>` | 按名/按端口杀进程（Bun） |
| **Docker** | |
| `dd` | 统一面板：容器+镜像，Tab 多选，l/e/c/s/r/R/d/i 等快捷键（Bun） |
| `dinfo <repo> <tag>` | 查 Docker Hub 仓库 tag 的 digest/size（Bun） |
| **开发** | |
| `d` / `b` / `i` / `t` | 开发/构建/安装/测试（转发到 `functions/bun/src/dev.ts`） |
| **代理** | |
| `setProxy [端口]` / `unsetProxy` | HTTP(S) 与 git 代理开关（Bun 生成 export/unset） |
| **包管理** | |
| `ins <包名>...` | 通用安装：按发行版执行 pacman/apt/dnf/zypper/apk/brew |

*依赖 Bun 的命令在未安装 Bun 时会提示；`ff`/`fs`/`gdiff`/`dd` 等还依赖 fzf，部分依赖 rg/delta/lsd*

---

## 依赖（建议预先安装）

| 工具 | 用途 |
|------|------|
| [Starship](https://starship.rs/) | Prompt |
| [Zoxide](https://github.com/ajeetdsouza/zoxide) | 智能 cd |
| [Fzf](https://github.com/junegunn/fzf) | 模糊搜索 |
| [fd](https://github.com/sharkdp/fd) | Fzf 文件搜索后端 |
| [lsd](https://github.com/lsd-rs/lsd) | ls 替代、Fzf 目录预览 |
| [bat](https://github.com/sharkdp/bat) | cat 替代、Fzf 文件预览 |
| [btop](https://github.com/aristocratos/btop) | top 替代（别名 `top`） |
| [rg](https://github.com/BurntSushi/ripgrep) | fs/fso 内容搜索 |
| [delta](https://github.com/dandavison/delta) | gdiff 等 Git  diff 预览 |
| [safe-rm](https://github.com/kaelzhang/safe-rm) | rm 安全包装（别名 `rm`） |
| [NeoVim](https://github.com/neovim/neovim) | 编辑器 |
| [Yazi](https://github.com/sxyazi/yazi) | 可选；文件管理器，配置在 `~/.zsh/yazi` |
| [Bun](https://bun.sh/) | 运行 `functions/bun/*.ts` 中的 TypeScript 脚本 |

---

## 自定义

- **添加别名**：编辑 `~/.zsh/aliases.zsh`
- **添加函数**：参考 `AGENTS.md` 了解 Zsh 与 Bun 的协作规范。通常在 `functions/bun/src/` 编写逻辑，在 `functions/*.zsh` 编写 UI 绑定
- **修改 Fzf 打开方式**：`~/.zsh/functions/fzf.zsh` 中的 `_fzf_bind_file`、`_fzf_ff_header` 等
- **修改 PATH**：编辑 `~/.zsh/env.zsh`
- **新增插件**：在 `plugins/` 下添加 `xxx.zsh`，并在 `plugins.zsh` 中 `source`
