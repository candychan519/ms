# Recording Rules

이 문서는 앞으로 필요한 기록을 남기는 규칙입니다.

## Rule 1: Documentation Is Part Of Done

작업 결과가 다음 중 하나에 해당하면, 코드나 설정 작업만 끝내지 말고 문서도 갱신합니다.

- 환경 정보가 바뀜
- 도구가 추가, 삭제, 업데이트됨
- 설치 방법이 바뀜
- 공유 폴더나 경로가 바뀜
- AutoJs6 권한이나 실행 방법이 바뀜
- 새 스크립트가 추가됨
- 테스트 결과가 새로 확인됨
- 반복해서 겪은 문제와 해결법이 생김
- 사용자가 작업 선호나 운영 원칙을 정함

## Rule 2: Stable Knowledge Goes To `docs/`

반복해서 참고할 안정적인 정보는 `docs/`에 기록합니다.

- Environment: `docs/ENVIRONMENT.md`
- Tools and installation: `docs/TOOLS_AND_INSTALLATION.md`
- Usage and sharing: `docs/USAGE_AND_SHARING.md`
- Work and development method: `docs/WORK_AND_DEVELOPMENT_METHOD.md`
- Recording rules: `docs/RECORDING_RULES.md`

## Rule 3: New Findings Go To `logs/LEARNINGS.md`

작업 중 새로 알게 된 사실, 시행착오, 결정, 검증 결과는 `logs/LEARNINGS.md`에 날짜별로 추가합니다.

Use this format:

```text
## YYYY-MM-DD - Short Title

Context:
Finding:
Evidence:
Decision:
Next action:
```

## Rule 4: Record Evidence, Not Just Conclusions

가능하면 결론만 쓰지 말고 근거를 같이 남깁니다.

Examples:

- Command used
- File path
- Version number
- Screenshot path
- Observed output
- Confirmed UI state

## Rule 5: Keep Secrets Out

문서와 로그에 다음을 기록하지 않습니다.

- Passwords
- Tokens
- API keys
- Account recovery codes
- Private personal data

## Rule 6: Separate Current State From History

- Current state: `docs/`
- Historical findings and changes: `logs/LEARNINGS.md`
- Source scripts: `scripts/`
- Temporary installers or large external files: `downloads/`

## Rule 7: Learning Loop

Every meaningful task should follow this loop:

```text
Observe -> Test -> Record -> Reuse -> Refine
```

- Observe: inspect actual environment or screen.
- Test: run the smallest useful test.
- Record: write the result in the right document.
- Reuse: use recorded knowledge in the next task.
- Refine: update docs when old knowledge becomes stale.

## Rule 8: User Preferences

사용자가 앞으로의 작업 방식에 대한 선호를 말하면 프로젝트 문서에 기록합니다.

Current preference:

- Android apps in LDPlayer should be installed and updated through Google Play by default.
- If Google Play asks for login, pause and let the user log in.
- Do not switch to third-party APK/XAPK sources unless the user explicitly approves it.
