die()  { printf '\033[31merror:\033[0m %s\n' "$*" >&2; exit 1; }
info() { printf '\033[36m[info]\033[0m %s\n' "$*" >&2; }
warn() { printf '\033[33m[warn]\033[0m %s\n' "$*" >&2; }
debug() { [[ "${OCTCLAW_DEBUG:-}" == "1" ]] && printf '\033[90m[debug]\033[0m %s\n' "$*" >&2 || true; }

require_cmd() {
  command -v "$1" &>/dev/null || die "$1 is required but not found"
}
