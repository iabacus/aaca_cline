# 확장 릴리스

Cline 릴리스를 위한 changeset을 가져와 업데이트된 공지 컴포넌트와 업데이트된 changelog를 작성합니다.

## 시작하기 전에

1. 먼저 체크아웃하지 않고 changeset PR을 검사합니다:
   ```bash
   gh pr view changeset-release/main
   ```

2. PR diff를 보고 자동 생성된 CHANGELOG.md 변경 사항을 확인합니다:
   ```bash
   gh pr diff changeset-release/main > changeset-diff.txt
   cat changeset-diff.txt | grep -A 50 "CHANGELOG.md"
   ```

## 초기 설정

3. 준비가 되면 changeset 릴리스 브랜치를 체크아웃하고 업데이트합니다:
   ```bash
   git checkout changeset-release/main
   git pull origin changeset-release/main
   ```

## 각 변경 사항 분석

4. 자동 생성된 changelog 항목의 각 커밋 해시에 대해:

   a. 커밋 해시와 관련된 PR 번호 찾기:
      ```bash
      gh pr list --search "<commit-hash>" --state merged
      ```
   
   b. 더 나은 컨텍스트를 위해 PR 세부 정보 가져오기:
      ```bash
      gh pr view <PR-number>
      ```
   
   c. 기여자가 외부인지 확인하여 attribution이 필요한지 판단:
      ```bash
      USERNAME=$(gh pr view <PR-number> --json author --jq .author.login)
      gh api "orgs/cline/members" --jq "map(.login)" | grep -i "$USERNAME"
      ```
   
   d. 코드 변경 사항을 이해하기 위해 전체 PR diff 보기:
      ```bash
      gh pr diff <PR-number> > pr-diff-<PR-number>.txt
      cat pr-diff-<PR-number>.txt
      ```

## Changelog 업데이트

5. PR 분석을 기반으로 사용자 친화적인 설명으로 CHANGELOG.md를 업데이트합니다:
   - 기능 유형별로 그룹화 (Added, Changed, Fixed)
   - 가장 흥미로운 기능을 맨 위에 배치
   - 버그 수정 및 작은 개선 사항을 맨 아래로 이동
   - 명확하고 최종 사용자 중심의 언어 사용
   - 외부 기여자의 경우 관련 항목 끝에 attribution 추가: `(Thanks @username!)`

## 버전 번호 확인

6. 버전 범프가 적절한지 확인합니다:
   - package.json을 확인하여 자동 생성된 버전 번호 확인
   - 기능 세트가 마이너 범프를 보증하지 않는 경우 package.json 수정

7. CHANGELOG.md의 버전에 대괄호가 있는지 확인:
   ```
   ## [3.16.0]
   ```

## 공지 생성 (마이너/메이저 버전만)

8. 마이너 버전 범프인 경우 공지 컴포넌트를 생성/업데이트합니다:
   - src/views/components/announcement.tsx 파일 편집
   - 주요 기능을 기반으로 하이라이트 업데이트
   - 이전 버전 하이라이트를 "Previous Updates" 섹션으로 이동

## 릴리스 마무리

9. 새 버전 번호로 종속성 업데이트:
   ```bash
   npm run install:all
   ```

10. 변경 사항 커밋:
    ```bash
    git add CHANGELOG.md package.json package-lock.json src/views/components/announcement.tsx
    git commit -m "Update CHANGELOG.md and announcement for version 3.16.0"
    ```

11. changeset 브랜치에 변경 사항 푸시:
    ```bash
    git push origin changeset-release/main
    ```

12. 변경 사항이 성공적으로 푸시되었는지 확인:
    ```bash
    git status
    ```
