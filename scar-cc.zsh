# === scar-cc: Claude Code Multi-Profile ===
# source this file in your .zshrc:
#   source "$HOME/path/to/scar-cc/scar-cc.zsh"

SCAR_CC_DIR="${SCAR_CC_DIR:-$(cd "$(dirname "${(%):-%x}")" && pwd)}"

# 바닐라
alias cc='claude'

# oh-my-claudecode (OMC 오케스트레이션 프롬프트 세션 주입, 글로벌 CLAUDE.md 안 건드림)
cc-omc() {
  command claude \
    --append-system-prompt "$(cat "$SCAR_CC_DIR/profiles/omc/system-prompt.md")" \
    "$@"
}

# moai-adk (프로젝트 로컬)
cc-moai() {
  if [[ ! -d ".moai" ]]; then
    echo "⚠ moai-adk 미초기화. 'cc-init-moai' 먼저 실행하세요."
    return 1
  fi
  command claude "$@"
}

# spec-kit (프로젝트 로컬)
cc-spec() {
  if [[ ! -d ".specify" ]]; then
    echo "⚠ spec-kit 미초기화. 'cc-init-spec' 먼저 실행하세요."
    return 1
  fi
  if [[ $# -eq 0 ]]; then
    command claude \
      --append-system-prompt "$(cat "$SCAR_CC_DIR/profiles/spec/system-prompt.md")" \
      "시작"
  else
    command claude \
      --append-system-prompt "$(cat "$SCAR_CC_DIR/profiles/spec/system-prompt.md")" \
      "$@"
  fi
}

# OMC + spec-kit
cc-omc-spec() {
  if [[ ! -d ".specify" ]]; then
    echo "⚠ spec-kit 미초기화. 'cc-init-spec' 먼저 실행하세요."
    return 1
  fi
  if [[ $# -eq 0 ]]; then
    cc-omc \
      --append-system-prompt "$(cat "$SCAR_CC_DIR/profiles/spec/system-prompt.md")" \
      "시작"
  else
    cc-omc \
      --append-system-prompt "$(cat "$SCAR_CC_DIR/profiles/spec/system-prompt.md")" \
      "$@"
  fi
}

# moai + spec-kit
cc-moai-spec() {
  if [[ ! -d ".moai" ]]; then
    echo "⚠ moai-adk 미초기화. 'cc-init-moai' 먼저 실행하세요."
    return 1
  fi
  if [[ ! -d ".specify" ]]; then
    echo "⚠ spec-kit 미초기화. 'cc-init-spec' 먼저 실행하세요."
    return 1
  fi
  if [[ $# -eq 0 ]]; then
    command claude \
      --append-system-prompt "$(cat "$SCAR_CC_DIR/profiles/spec/system-prompt.md")" \
      "시작"
  else
    command claude \
      --append-system-prompt "$(cat "$SCAR_CC_DIR/profiles/spec/system-prompt.md")" \
      "$@"
  fi
}

# claude-forge (프로젝트 로컬)
cc-forge() {
  if [[ ! -f ".claude/.forge" ]]; then
    echo "⚠ claude-forge 미초기화. 'cc-init-forge' 먼저 실행하세요."
    return 1
  fi
  command claude "$@"
}

# OMC + forge
cc-omc-forge() {
  if [[ ! -f ".claude/.forge" ]]; then
    echo "⚠ claude-forge 미초기화. 'cc-init-forge' 먼저 실행하세요."
    return 1
  fi
  cc-omc "$@"
}

# 프로젝트 초기화 헬퍼
cc-init-moai() { moai init "${1:-.}"; }
_SCAR_FORGE_REPO="https://github.com/sangrokjung/claude-forge.git"
_SCAR_FORGE_CACHE="${SCAR_CC_DIR}/.cache/claude-forge"

cc-init-forge() {
  # 캐시에 forge 레포 클론 (최초 1회)
  if [[ ! -d "$_SCAR_FORGE_CACHE" ]]; then
    echo "📦 claude-forge 다운로드 중..."
    git clone --depth 1 "$_SCAR_FORGE_REPO" "$_SCAR_FORGE_CACHE" || return 1
  fi

  # 프로젝트 .claude/ 디렉토리 생성
  mkdir -p .claude/commands .claude/agents .claude/rules

  # forge 파일 복사 (프로젝트 로컬)
  cp "$_SCAR_FORGE_CACHE"/commands/*.md .claude/commands/ 2>/dev/null
  cp "$_SCAR_FORGE_CACHE"/agents/*.md .claude/agents/ 2>/dev/null
  cp "$_SCAR_FORGE_CACHE"/rules/*.md .claude/rules/ 2>/dev/null

  # 마커 파일 생성
  echo "installed=$(date -u +%Y-%m-%dT%H:%M:%SZ)" > .claude/.forge

  echo "" && \
  echo "✨ claude-forge 준비 완료!" && \
  echo "" && \
  echo "📋 주요 커맨드 (세션 안에서 슬래시 커맨드 사용):" && \
  echo "" && \
  echo "  /plan              → AI 구현 계획 수립" && \
  echo "  /tdd               → 테스트 주도 개발 (RED→GREEN→IMPROVE)" && \
  echo "  /code-review       → 코드 리뷰 (보안 + 품질)" && \
  echo "  /auto              → 원버튼 자동화 (plan→tdd→review→verify→commit)" && \
  echo "  /handoff-verify    → 빌드/린트/테스트 자동 검증" && \
  echo "  /guide             → 3분 온보딩 투어" && \
  echo "" && \
  echo "🚀 시작하기:" && \
  echo "  cc-forge           → forge 기능만 사용" && \
  echo "  cc-omc-forge       → OMC + forge 조합"
}

cc-update-forge() {
  if [[ ! -d "$_SCAR_FORGE_CACHE" ]]; then
    echo "⚠ forge 캐시 없음. 'cc-init-forge' 먼저 실행하세요."
    return 1
  fi
  echo "Updating claude-forge cache..."
  git -C "$_SCAR_FORGE_CACHE" pull --ff-only
  echo "Done. 프로젝트에 반영하려면 cc-init-forge 를 다시 실행하세요."
}

cc-init-spec() {
  specify init "${1:-.}" --ai claude && \
  echo "" && \
  echo "✨ spec-kit 준비 완료!" && \
  echo "" && \
  echo "📋 워크플로우 (cc-spec 세션 안에서 슬래시 커맨드 사용):" && \
  echo "" && \
  echo "  1. /speckit.constitution  → 프로젝트 원칙·제약 정의 (최초 1회)" && \
  echo "  2. /speckit.specify       → 기능 명세 작성 (\"채팅 기능 만들어줘\")" && \
  echo "  3. /speckit.plan          → 기술 설계 (데이터 모델, 계약 등)" && \
  echo "  4. /speckit.tasks         → 구현 작업 목록 생성" && \
  echo "  5. /speckit.implement     → 작업 실행 (코드 구현)" && \
  echo "" && \
  echo "🚀 시작하기:" && \
  echo "  cc-spec                   → 안내에 따라 단계별 진행" && \
  echo "  cc-spec \"채팅 앱 만들어줘\" → 바로 명세 시작" && \
  echo "  cc-omc-spec               → OMC 에이전트와 함께 진행"
}

# 업데이트
cc-update() {
  echo "Updating moai-adk..."
  uv tool upgrade moai-adk
  echo ""
  echo "Updating spec-kit..."
  uv tool upgrade specify-cli
  echo ""
  echo "Updating OMC system prompt..."
  curl -fsSL "https://raw.githubusercontent.com/Yeachan-Heo/oh-my-claudecode/main/docs/CLAUDE.md" \
    -o "$SCAR_CC_DIR/profiles/omc/system-prompt.md" \
    && echo "OMC system prompt updated." \
    || echo "Failed to update OMC system prompt."
  echo ""
  echo "Done. OMC 플러그인은 Claude Code 내에서 /plugin update oh-my-claudecode 으로 업데이트하세요."
}

# y/c/yc 변형 자동 생성 (y=dsp, c=chrome, yc=둘다)
# 베이스 함수들을 감싸서 플래그만 추가
_cc_bases=( "::command claude" "-omc::cc-omc" "-moai::cc-moai" "-spec::cc-spec" "-forge::cc-forge" "-omc-spec::cc-omc-spec" "-moai-spec::cc-moai-spec" "-omc-forge::cc-omc-forge" )
for _entry in "${_cc_bases[@]}"; do
  _suffix="${_entry%%::*}"
  _base="${_entry##*::}"
  eval "ccy${_suffix}() { ${_base} --dangerously-skip-permissions \"\$@\"; }"
  eval "ccc${_suffix}() { ${_base} --chrome \"\$@\"; }"
  eval "ccyc${_suffix}() { ${_base} --dangerously-skip-permissions --chrome \"\$@\"; }"
done
unset _cc_bases _entry _suffix _base

# 프로파일 목록
cc-profile() {
  echo "Available Claude Code profiles:"
  echo ""
  echo "  Base:"
  echo "    cc             → 바닐라 Claude Code"
  echo "    cc-omc         → oh-my-claudecode"
  echo "    cc-moai        → moai-adk (프로젝트 로컬)"
  echo "    cc-spec        → spec-kit (프로젝트 로컬)"
  echo "    cc-forge       → claude-forge (프로젝트 로컬)"
  echo "    cc-omc-spec    → OMC + spec-kit"
  echo "    cc-moai-spec   → moai + spec-kit"
  echo "    cc-omc-forge   → OMC + forge"
  echo ""
  echo "  Variants (y=dsp, c=chrome, yc=둘다):"
  echo "    ccy[-profile]  → + dangerously-skip-permissions"
  echo "    ccc[-profile]  → + chrome"
  echo "    ccyc[-profile] → + dsp + chrome"
  echo "    예: ccy-omc, ccc-moai, ccyc-omc-spec ..."
  echo ""
  echo "  Project init:"
  echo "    cc-init-moai   → 현재 프로젝트에 moai-adk 초기화"
  echo "    cc-init-spec   → 현재 프로젝트에 spec-kit 초기화"
  echo "    cc-init-forge  → 현재 프로젝트에 claude-forge 초기화"
  echo ""
  echo "  Utilities:"
  echo "    cc-update        → moai + spec-kit + OMC 프롬프트 업데이트"
  echo "    cc-update-forge  → claude-forge 캐시 업데이트"
  echo "    cc-profile       → 이 목록 출력"
}

# === End scar-cc ===
