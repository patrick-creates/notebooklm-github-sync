#!/usr/bin/env bash
# Runs scripts/sync.sh against a throwaway git repo with nlm and jq mocked out.
# Usage: bash tests/test_sync.sh
set -euo pipefail

SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/scripts/sync.sh"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

mkdir -p "$WORK/bin" "$WORK/repo"
# nlm logs every call; jq answers "source list" with one ID per title
cat > "$WORK/bin/nlm" <<'EOF'
#!/usr/bin/env bash
echo "nlm $*" >> "$LOG"
EOF
cat > "$WORK/bin/jq" <<'EOF'
#!/usr/bin/env bash
cat > /dev/null; echo "id-$4"
EOF
chmod +x "$WORK/bin/nlm" "$WORK/bin/jq"
export PATH="$WORK/bin:$PATH" LOG="$WORK/log" NB_ID=nb RUNNER_TEMP="$WORK/tmp"

cd "$WORK/repo"
git init -q
git config user.email test@example.com
git config user.name test
mkdir docs mydocs guide
echo a > docs/a.md; echo b > mydocs/b.md; echo c > guide/c.md; echo r > README.md
git add -A; git commit -qm one
export BEFORE_SHA="$(git rev-parse HEAD)"
git rm -rq guide README.md
echo b2 >> mydocs/b.md
git add -A; git commit -qm two
export GITHUB_SHA="$(git rev-parse HEAD)"

fail=0
expect() { grep -qxF -- "$1" "$LOG" || { echo "FAIL: expected '$1'"; fail=1; }; }
reject() { ! grep -qF -- "$1" "$LOG" || { echo "FAIL: unexpected '$1'"; fail=1; }; }

: > "$LOG"; FORCE_SYNC=false bash "$SCRIPT" > /dev/null
expect "nlm source delete id-guide.md --confirm"
expect "nlm source delete id-Root_Files.md --confirm"
expect "nlm source delete id-mydocs.md --confirm"
reject "--title docs "

: > "$LOG"; FORCE_SYNC=true bash "$SCRIPT" > /dev/null
reject "id-guide.md"
grep -q -- "--title docs " "$LOG" || { echo "FAIL: force sync skipped docs"; fail=1; }

: > "$LOG"
if BEFORE_SHA=1234567890123456789012345678901234567890 FORCE_SYNC=false bash "$SCRIPT" > /dev/null 2>&1; then
  echo "FAIL: unknown base commit did not stop the run"; fail=1
fi

[ "$fail" -eq 0 ] && echo "ok"
exit "$fail"
