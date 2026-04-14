#!/usr/bin/env python3
import json
import re
import sys
import html
from pathlib import Path


def check_non_empty(output, expected):
    want = bool(expected.get("value", True))
    ok = bool(output.strip()) == want
    return ok, "output is non-empty" if ok else "output emptiness mismatch"


def check_max_chars(output, expected):
    limit = int(expected["value"])
    ok = len(output) <= limit
    return ok, f"len(output)={len(output)} <= {limit}" if ok else f"len(output)={len(output)} > {limit}"


def check_contains_any(output, expected):
    values = expected.get("values", [])
    lower = output.lower()
    ok = any(v.lower() in lower for v in values)
    return ok, "contains at least one expected token" if ok else f"missing any of: {values}"


def check_contains_all(output, expected):
    values = expected.get("values", [])
    lower = output.lower()
    missing = [v for v in values if v.lower() not in lower]
    ok = not missing
    return ok, "contains all expected tokens" if ok else f"missing: {missing}"


def check_contains_regex(output, expected):
    pattern = expected.get("value", "")
    if not pattern:
        return False, "missing regex pattern"
    ok = re.search(pattern, output, flags=re.S) is not None
    return ok, f"regex matched: {pattern}" if ok else f"regex not matched: {pattern}"


def check_must_not_contains_any(output, expected):
    values = expected.get("values", [])
    lower = output.lower()
    hits = [v for v in values if v.lower() in lower]
    ok = not hits
    return ok, "forbidden tokens are absent" if ok else f"forbidden tokens found: {hits}"


def parse_json_object(output):
    text = output.strip()
    try:
        return json.loads(text), None
    except Exception:
        pass

    match = re.search(r"\{.*\}", text, flags=re.S)
    if not match:
        return None, "no JSON object found"
    try:
        return json.loads(match.group(0)), None
    except Exception as exc:
        return None, f"invalid JSON object: {exc}"


def check_valid_json_object(output, expected):
    want = bool(expected.get("value", True))
    data, err = parse_json_object(output)
    ok = (data is not None and isinstance(data, dict)) == want
    return ok, "valid JSON object" if ok else f"json parse failed: {err}"


def check_json_has_keys(output, expected):
    data, err = parse_json_object(output)
    if not isinstance(data, dict):
        return False, f"json parse failed: {err}"
    keys = expected.get("values", [])
    missing = [k for k in keys if k not in data]
    ok = not missing
    return ok, "required keys exist" if ok else f"missing keys: {missing}"


def check_json_enum(output, expected):
    data, err = parse_json_object(output)
    if not isinstance(data, dict):
        return False, f"json parse failed: {err}"
    field = expected.get("field")
    values = expected.get("values", [])
    value = data.get(field)
    ok = value in values
    return ok, f"{field} in {values}" if ok else f"{field}={value} not in {values}"


CHECKERS = {
    "non_empty": check_non_empty,
    "max_chars": check_max_chars,
    "contains_any": check_contains_any,
    "contains_all": check_contains_all,
    "contains_regex": check_contains_regex,
    "must_not_contains_any": check_must_not_contains_any,
    "valid_json_object": check_valid_json_object,
    "json_has_keys": check_json_has_keys,
    "json_enum": check_json_enum,
}


def evaluate(record):
    output = record.get("answer", "")
    trace_lines = record.get("trace_lines", [])
    trace_text = "\n".join(trace_lines)
    checks = record.get("expected", {}).get("checks", [])
    failures = []

    for check in checks:
        kind = check.get("kind")
        checker = CHECKERS.get(kind)
        if checker is None:
            failures.append(f"unknown check kind: {kind}")
            continue
        ok, message = checker(output, check)
        if not ok:
            failures.append(f"{kind}: {message}")

    for tool in record.get("must_use_tools", []):
        if tool not in trace_text and tool not in record.get("output", ""):
            failures.append(f"must_use_tools: '{tool}' not found in output/trace")

    for tool in record.get("must_not_use_tools", []):
        if tool in trace_text or tool in record.get("output", ""):
            failures.append(f"must_not_use_tools: '{tool}' found in output/trace")

    if record.get("exit_code", 0) != 0:
        failures.append(f"non-zero exit code: {record['exit_code']}")

    passed = len(failures) == 0
    return passed, failures


def main():
    if len(sys.argv) != 3:
        print("Usage: score.py <run_file.jsonl> <report_file.html>", file=sys.stderr)
        sys.exit(1)

    run_file = Path(sys.argv[1])
    html_report_file = Path(sys.argv[2])
    if not run_file.exists():
        print(f"Run file not found: {run_file}", file=sys.stderr)
        sys.exit(1)

    records = []
    for line in run_file.read_text(encoding="utf-8").splitlines():
        if line.strip():
            records.append(json.loads(line))

    total = len(records)
    passed_count = 0
    report_rows = []
    for record in records:
        passed, failures = evaluate(record)
        if passed:
            passed_count += 1
        status = "PASS" if passed else "FAIL"
        report_rows.append((record, passed, failures))

    score = (passed_count / total * 100.0) if total else 0.0
    html_report_file.write_text(build_html_report(total, passed_count, score, report_rows), encoding="utf-8")
    print(f"Score: {score:.1f}% ({passed_count}/{total})")

    if passed_count != total:
        sys.exit(2)


def build_html_report(total, passed_count, score, report_rows):
    details_html = []
    for record, passed, failures in report_rows:
        status = "PASS" if passed else "FAIL"
        status_class = "pass" if passed else "fail"

        failure_items = "".join(f"<li>{html.escape(item)}</li>" for item in failures) if failures else "<li>None</li>"
        details_html.append(
            "<details>"
            f"<summary><strong>{html.escape(record.get('case_id', ''))}</strong> — "
            f"<span class=\"{status_class}\">{status}</span> | "
            f"routing={html.escape(record.get('routing_mode', ''))} | "
            f"latency={record.get('latency_ms', 0)}ms</summary>"
            "<div class=\"detail-block\">"
            f"<p><strong>Prompt:</strong> {html.escape(record.get('prompt', ''))}</p>"
            f"<p><strong>Answer:</strong></p><pre>{html.escape(record.get('answer', ''))}</pre>"
            f"<p><strong>Trace:</strong></p><pre>{html.escape(chr(10).join(record.get('trace_lines', [])))}</pre>"
            f"<p><strong>Failures:</strong></p><ul>{failure_items}</ul>"
            "</div>"
            "</details>"
        )

    return f"""<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>ToyBot Eval Report</title>
  <style>
    body {{ font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; margin: 24px; color: #1f2937; }}
    h1 {{ margin-bottom: 8px; }}
    .meta {{ margin-bottom: 18px; color: #4b5563; }}
    table {{ border-collapse: collapse; width: 100%; margin-bottom: 20px; }}
    th, td {{ border: 1px solid #e5e7eb; padding: 8px 10px; text-align: left; }}
    th {{ background: #f9fafb; }}
    .pass {{ color: #166534; font-weight: 600; }}
    .fail {{ color: #991b1b; font-weight: 600; }}
    details {{ margin-bottom: 12px; border: 1px solid #e5e7eb; border-radius: 8px; padding: 8px 10px; }}
    pre {{ white-space: pre-wrap; background: #f9fafb; border: 1px solid #e5e7eb; border-radius: 6px; padding: 10px; }}
    .detail-block p {{ margin: 8px 0 6px; }}
  </style>
</head>
<body>
  <h1>ToyBot Eval Report</h1>
  <div class="meta">Total: <strong>{total}</strong> &nbsp; Passed: <strong>{passed_count}</strong> &nbsp; Score: <strong>{score:.1f}%</strong></div>
  <h2>Details</h2>
  {''.join(details_html)}
</body>
</html>
"""


if __name__ == "__main__":
    main()
