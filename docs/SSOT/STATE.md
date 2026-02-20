# Project State Ledger (SSOT)

This file is the single source of truth for project progress in 1click.

Last updated: 2026-02-21
Owner: Pork-Belly

## Reality Snapshot A0 (remote)

- Repository: https://github.com/Hello-Pork-Belly/1click
- Captured at: 2026-02-20T12:36:19Z
- main HEAD: `49a089a58f0d579db7f805049eae8e8f9e9ba701`
  - https://github.com/Hello-Pork-Belly/1click/commit/49a089a58f0d579db7f805049eae8e8f9e9ba701
- PR #1: https://github.com/Hello-Pork-Belly/1click/pull/1
  - merged: true (`state=MERGED`, `mergedAt=2026-02-18T11:12:57Z`)
  - base/head: `cd31d44d65a671ca05100ff63b55581c07027a1f` / `ab7c28c65e5ddee34a820acf38b142be2f400e31`
  - merge commit: `aac4c6c11f406bce69f6db05f1ce421c64ec1f36`
    - https://github.com/Hello-Pork-Belly/1click/commit/aac4c6c11f406bce69f6db05f1ce421c64ec1f36
- PR #2: https://github.com/Hello-Pork-Belly/1click/pull/2
  - merged: true (`state=MERGED`, `mergedAt=2026-02-18T12:04:39Z`)
  - base/head: `aac4c6c11f406bce69f6db05f1ce421c64ec1f36` / `58ee35fa22056f870ea8bfadfebedc9e7c09e04e`
  - merge commit: `f8417212878ffce5d042b07b9cb84d633bd46300`
    - https://github.com/Hello-Pork-Belly/1click/commit/f8417212878ffce5d042b07b9cb84d633bd46300
- PR #3: https://github.com/Hello-Pork-Belly/1click/pull/3
  - merged: true (`state=MERGED`, `mergedAt=2026-02-20T09:43:21Z`)
  - base/head: `f8417212878ffce5d042b07b9cb84d633bd46300` / `d16145868dbe00f4beef70958db9e3af5d8a8859`
  - merge commit: `8a00ef95c56e5e7ae975bfafe29b3a7d80d76d0a`
    - https://github.com/Hello-Pork-Belly/1click/commit/8a00ef95c56e5e7ae975bfafe29b3a7d80d76d0a
- PR #4: https://github.com/Hello-Pork-Belly/1click/pull/4
  - merged: true (`state=MERGED`, `mergedAt=2026-02-20T10:42:07Z`)
  - merge commit: `3dd393da7aeacfc7a9377abb68181e1d4f827057`
    - https://github.com/Hello-Pork-Belly/1click/commit/3dd393da7aeacfc7a9377abb68181e1d4f827057
  - main updated to merge commit `3dd393d...`
- PR #5: https://github.com/Hello-Pork-Belly/1click/pull/5
  - merged: true (`state=MERGED`, `mergedAt=2026-02-20T11:18:53Z`)
  - merge commit: `49a089a58f0d579db7f805049eae8e8f9e9ba701` (`49a089a`)
    - https://github.com/Hello-Pork-Belly/1click/commit/49a089a58f0d579db7f805049eae8e8f9e9ba701
  - main updated to merge commit `49a089a...` (A0 snapshot now covers PR #1/#2/#3/#4/#5)
- Actions / Workflows:
  - Actions page: https://github.com/Hello-Pork-Belly/1click/actions
  - `.github/workflows` is missing (404): https://github.com/Hello-Pork-Belly/1click/tree/main/.github/workflows
  - `gh api "repos/Hello-Pork-Belly/1click/contents/.github/workflows?ref=main"` returned `404 Not Found`.
  - `gh run list -R Hello-Pork-Belly/1click --limit 20` returned no rows (`getting started / no runs`).
  - workflows tree URL: https://github.com/Hello-Pork-Belly/1click/tree/main/.github/workflows
- Releases / Tags:
  - Releases page: https://github.com/Hello-Pork-Belly/1click/releases
  - `gh release list -R Hello-Pork-Belly/1click --limit 50` returned no rows.
  - Tags evidence uses HTTPS/API only (SSH is not used for SSOT audit evidence):
    - `git ls-remote --tags https://github.com/Hello-Pork-Belly/1click.git | head -n 20` -> no rows
    - `gh api "repos/Hello-Pork-Belly/1click/tags?per_page=10" --jq '.[] | {name:.name, sha:.commit.sha}'` -> no rows

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

- A0 snapshot closeout now includes merged facts for PR #1/#2/#3/#4/#5 (latest main aligned).

- Legacy imported Done/PR history moved out of truth surface:
  - `docs/SSOT/provenance/legacy-done-list.md`
  - Provenance only; not source of truth for 1click.

## Doing

- none

## Next

- T-A0-001 Keep A0 snapshot current on every merge (main HEAD / PR links / Actions / Releases evidence).
