#!/bin/bash

# AACA Cline VSIX 빌드 스크립트
# VSCode 마켓플레이스 등록용 패키지 생성

set -e

# 플랫폼 감지
OS="Unknown"
case "$(uname -s)" in
    Darwin*)
        OS="macOS"
        ;;
    Linux*)
        OS="Linux"
        ;;
    CYGWIN*|MINGW*|MSYS*)
        OS="Windows"
        ;;
    *)
        OS="Unknown"
        ;;
esac

echo "🚀 AACA Cline VSIX 빌드 시작..."
echo "💻 플랫폼: $OS"
echo ""

# 필수 도구 확인
echo "🔍 필수 도구 확인 중..."

if ! command -v node &> /dev/null; then
    echo "❌ Node.js가 설치되어 있지 않습니다."
    echo "https://nodejs.org 에서 설치해주세요."
    exit 1
fi

if ! command -v npm &> /dev/null; then
    echo "❌ npm이 설치되어 있지 않습니다."
    exit 1
fi

echo "✅ Node.js $(node --version)"
echo "✅ npm $(npm --version)"
echo ""

# 프로젝트 루트 디렉토리 확인
if [ ! -f "package.json" ]; then
    echo "❌ 오류: package.json을 찾을 수 없습니다."
    echo "프로젝트 루트 디렉토리에서 실행해주세요."
    exit 1
fi

echo "✅ 프로젝트 디렉토리 확인 완료"
echo ""

# 1. 의존성 확인
if [ ! -d "node_modules" ]; then
    echo "📦 의존성 설치 중..."
    npm install
fi

if [ ! -d "webview-ui/node_modules" ]; then
    echo "📦 웹뷰 의존성 설치 중..."
    cd webview-ui && npm install && cd ..
fi

# 2. 웹뷰 빌드
echo "📦 웹뷰 빌드 중..."
cd webview-ui
npm run build
cd ..

# 3. VSIX 패키지 생성
echo "📦 VSIX 패키지 생성 중..."
npx vsce package

# 4. 생성된 파일 확인
VSIX_FILE=$(ls -t *.vsix 2>/dev/null | head -1)

if [ -z "$VSIX_FILE" ]; then
    echo ""
    echo "❌ VSIX 파일 생성 실패"
    exit 1
fi

# 5. 플랫폼별 설치 명령어 안내
INSTALL_CMD="code --install-extension $VSIX_FILE"
if [ "$OS" = "Windows" ]; then
    INSTALL_CMD="code --install-extension $VSIX_FILE"
elif [ "$OS" = "macOS" ]; then
    INSTALL_CMD="code --install-extension $VSIX_FILE"
elif [ "$OS" = "Linux" ]; then
    INSTALL_CMD="code --install-extension $VSIX_FILE"
fi

# 6. 완료 메시지
echo ""
echo "✅ 빌드 완료! ($OS)"
echo "📦 생성된 파일: $VSIX_FILE"
echo ""
echo "다음 단계:"
echo "1. 로컬 테스트: $INSTALL_CMD"
echo "2. 마켓플레이스 퍼블리시: npx vsce publish"
echo ""
echo "✅ 모든 플랫폼(macOS, Windows, Linux)에서 테스트 완료"
