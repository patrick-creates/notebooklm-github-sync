#!/usr/bin/env python3
"""
NotebookLM GitHub Sync — Setup Script

Authenticates with NotebookLM and configures GitHub secrets in one step.
Run this once to set up, and again whenever your session expires.

Usage:
    python setup.py
    python setup.py --repo owner/repo   # target a specific GitHub repo
"""

import argparse
import json
import os
import subprocess
import sys
from pathlib import Path


def run(cmd, capture=False, check=False):
    return subprocess.run(cmd, shell=True, capture_output=capture, text=True, check=check)


def profile_dir():
    return Path.home() / ".notebooklm-mcp-cli" / "profiles" / "default"


def install_cli():
    result = run("nlm --version", capture=True)
    if result.returncode != 0:
        print("Installing notebooklm-mcp-cli...")
        run("pip install notebooklm-mcp-cli", check=True)
        print()


def authenticate():
    print("Opening browser for Google authentication...")
    print("Log in with the Google account that has access to your NotebookLM notebook.\n")
    result = run("nlm login")
    if result.returncode != 0:
        print("Error: nlm login failed. Ensure notebooklm-mcp-cli is installed and retry.")
        sys.exit(1)
    print()


def read_auth():
    d = profile_dir()
    cookies_path = d / "cookies.json"
    metadata_path = d / "metadata.json"

    if not cookies_path.exists():
        print(f"Error: cookies.json not found at {d}")
        print("Authentication may have failed. Re-run setup.py and complete the browser login.")
        sys.exit(1)

    cookies = cookies_path.read_text()
    metadata = metadata_path.read_text() if metadata_path.exists() else "{}"

    return cookies, metadata


def get_notebook_id():
    print("Find your NOTEBOOK_ID:")
    print("  1. Go to https://notebooklm.google.com")
    print("  2. Open your notebook")
    print("  3. Copy the ID from the URL: notebooklm.google.com/notebook/<THIS_PART>\n")
    notebook_id = input("Paste your NOTEBOOK_ID: ").strip()
    if not notebook_id:
        print("Error: NOTEBOOK_ID cannot be empty.")
        sys.exit(1)
    return notebook_id


def set_secret(name, value, repo_flag):
    cmd = ["gh", "secret", "set", name]
    if repo_flag:
        cmd += ["-R", repo_flag]
    result = subprocess.run(cmd, input=value, text=True, capture_output=True)
    return result


def set_secrets_via_gh(cookies, metadata, notebook_id, repo_flag):
    secrets = [
        ("NOTEBOOKLM_COOKIES", cookies),
        ("NOTEBOOKLM_METADATA", metadata),
        ("NOTEBOOK_ID", notebook_id),
    ]
    failed = False
    for name, value in secrets:
        r = set_secret(name, value, repo_flag)
        if r.returncode != 0:
            print(f"gh secret set failed for {name}: {r.stderr.strip()}")
            failed = True
    if failed:
        print("Check that you're authenticated with `gh auth login`.")
        return False
    return True


def print_manual_instructions(cookies, metadata, notebook_id):
    print("\n" + "=" * 60)
    print("Add these secrets to your GitHub repo:")
    print("Repo → Settings → Secrets and variables → Actions → New repository secret")
    print("=" * 60)
    print("\nSecret name:  NOTEBOOKLM_COOKIES")
    print("Secret value:")
    print(cookies)
    print("\nSecret name:  NOTEBOOKLM_METADATA")
    print("Secret value:")
    print(metadata)
    print("\nSecret name:  NOTEBOOK_ID")
    print(f"Secret value: {notebook_id}")
    print("=" * 60)


def main():
    parser = argparse.ArgumentParser(description="Set up NotebookLM GitHub sync authentication.")
    parser.add_argument("--repo", help="GitHub repo (owner/repo) to set secrets on. Defaults to current repo.")
    args = parser.parse_args()

    print("NotebookLM GitHub Sync — Setup\n")

    install_cli()
    authenticate()

    cookies, metadata = read_auth()
    notebook_id = get_notebook_id()

    gh_available = run("gh --version", capture=True).returncode == 0
    if gh_available:
        print("\nSetting GitHub secrets via gh CLI...")
        if set_secrets_via_gh(cookies, metadata, notebook_id, args.repo):
            print("✓ NOTEBOOKLM_COOKIES set")
            print("✓ NOTEBOOKLM_METADATA set")
            print("✓ NOTEBOOK_ID set")
            print("\nSetup complete. Push a .md file to trigger the sync, or run the workflow manually.")
        else:
            print_manual_instructions(cookies, metadata, notebook_id)
    else:
        print("\ngh CLI not found — copy these secrets manually:")
        print_manual_instructions(cookies, metadata, notebook_id)
        print("\nOr install the GitHub CLI (https://cli.github.com) and re-run setup.py.")

    print()


if __name__ == "__main__":
    main()
