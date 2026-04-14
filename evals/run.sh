#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CASES_FILE="${1:-$ROOT_DIR/evals/cases/smoke.jsonl}"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
RUN_FILE="$ROOT_DIR/evals/runs/$TIMESTAMP.jsonl"
REPORT_FILE="$ROOT_DIR/evals/reports/$TIMESTAMP.md"

if [[ ! -f "$CASES_FILE" ]]; then
  echo "Cases file not found: $CASES_FILE" >&2
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
    swift run ToyBot --routing "$routing_mode" -c "$prompt" 2>&1
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

record = {
    "run_id": run_id,
    "case_id": case["id"],
    "category": case.get("category"),
    "routing_mode": case.get("routing_mode", "intent"),
    "prompt": case["prompt"],
    "expected": case.get("expected", {}),
    "must_use_tools": case.get("must_use_tools", []),
    "must_not_use_tools": case.get("must_not_use_tools", []),
    "output": output,
    "exit_code": exit_code,
    "latency_ms": latency_ms,
}
print(json.dumps(record, ensure_ascii=False))
PY

  echo "  - $case_id (routing=$routing_mode, exit=$exit_code, latency=${latency_ms}ms)"
done < "$CASES_FILE"

python3 "$ROOT_DIR/evals/score.py" "$RUN_FILE" "$REPORT_FILE"
echo "Done. Report: $REPORT_FILE"
