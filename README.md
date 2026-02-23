# scar-cc (스까-cc)

Claude Code 멀티 프로필 매니저. 하나의 `source`로 다양한 Claude Code 세션 프로필을 조합해서 쓸 수 있다.

## 지원 프로필

| 프로필 | 설명 |
|---|---|
| `cc` | 바닐라 Claude Code |
| `cc-omc` | [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) 멀티에이전트 오케스트레이션 |
| `cc-moai` | [moai-adk](https://github.com/moai-adk) 프로젝트 로컬 |
| `cc-spec` | [spec-kit](https://github.com/hreid3/spec-kit) 스펙 기반 개발 |
| `cc-omc-spec` | OMC + spec-kit 조합 |
| `cc-moai-spec` | moai + spec-kit 조합 |

### 변형 접두사

각 베이스 프로필에 플래그를 조합할 수 있다:

| 접두사 | 플래그 | 예시 |
|---|---|---|
| `ccy-` | `--dangerously-skip-permissions` | `ccy-omc`, `ccy-spec` |
| `ccc-` | `--chrome` | `ccc-omc`, `ccc-spec` |
| `ccyc-` | 둘 다 | `ccyc-omc-spec` |

총 **24개** 조합이 자동 생성된다.

## 설치

```bash
git clone https://github.com/gtpgg1013/scar-cc.git ~/.scar-cc
```

`.zshrc`에 추가:

```bash
source "$HOME/.scar-cc/scar-cc.zsh"
```

### 의존성 (선택)

- [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) — `cc-omc` 프로필용
- [spec-kit](https://github.com/hreid3/spec-kit) (`pip install specify-cli`) — `cc-spec` 프로필용
- [moai-adk](https://github.com/moai-adk) — `cc-moai` 프로필용

## 사용법

### 기본

```bash
cc                # 바닐라 Claude Code
cc-omc            # OMC 에이전트 오케스트레이션
cc-spec           # spec-kit 워크플로우 (자동 안내 시작)
cc-omc-spec       # OMC + spec-kit
ccyc-omc-spec     # OMC + spec-kit + dsp + chrome
```

### spec-kit 워크플로우

프로젝트에서 스펙 기반 개발을 시작하려면:

```bash
# 1. 프로젝트 초기화
cc-init-spec

# 2. 세션 시작 (자동으로 워크플로우 안내)
cc-spec

# 또는 바로 설명하기
cc-spec "실시간 채팅 앱 만들어줘"
```

세션 안에서 슬래시 커맨드로 단계별 진행:

```
/speckit.constitution  → 프로젝트 원칙 정의 (최초 1회)
/speckit.specify       → 기능 명세 작성
/speckit.clarify       → 모호한 부분 질문으로 해소 (선택)
/speckit.plan          → 기술 설계 산출물 생성
/speckit.checklist     → 요구사항 품질 체크리스트 (선택)
/speckit.tasks         → 구현 작업 목록 생성
/speckit.analyze       → 산출물 일관성 검증 (선택)
/speckit.implement     → 작업 실행
```

### 유틸리티

```bash
cc-profile        # 사용 가능한 프로필 목록 출력
cc-update         # moai + spec-kit + OMC 프롬프트 업데이트
cc-init-moai      # 현재 프로젝트에 moai-adk 초기화
cc-init-spec      # 현재 프로젝트에 spec-kit 초기화
```

## 구조

```
scar-cc/
├── scar-cc.zsh                    # source할 메인 스크립트
├── profiles/
│   ├── omc/
│   │   └── system-prompt.md       # OMC 시스템 프롬프트
│   └── spec/
│       └── system-prompt.md       # spec-kit 워크플로우 프롬프트
└── README.md
```

## 동작 원리

`--append-system-prompt`로 프로필별 시스템 프롬프트를 세션에 주입한다.
글로벌 `CLAUDE.md`는 건드리지 않으며, 프로필 조합은 zsh 함수 래핑으로 구현된다.

```
cc-omc-spec "작업"
  → cc-omc --append-system-prompt <spec프롬프트> "작업"
    → claude --append-system-prompt <omc프롬프트> --append-system-prompt <spec프롬프트> "작업"
```

## License

MIT
