# Large Asset Publish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Optimize the current Unity project safely, rewrite the unpushed oversized history, and publish the verified latest state to `origin/main`.

**Architecture:** Preserve lossy inputs in an external backup, resize only qualifying 4K PNGs, and move unsafe-to-rewrite large binary assets to Git LFS. Collapse the two unpushed commits back onto `origin/main`, stage the resulting latest worktree, validate assets and outgoing Git objects, then push and verify the remote SHA.

**Tech Stack:** PowerShell 7/Windows PowerShell, Python 3 with Pillow, Git 2.53, Git LFS 3.7, Unity Editor 6000.0.23f1, GitHub CLI.

---

### Task 1: Preflight and rollback snapshot

**Files:**
- Read: `ProjectSettings/ProjectVersion.txt`
- Read: `.gitignore`
- Read: `.gitattributes`
- Backup externally: qualifying PNGs, oversized TerrainData assets, and Git metadata references

- [ ] **Step 1: Verify required tools and authentication**

Run `python --version`, import Pillow, run `git lfs version`, `gh --version`, `gh auth status`, and verify Unity Editor `6000.0.23f1` exists.

- [ ] **Step 2: Record repository state**

Record `HEAD`, `origin/main`, branch name, status counts, outgoing commits, and every outgoing blob at least 50 MiB.

- [ ] **Step 3: Create rollback references and external backups**

Create a local backup branch at the current `HEAD`. Copy each qualifying PNG and the two TerrainData assets into a timestamped directory outside `C:\Users\whees\TheBlock`, preserving relative paths.

- [ ] **Step 4: Verify backup integrity**

Compare SHA-256 hashes of every source and backup file. Stop if any pair differs.

### Task 2: Optimize qualifying PNG assets

**Files:**
- Modify: `Assets/Real Landscapes - Valley Forest/Content/Textures/**/*.png` only when the file is 4096x4096 and larger than 50 MiB
- Preserve: matching `.meta` files unchanged

- [ ] **Step 1: Capture baseline image metadata**

For every qualifying PNG, record path, byte size, dimensions, mode, and alpha presence.

- [ ] **Step 2: Resize deterministically**

Use Pillow `Image.Resampling.LANCZOS` to resize to 2048x2048, save to a temporary PNG beside the source, decode the temporary output, then atomically replace the source only after successful validation.

- [ ] **Step 3: Validate every resized file**

Require successful decode, 2048x2048 dimensions, unchanged alpha presence, smaller byte size, unchanged `.meta` SHA-256, and a valid PNG signature. Restore the source from backup if any check fails.

### Task 3: Configure Git LFS and rebuild outgoing history

**Files:**
- Modify: `.gitattributes`
- Rewrite locally: commits after `origin/main`

- [ ] **Step 1: Collapse unpushed history without altering the worktree**

Run `git reset --mixed origin/main` after the backup branch exists. Confirm the worktree contents remain present and the backup branch still resolves to the former `HEAD`.

- [ ] **Step 2: Add exact LFS rules for unsafe large binaries**

Track the two oversized TerrainData paths and any remaining current file at least 100 MiB. If the generated regular Git pack remains above 2 GiB, add exact LFS rules for the largest remaining binary files until the pack is below the limit; do not blanket-track Unity text assets.

- [ ] **Step 3: Stage the latest intended worktree**

Scan untracked scripts/configuration for credentials, exclude local-only credential-bearing files, then stage the current project state including intended modifications, additions, deletions, design, and plan documents.

- [ ] **Step 4: Verify LFS conversion**

Run `git lfs status`, `git lfs fsck`, inspect pointer files for every LFS-tracked path, and confirm no staged regular Git blob reaches 100 MiB.

### Task 4: Validate Unity and outgoing repository

**Files:**
- Read/validate: the full staged Unity project
- Generate outside tracked source: Unity batch log

- [ ] **Step 1: Run repository checks**

Run `git diff --cached --check`, inspect staged status and change counts, verify no secret pattern is staged, and calculate outgoing regular Git and LFS totals.

- [ ] **Step 2: Run Unity batch validation**

Launch `C:\Program Files\Unity\Hub\Editor\6000.0.23f1\Editor\Unity.exe -batchmode -quit -projectPath C:\Users\whees\TheBlock -logFile <external-log-path>`. Require exit code zero and inspect the log for import, serialization, missing-script, and asset database errors introduced by the conversion.

- [ ] **Step 3: Recheck repository state after Unity import**

Review any Unity-generated changes. Stage only legitimate deterministic project updates and repeat Git/LFS/object-size checks.

### Task 5: Commit, push, and verify

**Files:**
- Commit: all approved latest project changes

- [ ] **Step 1: Commit using Lore protocol**

Create one intentional commit explaining the GitHub limits, hybrid optimization, rejected destructive TerrainData resampling, validation performed, and remaining risks.

- [ ] **Step 2: Push main**

Push `main` to `origin/main`, allowing Git LFS to upload managed objects. Stop on authentication, quota, or server rejection and preserve the local commit plus backup branch.

- [ ] **Step 3: Verify publication**

Fetch/inspect the remote ref and require local `HEAD`, `origin/main`, and `git ls-remote origin refs/heads/main` to match. Confirm the working tree state and retain the external backup location in the final report.
