#!/usr/bin/env bash
set -euo pipefail
echo "=== SkillConnect Full Build ==="

# 1. Apply pending migrations
echo "[1/7] Applying migrations..."
for f in /workspaces/SKILL/database/migrations/*.sql; do
  echo "  → $(basename "$f")"
  PGPASSWORD=password psql -h localhost -U postgres -d skillconnect -f "$f" 2>&1 | grep -v "^$" | head -5 || true
done
echo "  ✓ Migrations applied"

# 2. Restart backend
echo "[2/7] Restarting backend..."
pkill -f "node src/server.js" 2>/dev/null || true
sleep 2
cd /workspaces/SKILL/backend
nohup node src/server.js > /tmp/backend.log 2>&1 &
sleep 3
curl -sf http://localhost:8000/api/health > /dev/null && echo "  ✓ Backend running on port 8000" || echo "  ✗ Backend failed — check /tmp/backend.log"

# 3. Run backend tests
echo "[3/7] Running backend tests..."
cd /workspaces/SKILL/backend
npx jest --forceExit --detectOpenHandles 2>&1 | tail -20
echo "  ✓ Tests done"

# 4. Verify API endpoints
echo "[4/7] Smoke-testing API..."
TOKEN_C=$(curl -s -X POST http://localhost:8000/api/auth/login -H "Content-Type: application/json" -d '{"email":"customer@demo.com","password":"demo123"}' | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['token'])")
echo "  login: ok"
curl -s "http://localhost:8000/api/bookings" -H "Authorization: Bearer $TOKEN_C" | python3 -c "import sys,json;d=json.load(sys.stdin);print(f'  bookings: {len(d[\"data\"])} found')"
curl -s "http://localhost:8000/api/messages/threads" -H "Authorization: Bearer $TOKEN_C" | python3 -c "import sys,json;d=json.load(sys.stdin);print(f'  threads:  {len(d[\"data\"])} found')"
curl -s "http://localhost:8000/api/notifications" -H "Authorization: Bearer $TOKEN_C" | python3 -c "import sys,json;d=json.load(sys.stdin);print(f'  notifs:   {len(d[\"data\"])} (unread: {d.get(\"unread_count\",0)})')"
curl -s "http://localhost:8000/api/search?availability=available&latitude=17.385&longitude=78.4867&radius_km=50" | python3 -c "import sys,json;d=json.load(sys.stdin);print(f'  geo+avail: {len(d[\"data\"])} nearby available pros')"
TOKEN_P=$(curl -s -X POST http://localhost:8000/api/auth/login -H "Content-Type: application/json" -d '{"email":"pro1@demo.com","password":"demo123"}' | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['token'])" 2>/dev/null || echo "")
if [ -n "$TOKEN_P" ]; then
  curl -s "http://localhost:8000/api/dashboard" -H "Authorization: Bearer $TOKEN_P" | python3 -c "import sys,json;d=json.load(sys.stdin)['data'];e=d.get('earnings',{});f=d.get('funnel',{});print(f'  pro analytics: lifetime=\u20b9{e.get(\"lifetime\",0):.0f}, pipeline=\u20b9{e.get(\"pipeline\",0):.0f}, conv={f.get(\"conversionPct\",0)}%')"
fi
echo "  ✓ API verified"

# 5. Flutter analyze
echo "[5/7] Flutter analyze..."
cd /workspaces/SKILL/mobile/skillconnect
flutter analyze 2>&1 | grep -E "error|issues found" | tail -5
echo "  ✓ Analysis done"

# 6. Build web
echo "[6/7] Building Flutter web..."
cd /workspaces/SKILL/mobile/skillconnect
flutter build web --release --base-href=/app/ 2>&1 | tail -5
echo "  ✓ Web build at build/web/"

# 7. Build APK
echo "[7/7] Building Flutter APK..."
cd /workspaces/SKILL/mobile/skillconnect
flutter build apk --debug 2>&1 | tail -5
APK_PATH="build/app/outputs/flutter-apk/app-debug.apk"
if [ -f "$APK_PATH" ]; then
  SIZE=$(du -h "$APK_PATH" | cut -f1)
  echo "  ✓ APK built ($SIZE): $APK_PATH"
else
  echo "  ⚠ APK build may have failed"
fi

echo ""
echo "════════════════════════════════════════"
echo "  BUILD COMPLETE"
echo "════════════════════════════════════════"
echo "  Web: https://bookish-tribble-4q7qxr5p5vvxh7vwg-8000.app.github.dev/app/"
echo "  API: https://bookish-tribble-4q7qxr5p5vvxh7vwg-8000.app.github.dev/api"
echo "  APK: /workspaces/SKILL/mobile/skillconnect/$APK_PATH"
echo "  WS:  wss://bookish-tribble-4q7qxr5p5vvxh7vwg-8000.app.github.dev/ws?token=..."
echo "════════════════════════════════════════"
