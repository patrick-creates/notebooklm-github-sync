#!/usr/bin/env bash
# Runs scripts/sync.sh against a throwaway git repo with nlm mocked out.
# Uses the real jq when installed; otherwise a grep stand-in, which does not check the jq filter itself.
# Usage: bash tests/test_sync.sh
set -euo pipefail

SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/scripts/sync.sh"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

mkdir -p "$WORK/bin" "$WORK/repo"
# nlm logs every call. The notebook holds sources under both title styles:
# bare (CLI >= 0.9) and "<name>.md" (CLI < 0.9).
cat > "$WORK/bin/nlm" <<'EOF'
#!/usr/bin/env bash
echo "nlm $*" >> "$LOG"
case "$1 $2" in
  "source list") cat <<'JSON'
[
{"id":"id-guide-new","title":"guide"},
{"id":"id-guide-old","title":"guide.md"},
{"id":"id-mydocs","title":"mydocs"},
{"id":"id-root","title":"Root_Files.md"},
{"id":"id-docs","title":"docs"},
{"id":"id-guidelines","title":"guidelines"}
]
JSON
  ;;
  "source add") [ -z "${NLM_FAIL_ADD:-}" ] || { echo "quota exceeded"; exit 1; } ;;
esac
EOF
if ! command -v jq > /dev/null; then
  echo "note: jq not installed, using grep stand-in"
  cat > "$WORK/bin/jq" <<'EOF'
#!/usr/bin/env bash
grep -E "\"title\":\"$4(\.md)?\"" | sed 's/.*"id":"\([^"]*\)".*/\1/'
EOF
fi
chmod +x "$WORK/bin/"*
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

# Changed files only: deleted folder and root files pruned (both title styles), changed folder replaced
: > "$LOG"; FORCE_SYNC=false bash "$SCRIPT" > /dev/null
expect "nlm source delete id-guide-new --confirm"
expect "nlm source delete id-guide-old --confirm"
expect "nlm source delete id-root --confirm"
expect "nlm source delete id-mydocs --confirm"
reject "id-guidelines"
reject "id-docs"
reject "--title docs "

# Force sync: every existing folder re-uploaded, nothing for the deleted one
: > "$LOG"; FORCE_SYNC=true bash "$SCRIPT" > /dev/null
expect "nlm source delete id-docs --confirm"
reject "id-guide"
grep -q -- "--title docs " "$LOG" || { echo "FAIL: force sync skipped docs"; fail=1; }

# Failed upload stops the run and shows the CLI output
: > "$LOG"
if out=$(NLM_FAIL_ADD=1 FORCE_SYNC=false bash "$SCRIPT" 2>&1); then
  echo "FAIL: failed upload did not stop the run"; fail=1
fi
grep -q "::error::nlm source add failed for mydocs" <<< "$out" || { echo "FAIL: no error line for failed upload"; fail=1; }
grep -q "quota exceeded" <<< "$out" || { echo "FAIL: CLI output not shown"; fail=1; }

# Unknown base commit stops the run
if BEFORE_SHA=1234567890123456789012345678901234567890 FORCE_SYNC=false bash "$SCRIPT" > /dev/null 2>&1; then
  echo "FAIL: unknown base commit did not stop the run"; fail=1
fi

[ "$fail" -eq 0 ] && echo "ok"
exit "$fail"
