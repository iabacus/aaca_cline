# 일반 개발 가이드

이 파일은 코드베이스에서 효과적으로 작업하기 위한 핵심 지식입니다. 빠른 수정과 몇 시간의 시행착오 및 사람의 개입 사이의 차이를 만드는 미묘하고 명확하지 않은 패턴을 담고 있습니다.

**이 파일에 추가해야 할 때:**
- 사용자가 개입, 수정 또는 안내가 필요했을 때
- 작동시키기 위해 여러 번의 시행착오가 필요했을 때
- 이해하기 위해 많은 파일을 읽어야 하는 것을 발견했을 때
- 예상하지 못한 파일을 변경해야 했을 때
- 예상과 다르게 작동했을 때
- 사용자가 명시적으로 "CLAUDE.md에 추가해줘"라고 요청했을 때

**적극적으로 추가를 제안하세요** - 요청을 기다리지 마세요.

**추가하지 말아야 할 것:** 몇 개의 파일을 읽어서 알 수 있는 것, 명백한 패턴, 표준 관행. 이 파일은 포괄적이 아닌 고신호여야 합니다.

## 기타
- 이것은 VS Code 확장입니다—빌드를 확인하기 전에 `package.json`에서 사용 가능한 스크립트를 확인하세요 (예: `npm run compile`, `npm run build` 아님).
- PR을 생성할 때, 변경 사항이 사용자 대면이고 변경 로그 항목을 보증할 만큼 중요한 경우 `npm run changeset`을 실행하고 패치 변경 세트를 생성하세요. 마이너 또는 메이저 버전 범프는 절대 생성하지 마세요. 사소한 수정, 내부 리팩토링 또는 사용자가 알아차리지 못할 사소한 UI 조정에 대해서는 변경 세트를 건너뛰세요.
- 새로운 기능 플래그를 추가할 때는 이 PR을 참조하세요 https://github.com/cline/cline/pull/7566
- 요청 만들기에 대한 추가 지침: @.clinerules/network.md

## gRPC/Protobuf 통신
확장과 웹뷰는 VS Code 메시지 전달을 통한 gRPC 유사 프로토콜로 통신합니다.

**Proto 파일은 `proto/`에 있습니다** (예: `proto/cline/task.proto`, `proto/cline/ui.proto`)
- 각 기능 도메인에는 자체 `.proto` 파일이 있습니다
- 간단한 데이터의 경우 `proto/cline/common.proto`의 공유 타입을 사용하세요 (`StringRequest`, `Empty`, `Int64Request`)
- 복잡한 데이터의 경우 기능의 `.proto` 파일에 사용자 정의 메시지를 정의하세요
- 명명: 서비스 `PascalCaseService`, RPC `camelCase`, 메시지 `PascalCase`
- 스트리밍 응답의 경우 `stream` 키워드를 사용하세요 (`account.proto`의 `subscribeToAuthCallback` 참조)

**Proto 변경 후 `npm run protos` 실행**—다음 위치에 타입을 생성합니다:
- `src/shared/proto/` - 공유 타입 정의
- `src/generated/grpc-js/` - 서비스 구현
- `src/generated/nice-grpc/` - Promise 기반 클라이언트
- `src/generated/hosts/` - 생성된 핸들러

**새로운 enum 값 추가** (새로운 `ClineSay` 타입과 같은)는 `src/shared/proto-conversions/cline-message.ts`의 변환 매핑 업데이트가 필요합니다

**새로운 RPC 메서드 추가**는 다음이 필요합니다:
- `src/core/controller/<domain>/`의 핸들러
- 생성된 클라이언트를 통한 웹뷰에서의 호출: `UiServiceClient.scrollToSettings(StringRequest.create({ value: "browser" }))`

**예시—`explain-changes` 기능이 수정한 파일:**
- `proto/cline/task.proto` - `ExplainChangesRequest` 메시지 및 `explainChanges` RPC 추가
- `proto/cline/ui.proto` - `ClineSay` enum에 `GENERATE_EXPLANATION = 29` 추가
- `src/shared/ExtensionMessage.ts` - `ClineSayGenerateExplanation` 타입 추가
- `src/shared/proto-conversions/cline-message.ts` - 새로운 say 타입에 대한 매핑 추가
- `src/core/controller/task/explainChanges.ts` - 핸들러 구현
- `webview-ui/src/components/chat/ChatRow.tsx` - UI 렌더링

## 새로운 API 프로바이더 추가
새로운 프로바이더(예: "openai-codex")를 추가할 때, proto 변환 레이어를 세 곳에서 업데이트해야 합니다. 그렇지 않으면 프로바이더가 조용히 Anthropic으로 재설정됩니다:

1. `proto/cline/models.proto` - `ApiProvider` enum에 추가 (예: `OPENAI_CODEX = 40;`)
2. `src/shared/proto-conversions/models/api-configuration-conversion.ts`의 `convertApiProviderToProto()` - 문자열을 proto enum으로 매핑하는 케이스 추가
3. 같은 파일의 `convertProtoToApiProvider()` - proto enum을 문자열로 다시 매핑하는 케이스 추가

**이것이 중요한 이유:** 이것들이 없으면 프로바이더 문자열이 `default` 케이스에 도달하고 `ANTHROPIC`을 반환합니다. 웹뷰, 프로바이더 목록 및 핸들러는 모두 잘 작동하지만, proto 직렬화를 통해 왕복할 때 상태가 조용히 재설정됩니다. 오류가 발생하지 않습니다.

**프로바이더를 추가할 때 업데이트할 다른 파일:**
- `src/shared/api.ts` - `ApiProvider` 유니온 타입에 추가, 모델 정의
- `src/shared/providers/providers.json` - 드롭다운용 프로바이더 목록에 추가
- `src/core/api/index.ts` - `createHandlerForProvider()`에 핸들러 등록
- `webview-ui/src/components/settings/utils/providerUtils.ts` - `getModelsForProvider()` 및 `normalizeApiConfiguration()`에 케이스 추가
- `webview-ui/src/utils/validate.ts` - 검증 케이스 추가
- `webview-ui/src/components/settings/ApiOptions.tsx` - 프로바이더 컴포넌트 렌더링

## Responses API 프로바이더 (OpenAI Codex, OpenAI Native)
OpenAI의 Responses API를 사용하는 프로바이더는 네이티브 도구 호출이 필요합니다. XML 도구는 Responses API와 작동하지 않습니다.

**네이티브 도구 호출이 깨진 증상:**
- 도구가 여러 번 호출됨 (예: `ask_followup_question`이 같은 질문을 두 번 물음)
- 도구 인수가 중복되거나 잘못된 형식임
- 모델이 응답하지만 도구가 인식되지 않음

**확인할 근본 원인:**
1. **`src/utils/model-utils.ts`의 `isNextGenModelProvider()`에서 프로바이더 누락**. 네이티브 변형 매처(예: `native-gpt-5/config.ts`)가 이 함수를 호출합니다. 프로바이더가 목록에 없으면 매처가 false를 반환하고 XML 도구로 폴백합니다.

2. **모델 정보(`src/shared/api.ts`)에서 `apiFormat: ApiFormat.OPENAI_RESPONSES` 누락**. 이 속성은 모델이 네이티브 도구 호출을 필요로 한다는 신호입니다. `src/core/task/index.ts`의 작업 러너가 이것을 확인하고 사용자 설정에 관계없이 `enableNativeToolCalls: true`를 강제합니다.

**새로운 Responses API 프로바이더를 추가할 때:**
1. `src/utils/model-utils.ts`의 `isNextGenModelProvider()` 목록에 프로바이더 추가
2. Responses API를 사용하는 모든 모델에 `apiFormat: ApiFormat.OPENAI_RESPONSES` 설정
3. 변형 매처와 작업 러너가 나머지를 자동으로 처리합니다

## 시스템 프롬프트에 도구 추가
이것은 까다롭습니다—여러 프롬프트 변형과 구성이 있습니다. **항상 기존의 유사한 도구를 먼저 검색하고 그 패턴을 따르세요.** 구현하기 전에 프롬프트 정의 → 변형 구성 → 핸들러 → UI의 전체 체인을 살펴보세요.

1. **`src/shared/tools.ts`의 `ClineDefaultTool` enum에 추가**
2. **`src/core/prompts/system-prompt/tools/`의 도구 정의** (예: `generate_explanation.ts`와 같은 파일 생성)
   - 각 `ModelFamily`에 대한 변형 정의 (generic, next-gen, xs 등)
   - 변형 배열 내보내기 (예: `export const my_tool_variants = [GENERIC, NATIVE_NEXT_GEN, XS]`)
   - **폴백 동작**: 모델 패밀리에 대한 변형이 정의되지 않은 경우 `ClineToolSet.getToolByNameWithFallback()`이 자동으로 GENERIC으로 폴백합니다. 따라서 도구가 모델별 동작이 필요하지 않는 한 `[GENERIC]`만 내보내면 됩니다.
3. **`src/core/prompts/system-prompt/tools/init.ts`에 등록** - `allToolVariants`로 가져오고 스프레드
4. **변형 구성에 추가** - 각 모델 패밀리에는 `src/core/prompts/system-prompt/variants/*/config.ts`에 자체 구성이 있습니다. `.tools()` 목록에 도구의 enum을 추가하세요:
   - `generic/config.ts`, `next-gen/config.ts`, `gpt-5/config.ts`, `native-gpt-5/config.ts`, `native-gpt-5-1/config.ts`, `native-next-gen/config.ts`, `gemini-3/config.ts`, `glm/config.ts`, `hermes/config.ts`, `xs/config.ts`
   - **중요**: 변형의 구성에 추가하는 경우 도구 사양이 해당 ModelFamily에 대한 변형을 내보내는지 확인하세요 (또는 GENERIC 폴백에 의존)
5. **`src/core/task/tools/handlers/`에 핸들러 생성**
6. **필요한 경우 `ToolExecutor.ts`에 연결** 실행 흐름을 위해
7. **필요한 경우 `src/core/assistant-message/index.ts`의 도구 파싱에 추가**
8. **도구에 UI 피드백이 있는 경우**: proto에 `ClineSay` enum 추가, `src/shared/ExtensionMessage.ts` 업데이트, `src/shared/proto-conversions/cline-message.ts` 업데이트, `webview-ui/src/components/chat/ChatRow.tsx` 업데이트

## 시스템 프롬프트 수정
**먼저 읽으세요:** `src/core/prompts/system-prompt/README.md`, `tools/README.md`, `__tests__/README.md`

시스템 프롬프트는 모듈식입니다: **컴포넌트** (재사용 가능한 섹션) + **변형** (모델별 구성) + **템플릿** (`{{PLACEHOLDER}}` 해결 포함).

**주요 디렉토리:**
- `components/` - 공유 섹션: `rules.ts`, `capabilities.ts`, `editing_files.ts` 등
- `variants/` - 모델별: `generic/`, `next-gen/`, `xs/`, `gpt-5/`, `gemini-3/`, `hermes/`, `glm/` 등
- `templates/` - 템플릿 엔진 및 플레이스홀더 정의

**변형 계층 (사용자에게 수정할 것을 물어보세요):**
- **Next-gen** (Claude 4, GPT-5, Gemini 2.5): `next-gen/`, `native-next-gen/`, `native-gpt-5/`, `native-gpt-5-1/`, `gemini-3/`, `gpt-5/`
- **Standard** (기본 폴백): `generic/`
- **Local/small models**: `xs/`, `hermes/`, `glm/`

**재정의 작동 방식:** 변형은 `config.ts`의 `componentOverrides`를 통해 컴포넌트를 재정의하거나 `template.ts`에서 사용자 정의 템플릿을 제공할 수 있습니다 (예: `next-gen/template.ts`가 `rules_template`을 내보냄). 재정의가 없으면 `components/`의 공유 컴포넌트가 사용됩니다.

**예시: RULES 섹션에 규칙 추가**
1. 변형이 규칙을 재정의하는지 확인: `variants/*/template.ts`에서 `rules_template` 또는 `config.ts`에서 `componentOverrides.RULES` 찾기
2. 공유된 경우: `components/rules.ts` 수정
3. 재정의된 경우: 해당 변형의 템플릿 수정
4. XS 변형은 특별합니다—`template.ts`에 매우 압축된 인라인 콘텐츠가 있습니다

**변경 후 스냅샷 재생성:**
```bash
UPDATE_SNAPSHOTS=true npm run test:unit
```
스냅샷은 `__tests__/__snapshots__/`에 있습니다. 테스트는 모델 패밀리 및 컨텍스트 변형(브라우저, MCP, 포커스 체인)에 걸쳐 검증합니다.

## 기본 슬래시 명령 수정
세 곳을 업데이트해야 합니다:
- `src/core/slash-commands/index.ts` - 명령 정의
- `src/core/prompts/commands.ts` - 시스템 프롬프트 통합
- `webview-ui/src/utils/slash-commands.ts` - 웹뷰 자동 완성

## 새로운 전역 상태 키 추가
전역 상태에 새 키를 추가하려면 여러 곳을 업데이트해야 합니다. 단계를 놓치면 조용한 실패가 발생합니다.

필수 단계:
1. `src/shared/storage/state-keys.ts`의 타입 정의 - `GlobalState` 또는 `Settings` 인터페이스에 추가
2. `src/core/storage/utils/state-helpers.ts`에서 globalState에서 읽기:
   - `readGlobalStateFromDisk()`에 `const myKey = context.globalState.get<GlobalStateAndSettings["myKey"]>("myKey")` 추가
   - 반환 객체에 추가: `myKey: myKey ?? defaultValue,`
3. StateManager는 초기화 후 `setGlobalState()`/`getGlobalStateKey()`를 통해 읽기/쓰기를 처리합니다

일반적인 실수: `context.globalState.get()` 호출 없이 반환 값만 추가. 이것은 컴파일되지만 로드 시 값이 항상 `undefined`입니다.

## StateManager 캐시 vs 직접 globalState 액세스
StateManager는 `common.ts`의 `StateManager.initialize(context)` 중에 채워지는 인메모리 캐시를 사용합니다. 대부분의 상태에 대해 `controller.stateManager.setGlobalState()`/`getGlobalStateKey()`를 사용하세요.

예외: 확장 시작 시 즉시 필요한 상태 (캐시가 준비되기 전)

창 A가 상태를 설정하고 즉시 창 B를 열면 새 창의 StateManager 캐시는 초기화 중에 `context.globalState`에서 채워집니다. 창 B에서 시작 시 바로 상태를 읽어야 하는 경우 (예: `common.ts`의 `initialize()` 중), StateManager의 캐시 대신 `context.globalState.get()`에서 직접 읽으세요.

예시 패턴 (`lastShownAnnouncementId` 및 `worktreeAutoOpenPath` 참조):
```typescript
// 쓰기 (일반 패턴)
controller.stateManager.setGlobalState("myKey", value)

// common.ts의 시작 시 읽기 (캐시 우회)
const value = context.globalState.get<string>("myKey")
```

이것은 StateManager 캐시가 완전히 사용 가능하기 전의 짧은 시작 창 동안 창 간 상태 읽기에만 필요합니다. 초기화 후 일반 상태 액세스는 StateManager를 사용해야 합니다.

## ChatRow 취소/중단 상태
ChatRow가 로딩/진행 중 상태(스피너)를 표시할 때 작업이 취소될 때 어떤 일이 발생하는지 처리해야 합니다. 취소가 메시지 내용을 업데이트하지 않기 때문에 명확하지 않습니다—컨텍스트에서 추론해야 합니다.

**패턴:**
1. 메시지에는 `message.text`에 JSON으로 저장된 `status` 필드가 있습니다 (예: `"generating"`, `"complete"`, `"error"`)
2. 작업 중에 취소되면 상태가 영원히 `"generating"`으로 유지됩니다—아무도 업데이트하지 않습니다
3. 취소를 감지하려면 두 가지 조건을 확인하세요:
   - `!isLast` — 이 메시지가 더 이상 마지막 메시지가 아니면 그 후에 다른 일이 발생했습니다 (중단됨)
   - `lastModifiedMessage?.ask === "resume_task" || "resume_completed_task"` — 작업이 방금 취소되었고 재개를 기다리고 있습니다

**`generate_explanation`의 예시:**
```tsx
const wasCancelled =
    explanationInfo.status === "generating" &&
    (!isLast ||
        lastModifiedMessage?.ask === "resume_task" ||
        lastModifiedMessage?.ask === "resume_completed_task")
const isGenerating = explanationInfo.status === "generating" && !wasCancelled
```

**두 가지 확인이 필요한 이유?**
- `!isLast`는 다음을 포착합니다: 취소됨 → 재개됨 → 다른 작업 수행 → 이 오래된 메시지는 오래됨
- `lastModifiedMessage?.ask === "resume_task"`는 다음을 포착합니다: 방금 취소됨, 아직 재개되지 않음, 이 메시지는 여전히 기술적으로 "마지막"

**참조:** `BrowserSessionRow.tsx`는 `isLastApiReqInterrupted` 및 `isLastMessageResume`과 유사한 패턴을 사용합니다.

**백엔드 측:** 스트리밍이 취소되면 스트리밍 함수가 반환된 후 `taskState.abort`를 확인하여 적절하게 정리하세요 (탭 닫기, 주석 지우기 등).
