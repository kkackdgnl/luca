#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

# ---------------------------
# 설정 로드 (토큰 자동 불러오기)
# ---------------------------
[ -f "$HOME/.config/luca.env" ] && . "$HOME/.config/luca.env"
: "${GH_TOKEN:?GH_TOKEN이 없습니다. ~/.config/luca.env 에 GH_TOKEN=... 저장하세요}"

API="https://api.github.com"

# ---------------------------
# 현재 git remote에서 소유자/레포 자동 파싱
# ---------------------------
REMOTE_URL="$(git config --get remote.origin.url || true)"
if [[ "$REMOTE_URL" == git@github.com:* ]]; then
  PATH_PART="${REMOTE_URL#git@github.com:}"
elif [[ "$REMOTE_URL" == https://github.com/* ]]; then
  PATH_PART="${REMOTE_URL#https://github.com/}"
else
  echo "❌ 원격 저장소(URL)를 알 수 없습니다. git remote origin 설정을 확인하세요."
  exit 1
fi
PATH_PART="${PATH_PART%.git}"
GH_OWNER="${GH_OWNER:-${PATH_PART%%/*}}"
GH_REPO="${GH_REPO:-${PATH_PART#*/}}"

echo "📦 레포: $GH_OWNER/$GH_REPO"

# ---------------------------
# 웹 자산 빌드 → Capacitor 복사(옵션)
# (package.json 있으면 웹 빌드 시도)
# ---------------------------
if [ -f package.json ]; then
  echo "🧱 npm 설치/빌드"
  (npm ci || npm install)
  # Capacitor 웹자산 복사 (있을 때만)
  if npx cap -v >/dev/null 2>&1; then
    npx cap copy || true
  fi
else
  echo "ℹ️ package.json 없음 → 웹 빌드 생략"
fi

# ---------------------------
# 변경사항 커밋/푸시 (변경 없으면 그냥 통과)
# ---------------------------
echo "📝 git 커밋/푸시"
git add -A || true
git commit -m "build: android" || true
git push || true

# ---------------------------
# 최신(미만료) 아티팩트 중 'apk' 포함된 것 가져오기
# ---------------------------
OUTDIR="$HOME/storage/downloads/luca"
mkdir -p "$OUTDIR"

echo "⬇️  아티팩트 조회"
ART_URL=$(
  curl -s -H "Authorization: Bearer $GH_TOKEN" \
       -H "Accept: application/vnd.github+json" \
       "$API/repos/$GH_OWNER/$GH_REPO/actions/artifacts?per_page=100" \
  | jq -r '.artifacts[]
           | select(.expired==false)
           | select(.name | test("apk"; "i"))
           | .archive_download_url' \
  | head -n1
)

if [ -z "${ART_URL:-}" ] || [ "$ART_URL" = "null" ]; then
  echo "❌ 다운로드할 APK 아티팩트를 찾지 못했습니다."
  echo "   - Actions가 성공했는지, 아티팩트 이름에 apk가 포함되는지 확인하세요."
  exit 1
fi

echo "📥 다운로드: $OUTDIR/artifact.zip"
curl -L -s -H "Authorization: Bearer $GH_TOKEN" \
     -H "Accept: application/vnd.github+json" \
     -o "$OUTDIR/artifact.zip" "$ART_URL"

echo "🗜️  압축 해제"
unzip -qo "$OUTDIR/artifact.zip" -d "$OUTDIR"

echo "✅ 완료!"
echo "📁 폴더: $OUTDIR"
echo "📱 APK 파일들:"
find "$OUTDIR" -type f -name "*.apk" -print
