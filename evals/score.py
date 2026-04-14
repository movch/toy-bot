#!/usr/bin/env python3
import json
import re
import sys
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
    "valid_json_object": check_valid_json_object,
    "json_has_keys": check_json_has_keys,
    "json_enum": check_json_enum,
}


def evaluate(record):
    output = record.get("output", "")
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
        if tool not in output:
            failures.append(f"must_use_tools: '{tool}' not found in output/trace")

    for tool in record.get("must_not_use_tools", []):
        if tool in output:
            failures.append(f"must_not_use_tools: '{tool}' found in output/trace")

    if record.get("exit_code", 0) != 0:
        failures.append(f"non-zero exit code: {record['exit_code']}")

    passed = len(failures) == 0
    return passed, failures


def main():
    if len(sys.argv) != 3:
        print("Usage: score.py <run_file.jsonl> <report_file.md>", file=sys.stderr)
        sys.exit(1)

    run_file = Path(sys.argv[1])
    report_file = Path(sys.argv[2])
    if not run_file.exists():
        print(f"Run file not found: {run_file}", file=sys.stderr)
        sys.exit(1)

    records = []
    for line in run_file.read_text(encoding="utf-8").splitlines():
        if line.strip():
            records.append(json.loads(line))

    total = len(records)
    passed_count = 0
    lines = [
        "# Eval Report",
        "",
        f"- Total cases: {total}",
    ]

    for record in records:
        passed, failures = evaluate(record)
        if passed:
            passed_count += 1
        status = "PASS" if passed else "FAIL"
        lines.append(
            f"- [{status}] `{record['case_id']}` | routing={record.get('routing_mode')} | latency={record.get('latency_ms')}ms"
        )
        if failures:
            for failure in failures:
                lines.append(f"  - {failure}")

    score = (passed_count / total * 100.0) if total else 0.0
    lines.insert(3, f"- Passed: {passed_count}")
    lines.insert(4, f"- Score: {score:.1f}%")
    lines.append("")

    report_file.write_text("\n".join(lines), encoding="utf-8")
    print(f"Score: {score:.1f}% ({passed_count}/{total})")

    if passed_count != total:
        sys.exit(2)


if __name__ == "__main__":
    main()
