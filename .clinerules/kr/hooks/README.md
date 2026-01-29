# Cline Hooks 문서

## 개요

Cline hooks를 사용하면 에이전트 워크플로우의 특정 시점에 사용자 정의 스크립트를 실행할 수 있습니다. Hooks는 다음 위치에 배치할 수 있습니다:
- **전역 hooks 디렉토리**: `~/Documents/Cline/Hooks/` (모든 작업 공간에 적용)
- **작업 공간 hooks 디렉토리**: `.clinerules/hooks/` (저장소가 속한 작업 공간에 적용)

Hooks는 활성화되면 자동으로 실행됩니다.

## Hooks 활성화

1. VSCode에서 Cline 설정 열기
2. Feature Settings 섹션으로 이동
3. "Enable Hooks" 체크박스 선택
4. Hooks는 실행 가능한 파일이어야 합니다 (Unix/Linux/macOS에서는 `chmod +x hookname` 사용)

## 사용 가능한 Hooks

### TaskStart Hook
- **실행 시점**: 새 작업이 시작될 때 (재개 시에는 실행되지 않음)
- **목적**: 작업 컨텍스트 초기화, 작업 요구사항 검증, 환경 설정
- **전역 위치**: `~/Documents/Cline/Hooks/TaskStart`
- **작업 공간 위치**: `.clinerules/hooks/TaskStart`

### TaskResume Hook
- **실행 시점**: 기존 작업이 재개될 때 (사용자가 재개 버튼을 클릭한 후)
- **목적**: 재개된 작업 상태 검증, 컨텍스트 복원, 마지막 실행 이후 변경 사항 확인
- **전역 위치**: `~/Documents/Cline/Hooks/TaskResume`
- **작업 공간 위치**: `.clinerules/hooks/TaskResume`

### TaskCancel Hook
- **실행 시점**: 작업이 취소되거나 사용자가 hook을 중단할 때
- **목적**: 리소스 정리, 취소 로깅, 상태 저장
- **전역 위치**: `~/Documents/Cline/Hooks/TaskCancel`
- **작업 공간 위치**: `.clinerules/hooks/TaskCancel`
- **참고**: 이 hook은 취소할 수 없습니다

### UserPromptSubmit Hook
- **실행 시점**: 사용자가 프롬프트/메시지를 제출할 때
- **목적**: 사용자 입력 검증, 프롬프트 전처리, 사용자 메시지에 컨텍스트 추가
- **전역 위치**: `~/Documents/Cline/Hooks/UserPromptSubmit`
- **작업 공간 위치**: `.clinerules/hooks/UserPromptSubmit`

### PreToolUse Hook
- **실행 시점**: 도구가 실행되기 전
- **목적**: 매개변수 검증, 실행 차단 또는 컨텍스트 추가
- **전역 위치**: `~/Documents/Cline/Hooks/PreToolUse`
- **작업 공간 위치**: `.clinerules/hooks/PreToolUse`

### PostToolUse Hook
- **실행 시점**: 도구가 완료된 후
- **목적**: 결과 관찰, 패턴 추적 또는 컨텍스트 추가
- **전역 위치**: `~/Documents/Cline/Hooks/PostToolUse`
- **작업 공간 위치**: `.clinerules/hooks/PostToolUse`

## 크로스 플랫폼 Hook 형식

Cline은 모든 플랫폼에서 일관되게 작동하는 git 스타일 접근 방식을 사용합니다:

### Hook 파일 (모든 플랫폼)
- **파일 확장자 없음**: Hooks는 정확히 `PreToolUse` 또는 `PostToolUse`로 명명됩니다 (`.bat`, `.cmd`, `.sh` 등 없음)
- **Shebang 필수**: 첫 번째 줄은 shebang이어야 합니다 (예: `#!/usr/bin/env bash` 또는 `#!/usr/bin/env node`)
- **Unix에서 실행 가능**: Unix/Linux/macOS에서는 hooks가 실행 가능해야 합니다: `chmod +x PreToolUse`
- **Windows**: 현재 지원되지 않습니다

### Hook 입력/출력

#### 입력 (stdin을 통한 JSON)

모든 hooks는 다음을 받습니다:
```json
{
  "clineVersion": "string",
  "hookName": "TaskStart" | "TaskResume" | "TaskCancel" | "UserPromptSubmit" | "PreToolUse" | "PostToolUse",
  "timestamp": "string",
  "taskId": "string",
  "workspaceRoots": ["string"],
  "userId": "string"
}
```

#### 출력 (stdout을 통한 JSON)

모든 hooks는 다음을 반환해야 합니다:
```json
{
  "cancel": boolean,                   // 필수: 계속하려면 false, 실행을 차단하려면 true
  "contextModification": "string",     // 선택: 향후 AI 결정을 위한 컨텍스트
  "errorMessage": "string"             // 선택: 차단 시 오류 세부 정보
}
```

## Hook 실행 제한

- **타임아웃**: Hooks는 30초 이내에 완료되어야 합니다
- **컨텍스트 크기**: 컨텍스트 수정은 50KB로 제한됩니다
- **오류 처리**: 예상된 오류는 조용히 처리되며, 예상치 못한 파일 시스템 오류는 전파됩니다

## 일반적인 사용 사례

### 1. 검증 - 잘못된 작업 차단

```bash
#!/usr/bin/env bash
input=$(cat)
tool_name=$(echo "$input" | jq -r '.preToolUse.toolName')
path=$(echo "$input" | jq -r '.preToolUse.parameters.path // ""')

if [[ "$tool_name" == "write_to_file" && "$path" == *.js ]]; then
  cat <<EOF
{
  "cancel": true,
  "errorMessage": "TypeScript 프로젝트에서 .js 파일을 생성할 수 없습니다",
  "contextModification": ".ts/.tsx 확장자만 사용하세요"
}
EOF
  exit 0
fi

echo '{"cancel": false}'
```

### 2. 컨텍스트 구축 - 작업에서 학습

```bash
#!/usr/bin/env bash
input=$(cat)
tool_name=$(echo "$input" | jq -r '.postToolUse.toolName')
success=$(echo "$input" | jq -r '.postToolUse.success')
path=$(echo "$input" | jq -r '.postToolUse.parameters.path // ""')

if [[ "$tool_name" == "write_to_file" && "$success" == "true" ]]; then
  cat <<EOF
{
  "cancel": false,
  "contextModification": "'$path'를 생성했습니다. 향후 작업에서 이 파일의 패턴과 일관성을 유지하세요."
}
EOF
else
  echo '{"cancel": false}'
fi
```

## 전역 vs 작업 공간 Hooks

### 전역 Hooks
- **위치**: `~/Documents/Cline/Hooks/` (macOS/Linux)
- **범위**: 모든 작업 공간 및 프로젝트에 적용
- **사용 사례**: 조직 전체 정책, 개인 선호도, 범용 검증

### 작업 공간 Hooks
- **위치**: 각 작업 공간 루트의 `.clinerules/hooks/`
- **범위**: 특정 작업 공간에만 적용
- **사용 사례**: 프로젝트별 규칙, 팀 규약, 저장소 요구사항

### Hook 실행

여러 hooks가 존재하는 경우 (전역 및/또는 작업 공간):
- 주어진 단계의 모든 hooks는 `Promise.all`을 사용하여 **동시에** 실행됩니다
- **실행 순서는 보장되지 않습니다** - hooks는 병렬로 실행됩니다
- 모든 hooks가 실행을 허용하면 (`cancel: false`) 도구가 진행됩니다
- 어떤 hook이라도 차단하면 (`cancel: true`) 실행이 차단됩니다

## 문제 해결

### Hook이 실행되지 않음
- "Enable Hooks" 설정이 선택되어 있는지 확인
- hook 파일이 실행 가능한지 확인 (`chmod +x hookname`)
- hook 파일에 구문 오류가 없는지 확인
- VSCode의 출력 패널(Cline 채널)에서 오류 확인

### Hook 타임아웃
- hook 스크립트의 복잡성 줄이기
- 비용이 많이 드는 작업 피하기 (네트워크 호출, 무거운 계산)
- 복잡한 로직을 백그라운드 프로세스로 이동 고려

## 보안 고려사항

- Hooks는 VSCode와 동일한 권한으로 실행됩니다
- 신뢰할 수 없는 소스의 hooks에 주의하세요
- hooks를 활성화하기 전에 스크립트를 검토하세요
- 민감한 hook 로직을 커밋하지 않도록 `.gitignore` 사용 고려

## 모범 사례

1. **hooks를 빠르게 유지** - 100ms 미만의 실행 시간을 목표로 하세요
2. **컨텍스트를 실행 가능하게 만들기** - AI가 무엇을 해야 하는지 구체적으로 명시하세요
3. **오류를 우아하게 처리** - 항상 유효한 JSON을 반환하세요
4. **디버깅을 위한 로그** - 문제 해결을 위해 hook 실행 로그를 유지하세요
5. **점진적으로 테스트** - 간단한 hooks로 시작하여 복잡성을 추가하세요
