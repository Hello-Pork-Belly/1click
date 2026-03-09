#!/bin/sh

html__log_error() {
  if command -v log_error >/dev/null 2>&1; then
    log_error "$*"
  else
    printf 'ERROR: %s\n' "$*" >&2
  fi
}

html_require_python() {
  command -v python3 >/dev/null 2>&1 || {
    html__log_error "python3 not found"
    return 1
  }
}

html_find_latest_jsonl() {
  html_root=${HZ_REPO_ROOT:-${REPO_ROOT:-}}
  if [ -z "${html_root}" ]; then
    html_root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
  fi

  [ -d "${html_root}/records" ] || return 1

  latest_jsonl=$(find "${html_root}/records" -type f -name '*.jsonl' -print0 2>/dev/null | xargs -0 ls -1t 2>/dev/null | head -n 1 || true)
  [ -n "${latest_jsonl}" ] || return 1
  printf '%s\n' "${latest_jsonl}"
}

render_jsonl_to_html() {
  html_input=${1:-}
  html_output=${2:-}

  [ -n "${html_input}" ] || {
    html__log_error "missing input path"
    return 1
  }
  [ -f "${html_input}" ] || {
    html__log_error "input not found: ${html_input}"
    return 1
  }
  [ -n "${html_output}" ] || {
    html__log_error "missing output path"
    return 1
  }

  html_require_python || return 1

  python3 - "${html_input}" "${html_output}" <<'PY'
import datetime
import html
import json
import sys
from collections import Counter
from pathlib import Path

src = Path(sys.argv[1])
out = Path(sys.argv[2])
rows = []
levels = Counter()

for raw_line in src.read_text(encoding="utf-8", errors="replace").splitlines():
    line = raw_line.strip()
    if not line:
        continue
    try:
        obj = json.loads(line)
    except Exception:
        continue
    level = str(obj.get("level", ""))
    row = {
        "ts": str(obj.get("ts", obj.get("timestamp", ""))),
        "level": level,
        "phase": str(obj.get("phase", "")),
        "step": str(obj.get("step", "")),
        "status": str(obj.get("status", "")),
        "message": str(obj.get("msg", obj.get("message", ""))),
    }
    rows.append(row)
    levels[level or "UNKNOWN"] += 1

generated_at = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
title = f"Horizon Execution Report - {src.name}"

summary_bits = []
for level in sorted(levels):
    summary_bits.append(
        f"<span class='pill'><strong>{html.escape(level)}</strong>: {levels[level]}</span>"
    )
if not summary_bits:
    summary_bits.append("<span class='pill'><strong>EMPTY</strong>: 0</span>")

entry_rows = []
for row in rows:
    entry_rows.append(
        "<tr>"
        f"<td>{html.escape(row['ts'])}</td>"
        f"<td>{html.escape(row['level'])}</td>"
        f"<td>{html.escape(row['phase'])}</td>"
        f"<td>{html.escape(row['step'])}</td>"
        f"<td>{html.escape(row['status'])}</td>"
        f"<td>{html.escape(row['message'])}</td>"
        "</tr>"
    )
if not entry_rows:
    entry_rows.append("<tr><td colspan='6'>No entries</td></tr>")

doc = f"""<!DOCTYPE html>
<html lang=\"en\">
<head>
  <meta charset=\"utf-8\">
  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">
  <title>{html.escape(title)}</title>
  <style>
    body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; margin: 0; background: #f5f7fb; color: #172033; }}
    main {{ max-width: 1120px; margin: 0 auto; padding: 32px 20px 48px; }}
    h1 {{ margin: 0 0 8px; font-size: 28px; }}
    .meta {{ color: #5b6578; margin-bottom: 24px; }}
    .summary {{ display: flex; gap: 10px; flex-wrap: wrap; margin-bottom: 24px; }}
    .pill {{ background: #ffffff; border: 1px solid #d7ddea; border-radius: 999px; padding: 8px 12px; font-size: 14px; }}
    .card {{ background: #ffffff; border: 1px solid #d7ddea; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 30px rgba(18, 28, 45, 0.05); }}
    table {{ width: 100%; border-collapse: collapse; }}
    th, td {{ padding: 12px 14px; text-align: left; border-bottom: 1px solid #e6ebf4; vertical-align: top; }}
    th {{ background: #eef3fb; font-size: 12px; text-transform: uppercase; letter-spacing: 0.04em; color: #42506a; }}
    tr:nth-child(even) td {{ background: #fafcff; }}
    td {{ font-size: 14px; word-break: break-word; }}
  </style>
</head>
<body>
  <main>
    <h1>{html.escape(title)}</h1>
    <div class=\"meta\">Generated: {html.escape(generated_at)}</div>
    <section class=\"summary\">{''.join(summary_bits)}</section>
    <section class=\"card\">
      <table>
        <thead>
          <tr>
            <th>Timestamp</th>
            <th>Level</th>
            <th>Phase</th>
            <th>Step</th>
            <th>Status</th>
            <th>Message</th>
          </tr>
        </thead>
        <tbody>
          {''.join(entry_rows)}
        </tbody>
      </table>
    </section>
  </main>
</body>
</html>
"""
out.write_text(doc, encoding="utf-8")
PY
}

html_render_report() {
  render_jsonl_to_html "$@"
}
