#!/usr/bin/env bash
# Bundles changed Markdown per top-level folder and replaces the matching NotebookLM sources.
# Env: NB_ID (required), FORCE_SYNC, BEFORE_SHA, GITHUB_SHA, RUNNER_TEMP. Run from the repo root.
set -euo pipefail

OUTDIR="${RUNNER_TEMP}/nlm-bundles"
rm -rf "$OUTDIR"
mkdir -p "$OUTDIR"

# 1. Identify Changed Files
if [ "${FORCE_SYNC:-false}" = "true" ]; then
  echo "--- Force Sync: Identifying all markdown files ---"
  CHANGED_FILES=$(find . -type f -name "*.md" -not -path "*/.*" | sed 's|^\./||')
else
  BASE_SHA="${BEFORE_SHA:-}"
  # Check for initial push / zero-SHA
  if [ -n "$BASE_SHA" ] && [ "$BASE_SHA" != "0000000000000000000000000000000000000000" ]; then
    if ! git cat-file -e "${BASE_SHA}^{commit}" 2>/dev/null; then
      echo "::error::Previous commit $BASE_SHA not found. Use actions/checkout with fetch-depth: 0."
      exit 1
    fi
    CHANGED_FILES=$(git diff --name-only "$BASE_SHA" "$GITHUB_SHA" -- '*.md')
  else
    CHANGED_FILES=$(find . -type f -name "*.md" -not -path "*/.*" | sed 's|^\./||')
  fi
fi

# 2. Helper: delete ALL sources matching a title.
# CLI <0.9 ignored --title and stored the filename ("docs.md");
# CLI >=0.9 honors --title and stores it bare ("docs"). Match both
# so dedup survives either version and never accumulates duplicates.
delete_sources_by_title() {
  local nb_id="$1"
  local title="$2"
  local -a source_ids
  mapfile -t source_ids < <(nlm source list "$nb_id" --json 2>/dev/null \
    | jq -r --arg t "$title" \
      '(if type=="array" then . else (.sources // []) end)
       | .[] | select(.title == $t or .title == ($t + ".md")) | (.id // .source_id // "")
       | select(. != "" and . != "null")' 2>/dev/null)
  if [ ${#source_ids[@]} -gt 0 ]; then
    for sid in "${source_ids[@]}"; do
      echo "Deleting source ID: $sid (title: $title)"
      nlm source delete "$sid" --confirm || true
    done
  else
    echo "No existing source found for title: $title — skipping delete"
  fi
}

# 3. Reusable Sync Function
sync_bundle() {
  local title="$1"
  shift
  local bundle="$OUTDIR/${title}.md"

  echo ">>> Creating Bundle: $title"
  {
    echo "# ${title}"
    echo
    for file in "$@"; do
      echo "--- SOURCE: ${file#./} ---"
      echo
      cat "$file"
      echo
    done
  } > "$bundle"

  # Pass bare title; helper matches both "$title" and "$title.md".
  delete_sources_by_title "$NB_ID" "$title"
  if ! nlm source add "$NB_ID" --title "$title" --file "$bundle" --wait 2>&1 | tee "$RUNNER_TEMP/nlm-add.log"; then
    echo "::error::nlm source add failed for $title (bundle: $bundle, $(wc -c < "$bundle") bytes)"
    echo "::group::Last 50 lines of nlm output"
    tail -50 "$RUNNER_TEMP/nlm-add.log"
    echo "::endgroup::"
    exit 1
  fi
}

# --- PART A: Root-Level Files ---
if echo "$CHANGED_FILES" | grep -qE '^[^/]+\.md$'; then
  mapfile -d '' ROOT_MD < <(find . -maxdepth 1 -type f -name '*.md' -not -path '*/.*' -print0)
  if [ ${#ROOT_MD[@]} -gt 0 ]; then
    sync_bundle "Root_Files" "${ROOT_MD[@]}"
  else
    echo ">>> No root-level .md files remaining. Pruning source."
    delete_sources_by_title "$NB_ID" "Root_Files"
  fi
fi

# --- PART B: Top-Level Folder Bundles ---
# Folders come from the changed paths, so deleted folders are pruned too
CHANGED_DIRS=$(printf '%s\n' "$CHANGED_FILES" | awk -F/ 'NF > 1 { print $1 }' | sort -u)

while IFS= read -r DIR_NAME; do
  [ -n "$DIR_NAME" ] || continue

  # Filter out non-content directories
  case "$DIR_NAME" in
    .*|node_modules|venv) continue ;;
  esac

  MD_FILES=()
  if [ -d "$DIR_NAME" ]; then
    mapfile -d '' MD_FILES < <(find "$DIR_NAME" -type f -name '*.md' -not -path '*/.*' -print0)
  fi
  if [ ${#MD_FILES[@]} -gt 0 ]; then
    sync_bundle "$DIR_NAME" "${MD_FILES[@]}"
  else
    echo ">>> No .md files remaining in $DIR_NAME. Pruning source."
    delete_sources_by_title "$NB_ID" "$DIR_NAME"
  fi
done <<< "$CHANGED_DIRS"

echo "--- Sync Process Complete ---"
