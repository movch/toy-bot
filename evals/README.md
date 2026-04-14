# Evals (one-shot)

This directory contains a lightweight eval harness for checking model/agent quality outside `swift-testing`.

## What it does

- Reads prompt cases from `evals/cases/*.jsonl`
- Builds `ToyBot` once, then runs one-shot CLI calls via the binary
- Stores raw run output in `evals/runs/<timestamp>.jsonl`
- Scores each case with simple heuristic checks
- Writes an HTML report to `evals/reports/<timestamp>.html`

## Case format

Each JSONL line is one case with:

- `id`, `prompt`, `routing_mode`
- optional `must_use_tools`, `must_not_use_tools`
- optional `must_use_skills`, `must_not_use_skills`
- `expected.checks` (heuristics)

Supported checks in `score.py`:

- `non_empty`
- `max_chars`
- `contains_any`
- `contains_all`
- `contains_regex`
- `must_not_contains_any`
- `valid_json_object`
- `json_has_keys`
- `json_enum`

## Run

```bash
chmod +x evals/run.sh evals/score.py
./evals/run.sh
```

Or with a custom case file:

```bash
./evals/run.sh evals/cases/smoke.jsonl
```

Optional env:

```bash
# debug|release (default: release)
TOYBOT_EVAL_BUILD_CONFIG=debug ./evals/run.sh
```

## One-shot mode in CLI

`ToyBot` supports one-shot prompt execution:

```bash
swift run ToyBot --routing intent -c "Кратко объясни что делает файл Sources/toy-bot/ToyBot.swift"
```

Aliases:

- `-c "prompt"`
- `--prompt "prompt"`

In one-shot mode, the process prints only the model response to stdout and exits non-zero on error.
