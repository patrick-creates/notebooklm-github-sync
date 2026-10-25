# Changelog

All notable changes to this project are documented here. Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- `action.yml`: use it as `uses: patrick-creates/notebooklm-github-sync@v1` instead of copying the whole workflow. Inputs: `notebook-id`, `cookies`, `metadata`, `force-sync`.
- `tests/test_sync.sh`: checks the sync logic against a throwaway repo with the CLI mocked.

### Changed
- Sync logic moved from `sync_docs.yml` to `scripts/sync.sh`; `sync_docs.yml` is now a short example that calls the Action.
- The run stops with a clear error when the previous commit is missing (checkout without `fetch-depth: 0`), instead of a bare `git diff` failure.

### Fixed
- Deleting a whole top-level folder now removes its source from the notebook. Before, the folder was skipped because it no longer existed, and its stale source stayed.
- Deleting all root-level `.md` files now removes the `Root_Files` source.
- A change in `mydocs/` no longer also re-syncs `docs/` (folder match was a substring check).

## [1.0.0] – 2026-10-25

First tagged release.

### Added
- `sync_docs.yml`: GitHub Actions workflow that bundles `.md` files per top-level folder and uploads them as NotebookLM sources on every markdown push.
- Smart sync: only folders with changed files are re-uploaded; old sources with the same title are deleted first, so duplicates do not accumulate.
- Manual `workflow_dispatch` with a `force_sync` option to refresh all bundles.
- Auth check step that fails with a clear error when the NotebookLM session has expired.
- `setup.py`: one-time login via `notebooklm-mcp-cli`, then sets `NOTEBOOKLM_COOKIES`, `NOTEBOOKLM_METADATA` and `NOTEBOOK_ID` as repo secrets via GitHub CLI, or prints them for manual copy.
- MIT license, issue templates.
