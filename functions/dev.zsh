# 开发 / 构建 / 安装 / 测试：按项目类型与 lockfile 选择包管理器并执行

## 检测 Node 包管理器：优先 lock 文件，否则按 bun → pnpm → yarn → npm（需在项目根目录调用）
get_pm() {
  [[ -f bun.lockb || -f bun.lock ]] && command -v bun &>/dev/null && { echo bun; return }
  [[ -f pnpm-lock.yaml ]] && command -v pnpm &>/dev/null && { echo pnpm; return }
  [[ -f yarn.lock ]] && command -v yarn &>/dev/null && { echo yarn; return }
  for p in bun pnpm yarn; do
    command -v $p &>/dev/null && { echo $p; return }
  done
  echo npm
}

## 启动开发服务器
d() {
  if [[ -f package.json ]]; then
    local pm
    pm=$(get_pm)
    echo "🚀 启动 Node.js 开发服务器..."
    case $pm in
      bun)  bun run dev ;;
      pnpm) pnpm dev ;;
      yarn) yarn dev ;;
      *)    npm run dev ;;
    esac
  elif [[ -f pom.xml ]]; then
    echo "🚀 启动 Java 开发服务器..."
    nodemon -w ./controller/**/* -e java -x "mvn spring-boot:run"
  elif [[ -f pubspec.yaml ]]; then
    echo "🚀 启动 Flutter..."
    flutter run
  else
    echo "❌ 未找到支持的项目文件"
    return 1
  fi
}

## 构建项目
b() {
  if [[ -f package.json ]]; then
    local pm
    pm=$(get_pm)
    echo "📦 构建 Node.js 项目..."
    case $pm in
      bun)  bun run build ;;
      pnpm) pnpm build ;;
      yarn) yarn build ;;
      *)    npm run build ;;
    esac
  elif [[ -f pom.xml ]]; then
    echo "📦 构建 Java 项目..."
    mvn clean package
  elif [[ -f pubspec.yaml ]]; then
    echo "📦 构建 Flutter 项目..."
    flutter clean && flutter build
  else
    echo "❌ 未找到支持的项目文件"
    return 1
  fi
}

## 安装依赖；可传包名安装指定包
i() {
  if [[ -f package.json ]]; then
    local pm
    pm=$(get_pm)
    if (($#)); then
      echo "📥 安装依赖: $*"
      case $pm in
        bun)  bun add "$@" ;;
        pnpm) pnpm add "$@" ;;
        yarn) yarn add "$@" ;;
        *)    npm install "$@" ;;
      esac
    else
      echo "📥 安装所有依赖..."
      case $pm in
        bun)  bun install ;;
        pnpm) pnpm install ;;
        yarn) yarn install ;;
        *)    npm install ;;
      esac
    fi
  elif [[ -f pom.xml ]]; then
    echo "📥 安装 Maven 依赖..."
    mvn clean install
  elif [[ -f pubspec.yaml ]]; then
    if (($#)); then
      echo "📥 添加依赖: $*"
      flutter pub add "$@"
    else
      echo "📥 获取 Flutter 依赖..."
      flutter pub get
    fi
  else
    echo "❌ 未找到支持的项目文件"
    return 1
  fi
}

## 运行测试
t() {
  if [[ -f package.json ]]; then
    local pm
    pm=$(get_pm)
    echo "🧪 运行测试..."
    case $pm in
      bun)  bun test ;;
      pnpm) pnpm test ;;
      yarn) yarn test ;;
      *)    npm run test ;;
    esac
  elif [[ -f pom.xml ]]; then
    echo "🧪 运行 Maven 测试..."
    mvn test
  elif [[ -f pubspec.yaml ]]; then
    echo "🧪 运行 Flutter 测试..."
    flutter test
  else
    echo "❌ 未找到支持的项目文件"
    return 1
  fi
}
