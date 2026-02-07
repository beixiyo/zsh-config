# zsh-config

## 配置

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
├── zshrc              # 主入口，按顺序 source 各模块
├── env.zsh            # 环境变量、PATH、Fzf
├── init.zsh           # 终端标题、Starship/Vfox/Zoxide/Fzf 初始化
├── aliases.zsh        # 别名
├── functions.zsh      #  shell 函数（ff/fs/ffo/fso/fp）
├── history.zsh        # 历史记录
├── completions.zsh    # 补全配置
├── plugins.zsh        # 插件加载入口
├── keybindings.zsh    # 快捷键（上下键历史搜索）
├── prompt.zsh         # Prompt 占位（由 Starship 接管）
├── plugins/           # 插件配置与仓库
│   ├── autosuggestions.zsh
│   ├── history-substring-search.zsh
│   ├── vi-mode.zsh
│   ├── syntax-highlighting.zsh
│   └── zsh-*/         # 各插件 git 仓库
└── setup.sh           # 从零生成全部配置（非 clone 时用）
```

---

## 模块说明

| 文件 | 功能 |
|------|------|
| `env.zsh` | PATH、BROWSER、Fzf 默认命令与主题色 |
| `init.zsh` | WezTerm 标题、Starship/Vfox/Zoxide/Fzf 初始化；cd/rm/code/nvim 的 Fzf 预览 |
| `aliases.zsh` | Docker/nvim/Dir/Tools 等别名；`ls`→eza、`cat`→bat、`top`→btop |
| `functions.zsh` | `mkcd`、`ff`/`fs`/`ffo`/`fso` 文件搜索、`fp` 杀进程 |
| `history.zsh` | 10000 条历史、多终端共享、去重 |
| `completions.zsh` | compinit、菜单选择、dircolors |
| `plugins.zsh` | 加载 autosuggestions、history-substring-search、vi-mode、syntax-highlighting |
| `keybindings.zsh` | ↑↓ 子串历史搜索 |

---

## 依赖（建议预先安装）

| 工具 | 用途 |
|------|------|
| [Starship](https://starship.rs/) | Prompt |
| [Vfox](https://github.com/version-fox/vfox) | 多运行时管理 |
| [Zoxide](https://github.com/ajeetdsouza/zoxide) | 智能 cd |
| [Fzf](https://github.com/junegunn/fzf) | 模糊搜索 |
| [fd](https://github.com/sharkdp/fd) | Fzf 文件搜索后端 |
| [eza](https://github.com/eza-community/eza) | ls 替代 |
| [bat](https://github.com/sharkdp/bat) | cat 替代、Fzf 预览 |
| [btop](https://github.com/aristocratos/btop) | top 替代 |
| [rg](https://github.com/BurntSushi/ripgrep) | fs/fso 内容搜索 |
| [safe-rm](https://github.com/kaelzhang/safe-rm) | rm 安全包装 |
| [NeoVim](https://github.com/neovim/neovim) | 编辑器 |

---

## 自定义

- **添加别名**：编辑 `~/.zsh/aliases.zsh`
- **添加函数**：编辑 `~/.zsh/functions.zsh`
- **修改 Fzf 打开方式**：`functions.zsh` 中的 `_fzf_open_header`、`_fzf_bind_file`
- **修改 PATH**：编辑 `~/.zsh/env.zsh`
- **新增插件**：在 `plugins/` 下添加 `xxx.zsh`，并在 `plugins.zsh` 中 `source`
