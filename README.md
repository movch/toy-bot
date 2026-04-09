# toy-bot

Minimal Swift CLI bot with a provider-agnostic network layer and OpenAI-compatible client.

## Ollama Configuration

`toy-bot` supports Ollama via OpenAI-compatible endpoints.

### Defaults

If you do not pass any config, the app uses:

- provider: `ollama`
- base URL: `http://localhost:11434`
- model: `llama3.1`
- token: not required

## Configure via Environment Variables

Supported environment variables:

- `TOYBOT_PROVIDER` (`ollama` or `openai`)
- `TOYBOT_BASE_URL`
- `TOYBOT_MODEL`
- `TOYBOT_API_TOKEN` (optional for Ollama)
- `OLLAMA_HOST` (used as fallback for Ollama base URL)

Example:

```bash
export TOYBOT_PROVIDER=ollama
export OLLAMA_HOST=http://localhost:11434
export TOYBOT_MODEL=llama3.1
swift run
```

## Configure via CLI Arguments

Supported arguments:

- `--provider`
- `--base-url`
- `--model`
- `--token`
- `--ollama-host`

Example:

```bash
swift run ToyBot --provider ollama --base-url http://localhost:11434 --model llama3.1
```

## Configuration Priority

From highest to lowest:

1. CLI arguments
2. Environment variables
3. Built-in defaults

## Notes for Ollama

- For local Ollama, token is usually not needed.
- If no token is provided, `Authorization` header is omitted.
- If you run Ollama remotely and need auth, pass `--token` or `TOYBOT_API_TOKEN`.
