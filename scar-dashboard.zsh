# === scar-dashboard: Project Overview ===
#
# ~/DEV/ 프로젝트 현황을 한눈에
#
# 사용법:
#   cc-dash            전체 프로젝트 대시보드

SCAR_DEV_DIR="${SCAR_DEV_DIR:-$HOME/DEV}"

cc-dash() {
  # 리스닝 포트 한 번만 조회
  local listening=$(lsof -iTCP -sTCP:LISTEN -P -n 2>/dev/null | awk '{split($9,a,":"); print a[length(a)]}' | sort -u)
  local current=$(_scar_project_name 2>/dev/null)

  # 헤더
  echo ""
  printf "  \033[1;37mscar-cc dashboard\033[0m%*s\n" 30 "$(date +%Y-%m-%d)"
  echo ""

  # 컬럼 헤더
  printf "  \033[1m%-30s %-14s %-16s %s\033[0m\n" \
    "PROJECT" "TOOLS" "PORTS" "GIT"
  printf "  %.30s %.14s %.16s %.14s\n" \
    "------------------------------" "--------------" "----------------" "--------------"

  for dir in "$SCAR_DEV_DIR"/*/; do
    [[ -d "$dir" ]] || continue
    local name=$(basename "$dir")

    # ── Tools 감지 ──
    local tools=""
    if [[ -f "$dir/.claude/settings.json" ]]; then
      local _settings="$dir/.claude/settings.json"
      command grep -qF "oh-my-claudecode" "$_settings" 2>/dev/null && tools+="omc "
      command grep -qF "show-me-the-prd" "$_settings" 2>/dev/null && tools+="prd "
    fi
    [[ -d "$dir/.specify" ]] && tools+="spec "
    [[ -f "$dir/.claude/.forge" ]] && tools+="forge "
    [[ -d "$dir/.moai" ]] && tools+="moai "
    tools="${tools% }"
    [[ -z "$tools" ]] && tools="-"

    # ── Ports ──
    local port_str="-"
    if [[ -f "$SCAR_PORTS_REGISTRY" ]]; then
      local offset=$(_scar_registry_lookup "$name")
      if [[ -n "$offset" ]]; then
        local front=$((3000+offset)) back=$((4000+offset))
        local f_up=" " b_up=" "
        echo "$listening" | command grep -qx "$front" && f_up="*"
        echo "$listening" | command grep -qx "$back"  && b_up="*"
        port_str="${f_up}F:${front} ${b_up}B:${back}"
      fi
    fi

    # ── Git ──
    local git_info="-"
    if [[ -d "$dir/.git" || -f "$dir/.git" ]]; then
      local branch=$(git -C "$dir" branch --show-current 2>/dev/null)
      [[ -z "$branch" ]] && branch="detached"
      local dirty=$(git -C "$dir" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
      if [[ "$dirty" -eq 0 ]]; then
        git_info="${branch} \033[32mok\033[0m"
      else
        git_info="${branch} \033[33m~${dirty}\033[0m"
      fi
    fi

    # ── 출력 ──
    if [[ "$name" == "$current" ]]; then
      printf "  \033[36m> %-28s\033[0m %-14s %-16s %b\n" \
        "$name" "$tools" "$port_str" "$git_info"
    else
      printf "    %-28s %-14s %-16s %b\n" \
        "$name" "$tools" "$port_str" "$git_info"
    fi
  done

  echo ""
  printf "  \033[90m* = port listening\033[0m\n"
  echo ""
}

# === End scar-dashboard ===
