# Cline Protobuf 개발 가이드

이 가이드는 웹뷰(프론트엔드)와 확장 호스트(백엔드) 간의 통신을 위한 새로운 gRPC 엔드포인트를 추가하는 방법을 설명합니다.

## 개요

Cline은 [Protobuf](https://protobuf.dev/)를 사용하여 강력한 타입의 API를 정의하고 효율적이고 타입 안전한 통신을 보장합니다. 모든 정의는 `/proto` 디렉토리에 있습니다. 컴파일러와 플러그인은 프로젝트 종속성으로 포함되어 있으므로 수동 설치가 필요하지 않습니다.

## 주요 개념 및 모범 사례

- **파일 구조**: 각 기능 도메인에는 자체 `.proto` 파일이 있어야 합니다 (예: `account.proto`, `task.proto`).
- **메시지 디자인**:
  - 간단한 단일 값 데이터의 경우 `proto/common.proto`의 공유 타입을 사용하세요 (예: `StringRequest`, `Empty`, `Int64Request`). 이것은 일관성을 촉진합니다.
  - 복잡한 데이터 구조의 경우 기능의 `.proto` 파일 내에 사용자 정의 메시지를 정의하세요 (`NewTaskRequest`와 같은 예시는 `task.proto` 참조).
- **명명 규칙**:
  - 서비스: `PascalCaseService` (예: `AccountService`).
  - RPC: `camelCase` (예: `accountEmailIdentified`).
  - 메시지: `PascalCase` (예: `StringRequest`).
- **스트리밍**: 서버-클라이언트 스트리밍의 경우 응답 타입에 `stream` 키워드를 사용하세요. 예시는 `account.proto`의 `subscribeToAuthCallback`을 참조하세요.

---

## 4단계 개발 워크플로우

다음은 `scrollToSettings`을 예시로 사용하여 새로운 RPC를 추가하는 방법입니다.

### 1. `.proto` 파일에 RPC 정의

`proto/` 디렉토리의 적절한 파일에 서비스 메서드를 추가하세요.

**파일: `proto/ui.proto`**
```proto
service UiService {
  // ... 다른 RPC들
  // 설정 보기에서 특정 설정 섹션으로 스크롤합니다
  rpc scrollToSettings(StringRequest) returns (KeyValuePair);
}
```
여기서는 공통 `StringRequest` 및 `KeyValuePair` 타입을 사용합니다.

### 2. 정의 컴파일

`.proto` 파일을 편집한 후 TypeScript 코드를 재생성하세요. 프로젝트 루트에서 다음을 실행하세요:
```bash
npm run protos
```
이 명령은 모든 `.proto` 파일을 컴파일하고 생성된 코드를 `src/generated/` 및 `src/shared/`로 출력합니다. 이러한 생성된 파일을 수동으로 편집하지 마세요.

### 3. 백엔드 핸들러 구현

백엔드에서 RPC 구현을 생성하세요. 핸들러는 `src/core/controller/[service-name]/`에 있습니다.

**파일: `src/core/controller/ui/scrollToSettings.ts`**
```typescript
import { Controller } from ".."
import { StringRequest, KeyValuePair } from "../../../shared/proto/common"

/**
 * 설정으로 스크롤 작업을 실행합니다
 * @param controller 컨트롤러 인스턴스
 * @param request 스크롤할 설정 섹션의 ID를 포함하는 요청
 * @returns UI가 처리할 action 및 value 필드가 있는 KeyValuePair
 */
export async function scrollToSettings(controller: Controller, request: StringRequest): Promise<KeyValuePair> {
	return KeyValuePair.create({
		key: "scrollToSettings",
		value: request.value || "",
	})
}
```

### 4. 웹뷰에서 RPC 호출

`webview-ui/`의 React 컴포넌트에서 새로운 RPC를 호출하세요. 생성된 클라이언트가 이것을 간단하게 만듭니다.

**파일: `webview-ui/src/components/browser/BrowserSettingsMenu.tsx`** (예시)
```tsx
import { UiServiceClient } from "../../../services/grpc"
import { StringRequest } from "../../../../shared/proto/common"

// ... React 컴포넌트 내부
const handleMenuClick = async () => {
    try {
        await UiServiceClient.scrollToSettings(StringRequest.create({ value: "browser" }))
    } catch (error) {
        console.error("브라우저 설정으로 스크롤 중 오류:", error)
    }
}
```
