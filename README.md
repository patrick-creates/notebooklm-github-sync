# notebooklm-github-sync

![Python](https://img.shields.io/badge/python-3.8%2B-blue)
![License](https://img.shields.io/badge/license-MIT-orange)
[![Blog post](https://img.shields.io/badge/guide-telosignal.com-green)](https://www.telosignal.com/blog/github-notebooklm-sync-blog)

**Your NotebookLM notebook goes stale the moment your repo docs change — and re-uploading markdown by hand doesn't scale.**

A GitHub Action that auto-syncs your repository's markdown files to Google NotebookLM on every push, keeping your AI notebook current without manual uploads.

![How it works: git push → GitHub Actions bundles docs/ into docs.md → NotebookLM source replaced](./how-it-works.gif)

⭐ If this saves you manual uploads, a star helps others find it.

## What it does

- Watches for `.md` file pushes in your repo
- Groups files by top-level folder into one source each (`docs/` → `docs.md`)
- Deletes the old source, uploads a fresh bundle — no duplicate accumulation
- Only re-syncs folders that contain changed files (31-second runs on normal pushes)
- Force-sync option to refresh everything at once

## Why this exists

Most NotebookLM sync approaches either require enterprise infrastructure or aren't designed as GitHub Actions:

| Approach | Target user | Limitation |
|----------|-------------|------------|
| `storage-notebooklm-sync` | Enterprise users with GCS | Requires NotebookLM Enterprise + Google Cloud setup |
| `notebooklm-mcp-cli` | Developers using Claude/Cursor | General-purpose CLI — not a GitHub Action, no CI/CD |
| Manual upload | Everyone | Breaks the moment you forget. Doesn't scale. |
| **This tool** | **Any developer with a free NotebookLM account** | Cookie expiration requires periodic re-auth (~5 min) |

This tool targets the common case: a developer who wants their docs notebook to stay current, using only a free Google account.

## Quick start

**1. Authenticate (one time)**

Run this inside a clone of the repo you want to sync — the secrets go to that repo:

```bash
pip install notebooklm-mcp-cli
curl -O https://raw.githubusercontent.com/patrick-creates/notebooklm-github-sync/master/nlm_auth.py
python nlm_auth.py
```

Opens browser → Google login → credentials saved → GitHub secrets set automatically (requires [GitHub CLI](https://cli.github.com)) or printed for manual copy. The script prints which repo it writes to; use `--repo owner/repo` to pick another.

You'll need your **NOTEBOOK_ID**: open your notebook at [notebooklm.google.com](https://notebooklm.google.com) and copy the ID from the URL after `/notebook/`.

**2. Add the workflow to your repo**

Create `.github/workflows/sync_docs.yml` in the repo you want to sync (or copy [`sync_docs.yml`](./sync_docs.yml)):

```yaml
name: Sync Repo to NotebookLM

on:
  push:
    paths:
      - '**.md'
  workflow_dispatch:
    inputs:
      force_sync:
        description: 'Force sync all bundles'
        type: boolean
        default: false

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0   # needed to see which files changed

      - uses: patrick-creates/notebooklm-github-sync@v1
        with:
          notebook-id: ${{ secrets.NOTEBOOK_ID }}
          cookies: ${{ secrets.NOTEBOOKLM_COOKIES }}
          metadata: ${{ secrets.NOTEBOOKLM_METADATA }}
          force-sync: ${{ inputs.force_sync || false }}
```

| Input | Required | Default | Purpose |
|---|---|---|---|
| `notebook-id` | yes | — | ID from the notebook URL |
| `cookies` | yes | — | `NOTEBOOKLM_COOKIES` secret from `nlm_auth.py` |
| `metadata` | no | `{}` | `NOTEBOOKLM_METADATA` secret from `nlm_auth.py` |
| `force-sync` | no | `false` | Re-upload every folder, not only changed ones |

**3. Push any `.md` file**

The Action runs automatically on every markdown push from here.

## Full guide

→ [Auto-Sync GitHub to NotebookLM with GitHub Actions — Setup Guide](https://www.telosignal.com/blog/github-notebooklm-sync-blog)

## Files

| File | Purpose |
|---|---|
| `nlm_auth.py` | One-time authentication — sets `NOTEBOOKLM_COOKIES`, `NOTEBOOKLM_METADATA`, `NOTEBOOK_ID` secrets |
| `action.yml` | The Action: installs the CLI, restores the login, runs the sync |
| `scripts/sync.sh` | Bundling and upload logic |
| `sync_docs.yml` | Example workflow — copy to `.github/workflows/` in your target repo |
| `tests/test_sync.sh` | Runs the sync logic against a throwaway repo with the CLI mocked: `bash tests/test_sync.sh` |

## Requirements

- Python 3.8+
- `notebooklm-mcp-cli` (installed by `nlm_auth.py`)
- GitHub repository with `.md` files
- Google account with access to a NotebookLM notebook
- Optional: [GitHub CLI](https://cli.github.com) for automated secret setup

## Limitations

- **Cookie expiration:** Google session cookies expire periodically. When the Action fails with an auth error, re-run `python nlm_auth.py` and update `NOTEBOOKLM_COOKIES` and `NOTEBOOKLM_METADATA` in GitHub Settings → Secrets with the fresh values. Takes about 5 minutes.
- **Free accounts only:** This tool does not require NotebookLM Enterprise or Google Cloud Platform. It works with free NotebookLM accounts. Enterprise-grade GCS sync is out of scope.
- **Markdown only:** Only `.md` files are synced. Other file types are ignored.
