#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CASES_FILE="${1:-$ROOT_DIR/evals/cases/smoke.jsonl}"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
RUN_FILE="$ROOT_DIR/evals/runs/$TIMESTAMP.jsonl"
HTML_REPORT_FILE="$ROOT_DIR/evals/reports/$TIMESTAMP.html"
BUILD_CONFIG="${TOYBOT_EVAL_BUILD_CONFIG:-release}"
if [[ "$BUILD_CONFIG" != "debug" && "$BUILD_CONFIG" != "release" ]]; then
  echo "Invalid TOYBOT_EVAL_BUILD_CONFIG='$BUILD_CONFIG' (expected debug|release)" >&2
  exit 1
fi
BIN_PATH="$ROOT_DIR/.build/$BUILD_CONFIG/ToyBot"

if [[ ! -f "$CASES_FILE" ]]; then
  echo "Cases file not found: $CASES_FILE" >&2
  exit 1
fi

echo "Building ToyBot once ($BUILD_CONFIG)..."
(cd "$ROOT_DIR" && swift build -c "$BUILD_CONFIG" >/dev/null)
if [[ ! -x "$BIN_PATH" ]]; then
  echo "ToyBot binary not found: $BIN_PATH" >&2
  exit 1
fi

echo "Running eval cases from: $CASES_FILE"
echo "Run output: $RUN_FILE"

while IFS= read -r line; do
  [[ -z "$line" ]] && continue

  case_id="$(python3 -c 'import json,sys; print(json.loads(sys.argv[1])["id"])' "$line")"
  prompt="$(python3 -c 'import json,sys; print(json.loads(sys.argv[1])["prompt"])' "$line")"
  routing_mode="$(python3 -c 'import json,sys; print(json.loads(sys.argv[1]).get("routing_mode","intent"))' "$line")"

  start_ms="$(python3 -c 'import time; print(int(time.time()*1000))')"
  set +e
  output="$(
    cd "$ROOT_DIR" && \
    "$BIN_PATH" --routing "$routing_mode" -c "$prompt" 2>&1
  )"
  exit_code=$?
  set -e
  end_ms="$(python3 -c 'import time; print(int(time.time()*1000))')"
  latency_ms="$((end_ms - start_ms))"

  python3 - "$line" "$output" "$exit_code" "$latency_ms" "$TIMESTAMP" >> "$RUN_FILE" <<'PY'
import json
import sys

case = json.loads(sys.argv[1])
output = sys.argv[2]
exit_code = int(sys.argv[3])
latency_ms = int(sys.argv[4])
run_id = sys.argv[5]

trace_prefixes = ("🔍", "⚡", "🔨")
trace_lines = []
answer_lines = []
for line in output.splitlines():
    trimmed = line.lstrip()
    if trimmed.startswith(trace_prefixes):
        trace_lines.append(trimmed)
    elif line.strip() == "":
        continue
    else:
        answer_lines.append(line)

record = {
    "run_id": run_id,
    "case_id": case["id"],
    "category": case.get("category"),
    "routing_mode": case.get("routing_mode", "intent"),
    "prompt": case["prompt"],
    "expected": case.get("expected", {}),
    "must_use_tools": case.get("must_use_tools", []),
    "must_not_use_tools": case.get("must_not_use_tools", []),
    "must_use_skills": case.get("must_use_skills", []),
    "must_not_use_skills": case.get("must_not_use_skills", []),
    "output": output,
    "answer": "\n".join(answer_lines).strip(),
    "trace_lines": trace_lines,
    "exit_code": exit_code,
    "latency_ms": latency_ms,
}
print(json.dumps(record, ensure_ascii=False))
PY

  echo "  - $case_id (routing=$routing_mode, exit=$exit_code, latency=${latency_ms}ms)"
done < "$CASES_FILE"

python3 "$ROOT_DIR/evals/score.py" "$RUN_FILE" "$HTML_REPORT_FILE"
echo "Done. Report:"
echo "  - HTML: $HTML_REPORT_FILE"
