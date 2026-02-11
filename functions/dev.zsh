# 开发 / 构建 / 安装 / 测试：按项目类型与 lockfile 选择包管理器并执行

## 检测 Node 包管理器：优先 lock 文件，否则按 bun → pnpm → yarn → npm（需在项目根目录调用）
get_pm() {
  [[ -f pnpm-lock.yaml ]] && command -v pnpm &>/dev/null && { echo pnpm; return }
  [[ -f bun.lockb || -f bun.lock ]] && command -v bun &>/dev/null && { echo bun; return }
  [[ -f yarn.lock ]] && command -v yarn &>/dev/null && { echo yarn; return }
  for p in pnpm bun yarn; do
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
      pnpm)
        echo "+ pnpm dev"
        pnpm dev
        ;;
      bun)
        echo "+ bun run dev"
        bun run dev
        ;;
      yarn)
        echo "+ yarn dev"
        yarn dev
        ;;
      *)
        echo "+ npm run dev"
        npm run dev
        ;;
    esac
  elif [[ -f pom.xml ]]; then
    echo "🚀 启动 Java 开发服务器..."
    echo '+ nodemon -w ./controller/**/* -e java -x "mvn spring-boot:run"'
    nodemon -w ./controller/**/* -e java -x "mvn spring-boot:run"
  elif [[ -f pubspec.yaml ]]; then
    echo "🚀 启动 Flutter..."
    echo "+ flutter run"
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
      pnpm)
        echo "+ pnpm build"
        pnpm build
        ;;
      bun)
        echo "+ bun run build"
        bun run build
        ;;
      yarn)
        echo "+ yarn build"
        yarn build
        ;;
      *)
        echo "+ npm run build"
        npm run build
        ;;
    esac
  elif [[ -f pom.xml ]]; then
    echo "📦 构建 Java 项目..."
    echo "+ mvn clean package"
    mvn clean package
  elif [[ -f pubspec.yaml ]]; then
    echo "📦 构建 Flutter 项目..."
    echo "+ flutter clean && flutter build"
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
      echo "🔍 安装依赖: $*"
      case $pm in
        pnpm)
          echo "+ pnpm add $*"
          pnpm add "$@"
          ;;
        bun)
          echo "+ bun add $*"
          bun add "$@"
          ;;
        yarn)
          echo "+ yarn add $*"
          yarn add "$@"
          ;;
        *)
          echo "+ npm install $*"
          npm install "$@"
          ;;
      esac
    else
      echo "🔍 安装所有依赖..."
      case $pm in
        pnpm)
          echo "+ pnpm install"
          pnpm install
          ;;
        bun)
          echo "+ bun install"
          bun install
          ;;
        yarn)
          echo "+ yarn install"
          yarn install
          ;;
        *)
          echo "+ npm install"
          npm install
          ;;
      esac
    fi
  elif [[ -f pom.xml ]]; then
    echo "🔍 安装 Maven 依赖..."
    echo "+ mvn clean install"
    mvn clean install
  elif [[ -f pubspec.yaml ]]; then
    if (($#)); then
      echo "🔍 添加依赖: $*"
      echo "+ flutter pub add $*"
      flutter pub add "$@"
    else
      echo "🔍 获取 Flutter 依赖..."
      echo "+ flutter pub get"
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
      pnpm)
        echo "+ pnpm test"
        pnpm test
        ;;
      bun)
        echo "+ bun test"
        bun test
        ;;
      yarn)
        echo "+ yarn test"
        yarn test
        ;;
      *)
        echo "+ npm run test"
        npm run test
        ;;
    esac
  elif [[ -f pom.xml ]]; then
    echo "🧪 运行 Maven 测试..."
    echo "+ mvn test"
    mvn test
  elif [[ -f pubspec.yaml ]]; then
    echo "🧪 运行 Flutter 测试..."
    echo "+ flutter test"
    flutter test
  else
    echo "❌ 未找到支持的项目文件"
    return 1
  fi
}
