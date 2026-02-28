# === scar-dashboard: Project Overview ===
#
# ~/DEV/ 프로젝트 현황을 한눈에
#
# 사용법:
#   cc-dash            전체 프로젝트 대시보드

SCAR_DEV_DIR="${SCAR_DEV_DIR:-$HOME/DEV}"

cc-dash() {
  local mode="${1:-all}"

  # 리스닝 포트 한 번만 조회
  local listening=$(lsof -iTCP -sTCP:LISTEN -P -n 2>/dev/null | awk '{split($9,a,":"); print a[length(a)]}' | sort -u)
  local current=$(_scar_project_name 2>/dev/null)

  # 헤더
  echo ""
  printf "  \033[1;37mscar-cc dashboard\033[0m"
  printf "%*s\n" 35 "$(date +%Y-%m-%d)"
  echo ""

  # 컬럼 헤더
  printf "  \033[1m%-26s %-16s %-18s %s\033[0m\n" \
    "PROJECT" "TOOLS" "PORTS" "GIT"
  printf "  %-26s %-16s %-18s %s\n" \
    "──────────────────────────" "────────────────" "──────────────────" "──────────────"

  for dir in "$SCAR_DEV_DIR"/*/; do
    [[ -d "$dir" ]] || continue
    local name=$(basename "$dir")

    # ── Tools 감지 ──
    local tools=""
    if [[ -f "$dir/.claude/settings.json" ]]; then
      command grep -qF "oh-my-claudecode" "$dir/.claude/settings.json" 2>/dev/null && tools+="omc "
    fi
    [[ -d "$dir/.specify" ]] && tools+="spec "
    [[ -f "$dir/.claude/.forge" ]] && tools+="forge "
    [[ -d "$dir/.moai" ]] && tools+="moai "
    tools="${tools% }"
    [[ -z "$tools" ]] && tools="─"

    # ── Ports ──
    local port_str="─"
    if [[ -f "$SCAR_PORTS_REGISTRY" ]]; then
      local offset=$(_scar_registry_lookup "$name")
      if [[ -n "$offset" ]]; then
        local front=$((3000+offset)) back=$((4000+offset)) db=$((5500+offset))
        local f_dot="·" b_dot="·" d_dot="·"
        echo "$listening" | command grep -qx "$front" && f_dot="●"
        echo "$listening" | command grep -qx "$back"  && b_dot="●"
        echo "$listening" | command grep -qx "$db"    && d_dot="●"
        port_str="${f_dot}F:${front} ${b_dot}B:${back}"
      fi
    fi

    # ── Git ──
    local git_info="─"
    if [[ -d "$dir/.git" || -f "$dir/.git" ]]; then
      local branch=$(git -C "$dir" branch --show-current 2>/dev/null)
      [[ -z "$branch" ]] && branch="detached"
      local dirty=$(git -C "$dir" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
      if [[ "$dirty" -eq 0 ]]; then
        git_info="${branch} \033[32m✓\033[0m"
      else
        git_info="${branch} \033[33m~${dirty}\033[0m"
      fi
    fi

    # ── 출력 ──
    if [[ "$name" == "$current" ]]; then
      printf "  \033[36m▸ %-24s\033[0m %-16s %-18s %b\n" \
        "$name" "$tools" "$port_str" "$git_info"
    else
      printf "    %-24s %-16s %-18s %b\n" \
        "$name" "$tools" "$port_str" "$git_info"
    fi
  done

  echo ""
}

# === End scar-dashboard ===
