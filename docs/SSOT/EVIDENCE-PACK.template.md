## Header (MUST)

- mode: routine|milestone
- captured_at_utc: YYYY-MM-DDTHH:MM:SSZ
- main_sha: <40-hex>  # MUST equal (1) and (2); mismatch => STOP/BLOCKED

## Anchoring Rules (MUST)

- Hard Truth for main HEAD must come from this Evidence Pack only:
  (1) git ls-remote ... refs/heads/main
  (2) gh api .../commits/main --jq .sha
- First gate: verify (1)==(2). If mismatch => STOP/BLOCKED and stop.
- All SSOT/standard references MUST be SHA-pinned using main_sha:
  raw.githubusercontent.com/<owner>/<repo>/<main_sha>/...
  Do NOT use /main/ for truth citations.
- mode=routine: missing evidence => UNKNOWN + Evidence Gaps (do NOT STOP/BLOCKED),
  except (1)!=(2) (Hard Truth conflict) or standard missing at main_sha.

# Evidence Pack (verbatim outputs)
> Paste command + output blocks verbatim. Missing output => UNKNOWN (do not substitute with GitHub UI).

## (1) ls-remote main (Hard Truth)
```bash
git ls-remote https://github.com/Hello-Pork-Belly/1click.git refs/heads/main
```

```text
<PASTE_OUTPUT_VERBATIM>
```

## (2) gh api commits/main (Hard Truth)

```bash
gh api repos/Hello-Pork-Belly/1click/commits/main --jq .sha
```

```text
<PASTE_OUTPUT_VERBATIM>
```

## (3a) merged PRs (recent) (Hard Truth helper)

```bash
gh pr list --repo Hello-Pork-Belly/1click --state merged --limit 3
```

```text
<PASTE_OUTPUT_VERBATIM>
```

## (3b) merged PR facts (at least 3 PRs)

```bash
gh pr view <PR_NUMBER_1> --repo Hello-Pork-Belly/1click --json number,state,mergedAt,mergeCommit,url
gh pr view <PR_NUMBER_2> --repo Hello-Pork-Belly/1click --json number,state,mergedAt,mergeCommit,url
gh pr view <PR_NUMBER_3> --repo Hello-Pork-Belly/1click --json number,state,mergedAt,mergeCommit,url
```

```json
<PASTE_OUTPUT_VERBATIM>
```

## (4) open PRs

```bash
gh pr list --repo Hello-Pork-Belly/1click --state open --limit 50
```

```text
<PASTE_OUTPUT_VERBATIM>
```

## (5) Actions runs (if no workflows/runs, keep output as-is)

```bash
gh run list --repo Hello-Pork-Belly/1click --limit 20 || true
```

```text
<PASTE_OUTPUT_VERBATIM>
```

## (6) Releases (if none, keep output as-is)

```bash
gh release list --repo Hello-Pork-Belly/1click --limit 20 || true
```

```text
<PASTE_OUTPUT_VERBATIM>
```

## (7a) Tags via HTTPS only (D-012: HTTPS/API only; NO SSH)

```bash
git ls-remote --tags https://github.com/Hello-Pork-Belly/1click.git | head -n 20
```

```text
<PASTE_OUTPUT_VERBATIM>
```

## (7b) Tags via GitHub API (D-012: HTTPS/API only; NO SSH)

```bash
gh api "repos/Hello-Pork-Belly/1click/tags?per_page=10"
```

```json
<PASTE_OUTPUT_VERBATIM>
```
