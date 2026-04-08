# notebooklm-github-sync

Auto-sync your GitHub markdown docs to NotebookLM on every push.
No manual uploads. No stale AI answers.

## What it does

- Watches for `.md` file pushes in your repo
- Groups files by top-level folder into one source each (`docs/` → `docs.md`)
- Deletes the old source, uploads a fresh bundle — no duplicate accumulation
- Only re-syncs folders that contain changed files (31-second runs on normal pushes)
- Force-sync option to refresh everything at once

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

→ [How I Auto-Sync My GitHub Docs to NotebookLM on Every Push](https://www.automategenius.io/blog/github-notebooklm-sync-blog)

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

## Known limitation

Google session cookies expire periodically. When the Action fails with an auth error, re-run `python setup.py` and update `NOTEBOOKLM_COOKIES` and `NOTEBOOKLM_METADATA` in GitHub Settings → Secrets with the fresh values. Takes about 5 minutes.
