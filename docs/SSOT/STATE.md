# Project State Ledger (SSOT)

This file is the single source of truth for project progress in 1click.

Last updated: 2026-02-22
Owner: Pork-Belly

## Reality Snapshot A0 (remote)

- Repository: https://github.com/Hello-Pork-Belly/1click
- Milestone: governance change (PR #23)
- Snapshot Semantics (milestone-gated):
  - `pre_merge_main_head` = pre-merge hard truth (`git ls-remote refs/heads/main` == `gh api repos/<repo>/commits/main`).
  - `post_merge_main_head` = post-merge hard truth (`git ls-remote refs/heads/main` == `gh api repos/<repo>/commits/main`).
  - `main_head` is the compatibility alias and is defined as `post_merge_main_head` (`main_head == post_merge_main_head`).
  - Sentinel/auditor check runs only on milestone snapshot events and verifies `post_merge_main_head == current ls-remote == current gh api`.
  - Milestone triggers: phase change / release tag / security policy change / governance change.
  - Snapshot refresh is no longer required for every merge; ordinary docs-only fixes do not force A0 refresh unless they change gates/rules/milestone status.
- Captured at: 2026-02-22T10:14:33Z
  - pre_merge_main_head: `953d3fc5700dc423d37fab5a0b6823adcb48b208`
  - post_merge_main_head: `aed69ee7e0d8157c339b716a817b2e8d77caedd7`
main_head: `aed69ee7e0d8157c339b716a817b2e8d77caedd7`
  - commit/main URL: https://github.com/Hello-Pork-Belly/1click/commit/main (symbolic pointer)
  - commit/sha URL: https://github.com/Hello-Pork-Belly/1click/commit/aed69ee7e0d8157c339b716a817b2e8d77caedd7
- Merged PR facts (#1-#24):
  - PR #1: https://github.com/Hello-Pork-Belly/1click/pull/1
    - mergedAt: `2026-02-18T11:12:57Z`
    - merge commit: https://github.com/Hello-Pork-Belly/1click/commit/aac4c6c11f406bce69f6db05f1ce421c64ec1f36
  - PR #2: https://github.com/Hello-Pork-Belly/1click/pull/2
    - mergedAt: `2026-02-18T12:04:39Z`
    - merge commit: https://github.com/Hello-Pork-Belly/1click/commit/f8417212878ffce5d042b07b9cb84d633bd46300
  - PR #3: https://github.com/Hello-Pork-Belly/1click/pull/3
    - mergedAt: `2026-02-20T09:43:21Z`
    - merge commit: https://github.com/Hello-Pork-Belly/1click/commit/8a00ef95c56e5e7ae975bfafe29b3a7d80d76d0a
  - PR #4: https://github.com/Hello-Pork-Belly/1click/pull/4
    - mergedAt: `2026-02-20T10:42:07Z`
    - merge commit: https://github.com/Hello-Pork-Belly/1click/commit/3dd393da7aeacfc7a9377abb68181e1d4f827057
  - PR #5: https://github.com/Hello-Pork-Belly/1click/pull/5
    - mergedAt: `2026-02-20T11:18:53Z`
    - merge commit: https://github.com/Hello-Pork-Belly/1click/commit/49a089a58f0d579db7f805049eae8e8f9e9ba701
  - PR #6: https://github.com/Hello-Pork-Belly/1click/pull/6
    - mergedAt: `2026-02-20T12:46:05Z`
    - merge commit: https://github.com/Hello-Pork-Belly/1click/commit/a6e64de4eaca4d42af63253691127d15aa7191ba
  - PR #7: https://github.com/Hello-Pork-Belly/1click/pull/7
    - mergedAt: `2026-02-20T12:47:48Z`
    - merge commit: https://github.com/Hello-Pork-Belly/1click/commit/fbe949b14f410886020ed7b3ffb8af3addef2356
  - PR #8: https://github.com/Hello-Pork-Belly/1click/pull/8
    - mergedAt: `2026-02-20T12:49:47Z`
    - merge commit: https://github.com/Hello-Pork-Belly/1click/commit/b16d5b96931c1622cb58783420751de7cb455942
  - PR #9: https://github.com/Hello-Pork-Belly/1click/pull/9
    - mergedAt: `2026-02-21T08:42:10Z`
    - merge commit: https://github.com/Hello-Pork-Belly/1click/commit/16d76c4b99c45339899ffadf9760d7e1d87fc5f3
  - PR #10: https://github.com/Hello-Pork-Belly/1click/pull/10
    - mergedAt: `2026-02-21T09:15:13Z`
    - merge commit: https://github.com/Hello-Pork-Belly/1click/commit/7d0f3de285dc29e29fc1ec57a3159d7112ce1d26
  - PR #11: https://github.com/Hello-Pork-Belly/1click/pull/11
    - mergedAt: `2026-02-21T10:17:26Z`
    - merge commit: https://github.com/Hello-Pork-Belly/1click/commit/b39c83688602d43566430bf1b6728a75a96bf85c
  - PR #12: https://github.com/Hello-Pork-Belly/1click/pull/12
    - mergedAt: `2026-02-21T10:30:26Z`
    - merge commit: https://github.com/Hello-Pork-Belly/1click/commit/d9ad95c1416116cc5b50b18cadca4fb3734a4219
  - PR #13: https://github.com/Hello-Pork-Belly/1click/pull/13
    - mergedAt: `2026-02-21T10:49:36Z`
    - merge commit: https://github.com/Hello-Pork-Belly/1click/commit/f3d76fd3fe2e508b0ad3d1e2f1e940451ce75f9d
  - PR #14: https://github.com/Hello-Pork-Belly/1click/pull/14
    - mergedAt: `2026-02-21T10:53:08Z`
    - merge commit: https://github.com/Hello-Pork-Belly/1click/commit/f10c402e37182f6b45657116b6fc4d488f28e97e
  - PR #15: https://github.com/Hello-Pork-Belly/1click/pull/15
    - mergedAt: `2026-02-21T11:14:04Z`
    - merge commit: https://github.com/Hello-Pork-Belly/1click/commit/35842befecd6780f440e243858f629e8ed75cc61
  - PR #16: https://github.com/Hello-Pork-Belly/1click/pull/16
    - mergedAt: `2026-02-21T12:18:16Z`
    - merge commit: https://github.com/Hello-Pork-Belly/1click/commit/3dd31dce389a847512d8ff396e25f4951dd324db
  - PR #17: https://github.com/Hello-Pork-Belly/1click/pull/17
    - mergedAt: `2026-02-22T07:10:01Z`
    - merge commit: https://github.com/Hello-Pork-Belly/1click/commit/5ffa49b6754209faa101ddd5dfbd1f6d651cfc72
  - PR #18: https://github.com/Hello-Pork-Belly/1click/pull/18
    - mergedAt: `2026-02-22T07:24:42Z`
    - merge commit: https://github.com/Hello-Pork-Belly/1click/commit/6ad01bc8e5a8d3692518f3bc01ae3fdf6d0ea3ea
  - PR #19: https://github.com/Hello-Pork-Belly/1click/pull/19
    - mergedAt: `2026-02-22T07:28:58Z`
    - merge commit: https://github.com/Hello-Pork-Belly/1click/commit/d4d8477fd06c7c7ae394b3078560effbe0688e65
  - PR #20: https://github.com/Hello-Pork-Belly/1click/pull/20
    - mergedAt: `2026-02-22T08:16:23Z`
    - merge commit: https://github.com/Hello-Pork-Belly/1click/commit/c9ac15022a6b537245d885294957c68ec677ce17
  - PR #21: https://github.com/Hello-Pork-Belly/1click/pull/21
    - mergedAt: `2026-02-22T08:43:09Z`
    - merge commit: https://github.com/Hello-Pork-Belly/1click/commit/5519829601523e6e95f7cec069242664908b1d57
  - PR #22: https://github.com/Hello-Pork-Belly/1click/pull/22
    - mergedAt: `2026-02-22T09:00:42Z`
    - merge commit: https://github.com/Hello-Pork-Belly/1click/commit/14f54675507e14474af9933eb0116dd27d77473f
  - PR #23: https://github.com/Hello-Pork-Belly/1click/pull/23
    - mergedAt: `2026-02-22T09:32:17Z`
    - merge commit: https://github.com/Hello-Pork-Belly/1click/commit/953d3fc5700dc423d37fab5a0b6823adcb48b208
  - PR #24: https://github.com/Hello-Pork-Belly/1click/pull/24
    - mergedAt: `2026-02-22T09:47:20Z`
    - merge commit: https://github.com/Hello-Pork-Belly/1click/commit/aed69ee7e0d8157c339b716a817b2e8d77caedd7
  - remote-first precedence: use `git ls-remote refs/heads/main`, `gh api repos/<repo>/commits/main`, and `gh pr view`.
  - if UI rendering and command outputs differ, SSOT follows command outputs plus PR evidence pack.
  - hard evidence summary (post-merge evidence, verbatim):
    ```text
    (1)

    aed69ee7e0d8157c339b716a817b2e8d77caedd7	refs/heads/main

    (2)

    aed69ee7e0d8157c339b716a817b2e8d77caedd7

    (3)

    {"mergeCommit":{"oid":"aed69ee7e0d8157c339b716a817b2e8d77caedd7"},"mergedAt":"2026-02-22T09:47:20Z","number":24,"state":"MERGED","url":"https://github.com/Hello-Pork-Belly/1click/pull/24"}
    ```
- Actions / Workflows:
  - Actions page: https://github.com/Hello-Pork-Belly/1click/actions
  - `.github/workflows` missing (404): https://github.com/Hello-Pork-Belly/1click/tree/main/.github/workflows (repository has no workflow files)
  - `gh api "repos/Hello-Pork-Belly/1click/contents/.github/workflows?ref=main"` -> `404 Not Found`
  - `gh run list -R Hello-Pork-Belly/1click --limit 20` -> no rows (`no workflows / no runs`)
- Releases / Tags:
  - Releases page: https://github.com/Hello-Pork-Belly/1click/releases
  - `gh release list -R Hello-Pork-Belly/1click --limit 50` -> no rows
  - tags evidence transport: HTTPS/API only (SSH tag query forbidden)
  - `git ls-remote --tags https://github.com/Hello-Pork-Belly/1click.git | head -n 20` -> no rows
  - `gh api "repos/Hello-Pork-Belly/1click/tags?per_page=10" --jq '.[] | {name:.name, sha:.commit.sha}'` -> no rows
- Integrity gate before merge:
  - Run conflict-marker check on this file before merge and require zero hits.
  - Run separator-line check before merge and require zero hits.
  - Run branch-fragment/tailing-main check before merge and require zero hits.

## Phase Position

- Current Phase: `VERIFY`
- Phase truth source: `docs/PHASES.yml`
- Progress truth source: `docs/SSOT/STATE.md`

## Done (merged tasks)

- T-001 Import core framework + SSOT minimal set into 1click
  - Status: Done (moved from Doing to Done based on remote reality)
  - PR: https://github.com/Hello-Pork-Belly/1click/pull/1
  - Merge commit: https://github.com/Hello-Pork-Belly/1click/commit/aac4c6c11f406bce69f6db05f1ce421c64ec1f36
  - DoD verification at merge time: `make check` exit `0`

- A0 snapshot now records merged facts and remote reality including PR #5 anchor and PR #8 governance incident.

- Legacy imported Done/PR history moved out of truth surface:
  - `docs/SSOT/provenance/legacy-done-list.md`
  - Provenance only; not source of truth for 1click.

## Doing

- none

## Next

- T-A0-001 Keep A0 snapshot current on every milestone (phase change / release tag / security policy change / governance change).
  - Ordinary docs-only fixes do not force A0 refresh unless they change gates/rules/milestone status.
