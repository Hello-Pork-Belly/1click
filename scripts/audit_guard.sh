#!/usr/bin/env bash
set -euo pipefail

# audit_guard.sh
# Purpose: enforce audit worktree read-only/clean invariants before any audit run.
# Run from audit worktree (e.g. ~/Documents/1click-audit/1click).

fail() { echo "FAIL: $1"; return 1; }
pass() { echo "PASS: $1"; }
info() { echo "INFO: $1"; }

rc=0

echo "== audit_guard =="

# 1) worktree identity
echo "[1] worktree identity"
inside="$(git rev-parse --is-inside-work-tree 2>/dev/null || true)"
if [[ "$inside" != "true" ]]; then
  fail "not inside a git worktree (git rev-parse --is-inside-work-tree != true)" || rc=1
else
  pass "inside git worktree"
fi

branch="$(git branch --show-current 2>/dev/null || true)"
if [[ "$branch" != "wt/audit" ]]; then
  fail "branch must be wt/audit (current: '${branch}'). Fix: git checkout wt/audit" || rc=1
else
  pass "branch is wt/audit"
fi

# 2) hooks disabled (prevent JOURNAL contamination)
echo "[2] hooks disabled"
hooksPath="$(git config --get core.hooksPath 2>/dev/null || true)"
if [[ "$hooksPath" != "/dev/null" ]]; then
  fail "core.hooksPath must be /dev/null (current: '${hooksPath:-<unset>}'). Fix: git config core.hooksPath /dev/null" || rc=1
else
  pass "core.hooksPath=/dev/null"
fi

# 3) working tree clean
echo "[3] working tree clean"
porcelain="$(git status --porcelain 2>/dev/null || true)"
if [[ -n "$porcelain" ]]; then
  fail "working tree not clean (git status --porcelain not empty). Fix: git restore --staged . && git restore . (or reset/clean as appropriate)" || rc=1
  echo "$porcelain"
else
  pass "working tree clean"
fi

# 4) HEAD aligned with origin/main (Hard Truth layer)
echo "[4] HEAD aligned with origin/main"
git fetch --all --prune >/dev/null 2>&1 || true

head_sha="$(git rev-parse HEAD 2>/dev/null || true)"
origin_main_sha="$(git rev-parse origin/main 2>/dev/null || true)"
if [[ -z "$head_sha" || -z "$origin_main_sha" ]]; then
  fail "cannot resolve HEAD or origin/main. Fix: git fetch --all --prune" || rc=1
else
  if [[ "$head_sha" != "$origin_main_sha" ]]; then
    fail "HEAD != origin/main (HEAD=$head_sha origin/main=$origin_main_sha). Fix: git reset --hard origin/main" || rc=1
  else
    pass "HEAD matches origin/main ($head_sha)"
  fi
fi

# 5) read-only reminder (soft)
echo "[5] read-only reminder"
echo "WARNING: audit worktree is read-only in practice; do NOT commit/push from this directory."

echo "== audit_guard result =="
if [[ "$rc" -ne 0 ]]; then
  echo "FAIL (one or more checks failed)"
  exit 1
fi
echo "PASS (all checks passed)"
exit 0
