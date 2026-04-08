# notebooklm-github-sync

![Python](https://img.shields.io/badge/python-3.8%2B-blue)
![License](https://img.shields.io/badge/license-MIT-green)
[![Blog post](https://img.shields.io/badge/guide-automategenius.io-orange)](https://www.automategenius.io/blog/github-notebooklm-sync-blog)

A GitHub Action that auto-syncs your repository's markdown files to Google NotebookLM on every push, keeping your AI notebook current without manual uploads.

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

```bash
pip install notebooklm-mcp-cli
python setup.py
```

Opens browser → Google login → credentials saved → GitHub secrets set automatically (requires [GitHub CLI](https://cli.github.com)) or printed for manual copy.

You'll need your **NOTEBOOK_ID**: open your notebook at [notebooklm.google.com](https://notebooklm.google.com) and copy the ID from the URL after `/notebook/`.

**2. Add the workflow to your repo**

Copy `sync_docs.yml` to `.github/workflows/sync_docs.yml` in the repo you want to sync.

**3. Push any `.md` file**

The Action runs automatically on every markdown push from here.

## Full guide

→ [Auto-Sync GitHub to NotebookLM with GitHub Actions — Setup Guide](https://www.automategenius.io/blog/github-notebooklm-sync-blog)

## Files

| File | Purpose |
|---|---|
| `setup.py` | One-time authentication — sets `NOTEBOOKLM_COOKIES`, `NOTEBOOKLM_METADATA`, `NOTEBOOK_ID` secrets |
| `sync_docs.yml` | GitHub Actions workflow template — copy to `.github/workflows/` in your target repo |

## Requirements

- Python 3.8+
- `notebooklm-mcp-cli` (installed by `setup.py`)
- GitHub repository with `.md` files
- Google account with access to a NotebookLM notebook
- Optional: [GitHub CLI](https://cli.github.com) for automated secret setup

## Limitations

- **Cookie expiration:** Google session cookies expire periodically. When the Action fails with an auth error, re-run `python setup.py` and update `NOTEBOOKLM_COOKIES` and `NOTEBOOKLM_METADATA` in GitHub Settings → Secrets with the fresh values. Takes about 5 minutes.
- **Free accounts only:** This tool does not require NotebookLM Enterprise or Google Cloud Platform. It works with free NotebookLM accounts. Enterprise-grade GCS sync is out of scope.
- **Markdown only:** Only `.md` files are synced. Other file types are ignored.
