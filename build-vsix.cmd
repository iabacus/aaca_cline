@echo off
REM AACA Cline VSIX 빌드 스크립트 (Windows)
REM VSCode 마켓플레이스 등록용 패키지 생성

echo 🚀 AACA Cline VSIX 빌드 시작...

REM 1. 웹뷰 빌드
echo 📦 웹뷰 빌드 중...
cd webview-ui
call npm run build
cd ..

REM 2. VSIX 패키지 생성
echo 📦 VSIX 패키지 생성 중...
call npx vsce package

REM 3. 완료 메시지
echo.
echo ✅ 빌드 완료!
echo 📦 생성된 파일: aaca-cline-dev-0.0.3.vsix
echo.
echo 다음 단계:
echo 1. 로컬 테스트: code --install-extension aaca-cline-dev-0.0.3.vsix
echo 2. 마켓플레이스 퍼블리시: npx vsce publish
echo.
pause
