# 릴리스

열린 changeset PR에서 릴리스를 준비하고 게시합니다.

## 개요

이 워크플로우는 다음을 도와줍니다:
1. 열린 changeset PR 찾기 및 체크아웃
2. changelog 정리 (버전 형식 수정, 항목 다듬기)
3. PR 브랜치에 변경 사항 푸시
4. 적절한 커밋 메시지 형식으로 병합
5. 릴리스 태그 지정 및 푸시 (커밋 확인 후)
6. publish 워크플로우 트리거
7. GitHub 릴리스 노트 업데이트
8. Slack 공지와 함께 최종 요약 제공

## 1단계: Changeset PR 찾기

열린 changeset PR 찾기:

```bash
gh pr list --search "Changeset version bump" --state open --json number,title,headRefName,url
```

PR이 없으면 사용자에게 changeset PR이 준비되지 않았음을 알립니다.

## 2단계: PR 정보 수집

PR 세부 정보 가져오기:

```bash
PR_NUMBER=<1단계의 번호>
gh pr view $PR_NUMBER --json body,files,headRefName
```

PR 브랜치 체크아웃:

```bash
git fetch origin changeset-release/main
git checkout changeset-release/main
```

## 3단계: 변경 사항 분석

현재 CHANGELOG.md를 읽어 자동화가 생성한 내용 확인:

```bash
head -50 CHANGELOG.md
```

package.json에서 버전 가져오기:

```bash
cat package.json | grep '"version"'
```

**사용자에게 제시:**
- 릴리스될 버전 번호
- changeset PR의 원시 changelog 항목
- 패치, 마이너 또는 메이저 릴리스인지 여부

## 4단계: Changelog 정리

changelog에 필요한 수정 사항:

1. **버전 번호에 대괄호 추가**: `## 3.44.1`을 `## [3.44.1]`로 변경
2. **카테고리 헤더 없음**: `### Added`, `### Fixed` 등을 사용하지 마세요. 단순한 글머리 기호 목록만 사용
3. **가장 중요한 것부터 가장 덜 중요한 것까지 항목 정렬**
4. **사용자 친화적인 설명 작성**

**사용자에게** 제안된 changelog 변경 사항을 적용하기 전에 검토하도록 요청합니다.

## 5단계: 변경 사항 커밋 및 푸시

changelog 편집 후:

```bash
git add CHANGELOG.md
git commit -m "Clean up changelog formatting"
git push origin changeset-release/main
```

## 6단계: PR 병합

**사용자에게 확인** 병합 준비가 되었는지 확인합니다.

적절한 커밋 메시지 형식으로 PR 병합:

```bash
VERSION=<package.json의 버전>
gh pr merge $PR_NUMBER --squash --subject "v${VERSION} Release Notes" --body ""
```

## 7단계: 릴리스 태그 지정

병합이 완료된 후 main을 체크아웃하고 pull:

```bash
git checkout main
git pull origin main
```

**중요: 태그 지정 전에 최신 커밋이 릴리스 커밋인지 확인:**

```bash
git log -1 --oneline
```

확인 후 태그 지정 및 푸시:

```bash
VERSION=<버전>
git tag v${VERSION}
git push origin v${VERSION}
```

## 8단계: Publish 워크플로우 트리거

**사용자에게 publish 워크플로우를 트리거하도록 알립니다:**
1. https://github.com/cline/cline/actions/workflows/publish.yml로 이동
2. release-type에 대해 **"release"** 선택
3. 태그로 **`v{VERSION}`** 붙여넣기

**사용자가** publish 워크플로우가 완료되었음을 확인할 때까지 기다립니다.

## 9단계: GitHub 릴리스 노트 업데이트

사용자가 publish 워크플로우가 완료되었음을 확인하면 자동 생성된 릴리스 콘텐츠를 가져옵니다:

```bash
VERSION=<버전>
gh release view v${VERSION} --json body --jq '.body'
```

릴리스 업데이트:

```bash
gh release edit v${VERSION} --notes "<새 본문 콘텐츠>"
```

## 10단계: 최종 요약

**Slack 공지 메시지를 클립보드에 복사** (전체 changelog 포함):

```bash
echo "VS Code v{VERSION} Released

- Changelog 항목 1
- Changelog 항목 2
- Changelog 항목 3" | pbcopy
```

**최종 요약 제시:**
- 릴리스된 버전: v{VERSION}
- 병합된 PR: #{PR_NUMBER}
- 푸시된 태그: v{VERSION}
- 릴리스: https://github.com/cline/cline/releases/tag/v{VERSION}
- Slack 메시지가 클립보드에 복사됨

**최종 알림:**
릴리스를 알리기 위해 Slack 메시지를 게시하세요
