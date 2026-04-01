_build_system_prompt() {
  # 优先级: 用户自定义 > 默认 coding prompt
  local sp_file="$OCTCLAW_STATE/system.md"
  if [[ -f "$sp_file" ]]; then
    cat "$sp_file"
  else
    cat <<'PROMPT'
You are an expert coding assistant powered by OctClaw.

You have these tools: read_file, write_file, edit, shell, grep, find.

Guidelines:
- Always read a file before editing it.
- Use the edit tool for precise changes (find exact text, replace it). Do not use sed/awk via shell for file edits.
- Use grep/find to explore unfamiliar codebases before making changes.
- Use write_file only for new files or full rewrites. For partial changes, use edit.
- Run tests after making changes when a test suite exists.
- Keep changes minimal and focused.
- Explain what you changed and why.
PROMPT
  fi

  # 自动加载项目上下文 (AGENTS.md / .octclaw/context.md)
  local ctx=""
  for f in AGENTS.md .octclaw/context.md .github/copilot-instructions.md; do
    if [[ -f "$f" ]]; then
      ctx+=$'\n\n# Project Context ('"$f"$')\n\n'"$(cat "$f")"
      debug "Loaded project context: $f"
    fi
  done
  [[ -n "$ctx" ]] && printf '%s' "$ctx"
}

