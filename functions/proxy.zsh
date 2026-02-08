# HTTP/HTTPS 与 git 代理开关

setProxy() {
  local proxy_url="http://127.0.0.1"
  local proxy_port="7890"
  local no_proxy_default="localhost,127.0.0.1,::1,192.168.0.0/16,10.0.0.0/8"

  is_port() { [[ "$1" =~ ^[0-9]+$ ]] }
  is_url()  { [[ "$1" =~ :// ]] }

  while (($#)); do
    case $1 in
      -p|--port)
        if [[ -n "${2:-}" ]] && is_port "$2"; then
          proxy_port=$2
          shift 2
        else
          echo "❌ 端口参数错误: $2"
          return 1
        fi
        ;;
      -u|--url)
        if [[ -n "${2:-}" ]]; then
          proxy_url=$2
          shift 2
        else
          echo "❌ URL 参数错误: $2"
          return 1
        fi
        ;;
      -n|--no-proxy)
        if [[ -n "${2:-}" ]]; then
          no_proxy_default=$2
          shift 2
        else
          echo "❌ NO_PROXY 参数错误: $2"
          return 1
        fi
        ;;
      *)
        if is_port "$1"; then
          proxy_port=$1
        elif is_url "$1"; then
          proxy_url=$1
        else
          echo "❌ 未知参数: $1"
          echo "用法: setProxy [URL] [端口] | setProxy [-p|--port <端口>] [-u|--url <URL>] [-n|--no-proxy <排除列表>]"
          echo "示例: setProxy 8080 | setProxy -p 8080 | setProxy --url http://proxy.example.com"
          return 1
        fi
        shift
        ;;
    esac
  done

  local proxy="${proxy_url}:${proxy_port}"
  echo "🔧 设置代理: $proxy"
  echo "🚫 排除地址: $no_proxy_default"

  export http_proxy=$proxy
  export HTTP_PROXY=$proxy
  export https_proxy=$proxy
  export HTTPS_PROXY=$proxy
  export no_proxy=$no_proxy_default
  export NO_PROXY=$no_proxy_default

  git config --global http.proxy "$proxy"
  git config --global https.proxy "$proxy"
  echo "✅ 代理设置完成"
}

unsetProxy() {
  echo "🔧 清除代理..."
  unset http_proxy HTTP_PROXY https_proxy HTTPS_PROXY no_proxy NO_PROXY
  git config --global --unset http.proxy 2>/dev/null
  git config --global --unset https.proxy 2>/dev/null
  echo "✅ 代理已清除"
}
