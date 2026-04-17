# cc-configs

> levx의 Claude Code 전역 설정을 어디서든 한 번에 설치하세요.

`~/.claude`에 CLAUDE.md, rules, hooks, settings를 대화형으로 배포하는 Claude Code 플러그인입니다.

**[English →](./README.md)**

---

## 설치

### 플러그인으로 설치 (권장)

Claude Code에서 실행:

```
/plugin marketplace add https://github.com/levx-me/cc-configs
/plugin install cc-configs@levx-me
/cc-configs:install
```

컴포넌트를 선택하면 `~/.claude`에 자동으로 배포됩니다.

---

### 수동 설치

```bash
git clone https://github.com/levx-me/cc-configs
cd cc-configs
./scripts/install.sh
```

선택적 설치:

```bash
./scripts/install.sh --components=claude,rules
./scripts/install.sh --components=hooks --hooks=auto-allow,git-guard
```

---

## 포함 내용

### CLAUDE.md
Claude Code의 전역 동작 지침입니다. [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) 오케스트레이션 블록이 포함되어 있어 멀티 에이전트 워크플로우를 자동으로 활성화합니다.

### rules/
프로젝트마다 자동으로 주입되는 규칙 파일입니다.

| 파일 | 내용 |
|------|------|
| `cli-checklist.md` | CLI 도구 빌드 체크리스트 |
| `readme-guide.md` | README 작성 가이드 |
| `refactor-safety.md` | 리팩터링 안전 규칙 |
| `wiki.md` | 위키 작성 가이드 |

### hooks/
`PreToolUse` 이벤트에 자동으로 실행되는 bash 훅입니다.

| 훅 | 동작 |
|----|------|
| `bash-auto-allow` | 위험 패턴(rm -rf, sudo, force push 등) 제외한 Bash 명령 자동 허용 |
| `git-guard` | `git commit` / `git push` 전 안전 체크리스트 주입 |
| `rtk-rewrite` | RTK 설치 시 명령어를 자동으로 토큰 절약 프록시로 재작성 |

### settings.json
`settings.json.template`의 `{{CLAUDE_HOME}}`을 실제 경로로 치환 후 기존 설정과 스마트 머지합니다. `enabledPlugins`, `statusLine` 등 플러그인 관리 필드는 보존됩니다.

---

## 업데이트

다른 머신이나 설정 변경 후:

```bash
cd cc-configs
git pull
./scripts/install.sh
```

또는 플러그인이 설치된 경우:

```
/cc-configs:install
```

---

## 로컬 변경 사항 동기화

`~/.claude`에서 수정한 내용을 repo로 역동기화:

```bash
./sync.sh
git add -A && git commit -m "chore: sync local changes"
git push
```

---

## 의존 도구 (선택)

| 도구 | 용도 | 설치 |
|------|------|------|
| [oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) | 멀티 에이전트 오케스트레이션 | `claude plugin install oh-my-claudecode@omc` |
| [RTK](https://github.com/rtk-ai/rtk) | 토큰 절약 CLI 프록시 (60~90% 절감) | `cargo install rtk` |
| [jq](https://jqlang.github.io/jq/) | 훅 스크립트 의존성 | `brew install jq` |

---

## 주의사항

- 시크릿(`.mcp.json`, `.env` 등)은 절대 커밋하지 마세요.
- `enabledPlugins`, `extraKnownMarketplaces`, `statusLine`은 플러그인 시스템이 관리합니다 — 설치 시 자동 보존됩니다.

---

## License

MIT
