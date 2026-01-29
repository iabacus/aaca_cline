# 네트워킹 및 프록시 지원

모든 환경(VSCode, JetBrains, CLI)과 다양한 네트워크 구성(특히 기업 프록시)에서 Cline이 올바르게 작동하도록 하려면 모든 네트워크 활동에 대해 이 가이드라인을 엄격히 따르세요.

확장 코드에서는 전역 `fetch` 또는 기본 `axios` 인스턴스를 사용하지 마세요. (참고: `shared/net.ts`는 fetch 래퍼를 설정하므로 이 규칙에서 제외됩니다.) 웹뷰 코드에서는 전역 `fetch`를 사용해야 합니다.

전역 `fetch`와 기본 `axios`는 모든 환경(특히 JetBrains 및 CLI)에서 프록시 구성을 자동으로 가져오지 않습니다. 프록시 에이전트 구성을 처리하는 `@/shared/net`의 제공된 유틸리티를 사용해야 합니다. 웹뷰에서는 브라우저/임베더가 프록시를 처리합니다.

## 가이드라인

### 1. `fetch` 사용

`fetch(...)`대신 프록시 인식 래퍼를 가져오세요:

```typescript
import { fetch } from '@/shared/net'

// 사용법은 전역 fetch와 동일합니다
const response = await fetch('https://api.example.com/data')
```

### 2. `axios` 사용

`axios`를 사용할 때는 `getAxiosSettings()`의 설정을 적용해야 합니다:

```typescript
import axios from 'axios'
import { getAxiosSettings } from '@/shared/net'

const response = await axios.get('https://api.example.com/data', {
  headers: { 'Authorization': '...' },
  ...getAxiosSettings() // <--- 중요: 필요한 경우 프록시 에이전트를 주입합니다
})
```

### 3. 타사 클라이언트 (OpenAI, Ollama 등)

대부분의 API 클라이언트 라이브러리는 `fetch` 구현을 사용자 정의할 수 있습니다. 이러한 클라이언트에 프록시 인식 `fetch`를 전달해야 합니다.

**예시 (OpenAI):**
```typescript
import OpenAI from "openai"
import { fetch } from "@/shared/net"

this.client = new OpenAI({
  apiKey: '...',
  fetch, // <--- 중요: fetch 래퍼를 전달합니다
})
```

### 4. 테스트

`mockFetchForTesting`을 사용하여 기본 fetch 구현을 모킹하세요.

**예시 (콜백):**

```
import { mockFetchForTesting } from "@/shared/net"

...
  let mockFetch = ...
  mockFetchForTesting(mockFetch, () => {
    // 이것은 mockFetch를 호출합니다
    fetch('https://foo.example').then(...)
  })
  // 호출이 반환되면 즉시 원래 fetch가 복원됩니다.
```

**예시 (Promise):**

```
import { mockFetchForTesting } from "@/shared/net"

...
  let mockFetch = ...
  await mockFetchForTesting(mockFetch, async () => {
    await ...
    // 이것은 mockFetch를 호출합니다
    await fetch('https://foo.example')
    ...
  })
  // 콜백의 Promise가 완료되면 원래 fetch가 복원됩니다
```

## 검증

새로운 네트워크 호출 또는 통합을 추가하는 경우:
1. `@/shared/net.ts`가 가져와졌는지 확인하세요.
2. `fetch` 또는 `getAxiosSettings`이 사용되고 있는지 확인하세요.
3. 타사 클라이언트가 사용자 정의 fetch를 사용하도록 구성되었는지 확인하세요.
