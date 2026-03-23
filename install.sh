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
  cp "$tmp_dir/octclaw/.env.example" "$install_dir/.env"
  
  local bin_dir="${HOME}/.local/bin"
  mkdir -p "$bin_dir"
  cp "$tmp_dir/octclaw/oct" "$bin_dir/"
  chmod +x "$bin_dir/oct"
  
  # Init config
  [[ ! -f "$install_dir/config.json" ]] && printf '{"model":"gpt-4o","api_base":"https://api.openai.com/v1"}' > "$install_dir/config.json"

  # Add to PATH if needed
  if [[ ":$PATH:" != *":${bin_dir}:"* ]]; then
    _info "Add to PATH: export PATH=\"${bin_dir}:\$PATH\""
  fi

  _info "Done! Run: oct -h"
}

main "$@"
