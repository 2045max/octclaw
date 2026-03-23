#!/usr/bin/env bash
set -euo pipefail

OCTCLAW_REPO="https://github.com/2045max/octclaw.git"

_info() { printf '[INFO] %s\n' "$*"; }
_error() { printf '[ERROR] %s\n' "$*" >&2; exit 1; }

main() {
  _info "Installing OctClaw..."

  # Check bash version
  [[ ${BASH_VERSINFO[0]} -lt 3 ]] && _error "Bash 3.2+ required"
  
  # Check dependencies
  command -v jq &>/dev/null || _error "jq required. Install: brew install jq (macOS) or apt install jq (Linux)"
  command -v curl &>/dev/null || _error "curl required"

  # Download
  local tmp_dir
  tmp_dir=$(mktemp -d)
  trap "rm -rf '$tmp_dir'" EXIT
  
  if command -v git &>/dev/null; then
    _info "Cloning..."
    git clone --depth 1 "$OCTCLAW_REPO" "$tmp_dir/octclaw"
  else
    _info "Downloading tarball..."
    curl -fsSL "${OCTCLAW_REPO%.*}/archive/refs/heads/main.tar.gz" | tar xz -C "$tmp_dir"
    mv "$tmp_dir"/octclaw-main "$tmp_dir/octclaw"
  fi

  # Install
  local install_dir="${HOME}/.octclaw"
  mkdir -p "$install_dir"
  cp -r "$tmp_dir/octclaw/lib" "$install_dir/"
  cp "$tmp_dir/octclaw/cli.sh" "$install_dir/"
  cp "$tmp_dir/octclaw/oct" "$install_dir/"
  cp "$tmp_dir/octclaw/.env.example" "$install_dir/.env"
  
  local bin_dir="${HOME}/.local/bin"
  mkdir -p "$bin_dir"
  cp "$tmp_dir/octclaw/oct" "$bin_dir/"
  # Fix OCT_ROOT to point to install_dir instead of bin_dir
  sed -i.bak 's|^OCT_ROOT=.*|OCT_ROOT="${HOME}/.octclaw"|' "$bin_dir/oct"
  chmod +x "$bin_dir/oct"
  chmod +x "$install_dir/oct"
  
  # Init config - Auto-detect API provider
  if [[ ! -f "$install_dir/config.json" ]]; then
    local config
    if [[ -n "${DEEPSEEK_API_KEY:-}" ]]; then
      config='{"model":"deepseek-chat","api_base":"https://api.deepseek.com"}'
      _info "检测到DEEPSEEK_API_KEY，使用DeepSeek"
    elif [[ -n "${OPENAI_API_KEY:-}" ]]; then
      config='{"model":"gpt-4o","api_base":"https://api.openai.com/v1"}'
      _info "检测到OPENAI_API_KEY，使用OpenAI GPT-4o"
    else
      config='{"model":"deepseek-chat","api_base":"https://api.deepseek.com"}'
      _info "未检测到API密钥，已设置DeepSeek作为默认"
      _info "配置OpenAI: export OPENAI_API_KEY='sk-xxx'"
      _info "或配置DeepSeek: export DEEPSEEK_API_KEY='sk-xxx'"
    fi
    printf "$config" > "$install_dir/config.json"
  fi

  # Add to PATH if needed
  if [[ ":$PATH:" != *":${bin_dir}:"* ]]; then
    _info "Add to PATH: export PATH=\"${bin_dir}:\$PATH\""
  fi

  _info "Done! Run: oct -h"
}

main "$@"
