# zsh-config

## 配置

**前置依赖**

```bash
# Homebrew
brew install bat fzf fd ripgrep tree eza zoxide btop git-delta safe-rm

# =============================================

# Debian/Ubuntu
sudo apt install -y bat fzf fd-find ripgrep tree btop safe-rm

## eza（https://eza.rocks/）
sudo apt install -y gpg && \
sudo mkdir -p /etc/apt/keyrings && \
wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg && \
echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list && \
sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list && \
sudo apt update && \
sudo apt install -y eza

## zoxide 增强 cd
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh

# Git diff 高亮
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

完成后执行 `exec zsh` 或重新打开终端

---

## 目录结构

```
~/.zsh/
├── zshrc                 # 主入口：env → (secret) → plugins → init → aliases → functions → history → completions → keybindings → prompt
├── env.zsh               # 环境变量、PATH、Fzf 默认命令与主题、Yazi 配置路径
├── init.zsh              # 终端标题、Starship/Vfox/Zoxide、Fzf 预览（eza/bat）
├── aliases.zsh           # 别名（Docker/nvim/Dir/Tools；ls→eza, cat→bat, top→btop, rm→safe-rm）
├── functions/
│   ├── index.zsh         # 按序 source 下列子模块
│   ├── file-ops.zsh      # mkcd、lt 树形列表、rmr 按模式删除
│   ├── fzf.zsh           # ff/fs/ffo/fso 文件与内容搜索
│   ├── git.zsh           # gdiff 等（依赖 git-delta）
│   ├── yazi.zsh          # 与 yazi 文件管理器集成
│   ├── process.zsh       # fp 杀进程
│   ├── docker.zsh       # dd 统一 Docker 操作
│   ├── docker-dispatch.zsh
│   ├── dev.zsh
│   └── proxy.zsh
├── history.zsh           # 历史记录
├── completions.zsh       # 补全配置
├── plugins.zsh           # 插件加载入口
├── keybindings.zsh       # 快捷键（↑↓ 子串历史搜索）
├── prompt.zsh            # Prompt 占位（由 Starship 接管）
├── plugins/              # 插件配置与仓库
│   ├── autosuggestions.zsh
│   ├── history-substring-search.zsh
│   ├── vi-mode.zsh       # 内含 fzf --zsh 延迟加载
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
| `init.zsh` | WezTerm 标题、Starship/Vfox/Zoxide 初始化；cd/rm/code/nvim 的 Fzf 预览（eza/bat） |
| `aliases.zsh` | Docker/nvim/Dir/Tools 等别名；`ls`→eza、`cat`→bat、`top`→btop、`rm`→safe-rm |
| `functions/` | `index.zsh` 按序加载 file-ops、fzf、git、yazi、process、docker、dev、proxy；含 mkcd、lt、rmr、ff/fs/ffo/fso、fp、dd、gdiff 等 |
| `history.zsh` | 10000 条历史、多终端共享、去重 |
| `completions.zsh` | compinit、菜单选择、dircolors |
| `plugins.zsh` | 加载 autosuggestions、history-substring-search、syntax-highlighting、vi-mode（vi-mode 内加载 fzf） |
| `keybindings.zsh` | ↑↓ 子串历史搜索（须在 plugins 之后） |

---

## 依赖（建议预先安装）

| 工具 | 用途 |
|------|------|
| [Starship](https://starship.rs/) | Prompt |
| [Vfox](https://github.com/version-fox/vfox) | 多运行时管理 |
| [Zoxide](https://github.com/ajeetdsouza/zoxide) | 智能 cd |
| [Fzf](https://github.com/junegunn/fzf) | 模糊搜索 |
| [fd](https://github.com/sharkdp/fd) | Fzf 文件搜索后端 |
| [eza](https://github.com/eza-community/eza) | ls 替代、Fzf 目录预览 |
| [bat](https://github.com/sharkdp/bat) | cat 替代、Fzf 文件预览 |
| [btop](https://github.com/aristocratos/btop) | top 替代（别名 `top`） |
| [rg](https://github.com/BurntSushi/ripgrep) | fs/fso 内容搜索 |
| [delta](https://github.com/dandavison/delta) | gdiff 等 Git  diff 预览 |
| [safe-rm](https://github.com/kaelzhang/safe-rm) | rm 安全包装（别名 `rm`） |
| [NeoVim](https://github.com/neovim/neovim) | 编辑器 |
| [Yazi](https://github.com/sxyazi/yazi) | 可选；文件管理器，配置在 `~/.zsh/yazi` |

---

## 自定义

- **添加别名**：编辑 `~/.zsh/aliases.zsh`
- **添加函数**：编辑 `~/.zsh/functions/index.zsh`（新增 source）或 `~/.zsh/functions/*.zsh`（具体逻辑）
- **修改 Fzf 打开方式**：`~/.zsh/functions/fzf.zsh` 中的 `_fzf_bind_file`、`_fzf_ff_header` 等
- **修改 PATH**：编辑 `~/.zsh/env.zsh`
- **新增插件**：在 `plugins/` 下添加 `xxx.zsh`，并在 `plugins.zsh` 中 `source`
