#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

# ==== 설정 ====
GH_OWNER="${GH_OWNER:-kkackdgnl}"
GH_REPO="${GH_REPO:-luca}"
GH_BRANCH="${GH_BRANCH:-main}"
GH_TOKEN="${GH_TOKEN:-}"

if [ -z "$GH_TOKEN" ]; then
  echo "❗ GH_TOKEN 환경변수가 필요합니다 (actions:read, repo 권한)."
  exit 1
fi

# ==== 1) 웹자산 빌드 (원하면 생략 가능) ====
if [ -f package.json ]; then
  echo "▶ npm install"
  npm install --silent
  if npm run | grep -q " build"; then
    echo "▶ npm run build"
    npm run build
  fi
fi

if npx --yes cap -v >/dev/null 2>&1; then
  echo "▶ npx cap copy"
  npx --yes cap copy || true
fi

# ==== 2) 커밋 & 푸시 ====
echo "▶ git add/commit/push"
git add -A
git commit -m "chore: auto build $(date +'%F %T')" || true
git push origin "$GH_BRANCH"

# ==== 3) 최신 워크플로우 run 대기 ====
API="https://api.github.com"
AUTH="-H Authorization: token ${GH_TOKEN}"

echo "▶ 최신 워크플로우 실행 찾는 중..."
RUN_ID=""
for i in {1..30}; do
  RUN_ID=$(curl -s $AUTH "$API/repos/${GH_OWNER}/${GH_REPO}/actions/runs?branch=${GH_BRANCH}&per_page=1" \
    | jq -r '.workflow_runs[0].id // empty')
  [ -n "$RUN_ID" ] && break
  sleep 2
done
[ -z "$RUN_ID" ] && { echo "❗ 워크플로우 실행을 찾지 못했어요."; exit 1; }

echo "▶ 빌드 진행 상태 폴링..."
while :; do
  READ_JSON=$(curl -s $AUTH "$API/repos/${GH_OWNER}/${GH_REPO}/actions/runs/${RUN_ID}")
  STATUS=$(echo "$READ_JSON" | jq -r '.status')
  CONCLUSION=$(echo "$READ_JSON" | jq -r '.conclusion // ""')
  echo "   - status: $STATUS, conclusion: $CONCLUSION"
  [ "$STATUS" = "completed" ] && break
  sleep 5
done

[ "$CONCLUSION" = "success" ] || { echo "❗ 빌드 실패(conclusion=$CONCLUSION)"; exit 1; }

# ==== 4) 아티팩트(artifact) 다운로드 ====
echo "▶ 아티팩트 목록 조회"
ART_ID=$(curl -s $AUTH "$API/repos/${GH_OWNER}/${GH_REPO}/actions/runs/${RUN_ID}/artifacts" \
  | jq -r '.artifacts[] | select(.name=="apk") | .id' | head -n1)

[ -n "$ART_ID" ] || { echo "❗ 'apk' 아티팩트가 없습니다. Actions 업로드 이름 확인하세요."; exit 1; }

OUTDIR="$HOME/storage/downloads/luca"
mkdir -p "$OUTDIR"

echo "▶ 아티팩트 다운로드 → $OUTDIR/artifact.zip"
curl -L -s $AUTH -H "Accept: application/vnd.github+json" \
  "$API/repos/${GH_OWNER}/${GH_REPO}/actions/artifacts/${ART_ID}/zip" \
  -o "$OUTDIR/artifact.zip"

echo "▶ 압축 해제"
unzip -q -o "$OUTDIR/artifact.zip" -d "$OUTDIR"

echo "✅ 완료!"
echo "📦 폴더: $OUTDIR"
echo "💿 APK 파일들:"
find "$OUTDIR" -type f -name "*.apk" -print
