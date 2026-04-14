#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEFAULT_CASK_FILE="$ROOT_DIR/Casks/wechat-multi.rb"

usage() {
  cat <<'EOF'
Usage:
  update-homebrew-cask.sh --version <version> --sha256 <sha256> --url <url> [options]

Options:
  --cask-file <path>   Path to wechat-multi.rb
  --app-name <name>    App bundle name for new cask files
  --desc <text>        Description for new cask files
  --homepage <url>     Homepage for new cask files
EOF
}

require_value() {
  local name="$1"
  local value="$2"
  if [[ -z "$value" ]]; then
    echo "Missing required value: $name" >&2
    exit 1
  fi
}

cask_file="$DEFAULT_CASK_FILE"
version=""
sha256=""
url=""
app_name="WeChatMulti"
desc="Launch multiple WeChat instances on macOS"
homepage="https://github.com/KevoraLabs/wechat-multi"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --cask-file)
      cask_file="$2"
      shift 2
      ;;
    --version)
      version="$2"
      shift 2
      ;;
    --sha256)
      sha256="$2"
      shift 2
      ;;
    --url)
      url="$2"
      shift 2
      ;;
    --app-name)
      app_name="$2"
      shift 2
      ;;
    --desc)
      desc="$2"
      shift 2
      ;;
    --homepage)
      homepage="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

require_value "version" "$version"
require_value "sha256" "$sha256"
require_value "url" "$url"

mkdir -p "$(dirname "$cask_file")"

if [[ ! -f "$cask_file" ]]; then
  cat >"$cask_file" <<EOF
cask "wechat-multi" do
  version "$version"
  sha256 "$sha256"

  url "$url",
      verified: "github.com/KevoraLabs/wechat-multi/"
  name "$app_name"
  desc "$desc"
  homepage "$homepage"

  app "$app_name.app"
end
EOF

  echo "Created $cask_file"
  exit 0
fi

export CASK_FILE="$cask_file"
export CASK_VERSION="$version"
export CASK_SHA256="$sha256"
export CASK_URL="$url"
export CASK_APP_NAME="$app_name"
export CASK_DESC="$desc"
export CASK_HOMEPAGE="$homepage"

ruby <<'RUBY'
path = ENV.fetch("CASK_FILE")
content = File.read(path)

has_verified = content.match?(/^\s*verified\s+/)
url_replacement = has_verified ? "  url \"#{ENV.fetch("CASK_URL")}\"," : "  url \"#{ENV.fetch("CASK_URL")}\""

replacements = {
  /^\s*version\s+.*$/ => "  version \"#{ENV.fetch("CASK_VERSION")}\"",
  /^\s*sha256\s+.*$/ => "  sha256 \"#{ENV.fetch("CASK_SHA256")}\"",
  /^\s*url\s+.*$/ => url_replacement,
  /^\s*homepage\s+.*$/ => "  homepage \"#{ENV.fetch("CASK_HOMEPAGE")}\"",
  /^\s*name\s+.*$/ => "  name \"#{ENV.fetch("CASK_APP_NAME")}\"",
  /^\s*desc\s+.*$/ => "  desc \"#{ENV.fetch("CASK_DESC")}\""
}

replacements.each do |pattern, replacement|
  if content.match?(pattern)
    content.sub!(pattern, replacement)
  end
end

unless content.match?(/^\s*version\s+/)
  content.sub!(/cask\s+"wechat-multi"\s+do\n/, "\\0  version \"#{ENV.fetch("CASK_VERSION")}\"\n")
end

unless content.match?(/^\s*sha256\s+/)
  content.sub!(/^\s*version\s+.*$\n/, "\\0  sha256 \"#{ENV.fetch("CASK_SHA256")}\"\n")
end

unless content.match?(/^\s*url\s+/)
  insertion = "#{url_replacement}\n"
  if content.match?(/^\s*sha256\s+/)
    content.sub!(/^\s*sha256\s+.*$\n/, "\\0\n#{insertion}")
  else
    content.sub!(/cask\s+"wechat-multi"\s+do\n/, "\\0#{insertion}")
  end
end

File.write(path, content)
RUBY

echo "Updated $cask_file"
