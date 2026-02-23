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

# 프로젝트 초기화 헬퍼
cc-init-moai() { moai init "${1:-.}"; }
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
_cc_bases=( "::command claude" "-omc::cc-omc" "-moai::cc-moai" "-spec::cc-spec" "-omc-spec::cc-omc-spec" "-moai-spec::cc-moai-spec" )
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
  echo "    cc-omc-spec    → OMC + spec-kit"
  echo "    cc-moai-spec   → moai + spec-kit"
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
  echo ""
  echo "  Utilities:"
  echo "    cc-update      → moai + spec-kit + OMC 프롬프트 업데이트"
  echo "    cc-profile     → 이 목록 출력"
}

# === End scar-cc ===
