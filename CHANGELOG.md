# Changelog

All notable changes to this project are documented here. Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [1.0.0] – 2026-10-25

First tagged release.

### Added
- `sync_docs.yml`: GitHub Actions workflow that bundles `.md` files per top-level folder and uploads them as NotebookLM sources on every markdown push.
- Smart sync: only folders with changed files are re-uploaded; old sources with the same title are deleted first, so duplicates do not accumulate.
- Manual `workflow_dispatch` with a `force_sync` option to refresh all bundles.
- Auth check step that fails with a clear error when the NotebookLM session has expired.
- `setup.py`: one-time login via `notebooklm-mcp-cli`, then sets `NOTEBOOKLM_COOKIES`, `NOTEBOOKLM_METADATA` and `NOTEBOOK_ID` as repo secrets via GitHub CLI, or prints them for manual copy.
- MIT license, issue templates.
