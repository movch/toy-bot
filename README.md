# toy-bot

Minimal Swift CLI bot with an OpenAI-compatible client. 

## Current Architecture

Currently it is "just chat loop" agent:

- `ChatLoop` (`Presentation`): handles terminal input/output and loop control (`exit`, `quit`, `q`).
- `AgentSession` (`Data/Agent`): owns conversation history and orchestrates one chat turn:
  1. append user message,
  2. call LLM with full history,
  3. append assistant message,
  4. rollback last user message on request failure.
- `Agent` / `DefaultAgent`: binds `LLMClient` and a system prompt.
- `OpenAIClient`: provider-agnostic chat completion client used by the session.

When started, the app prints active config and enters interactive chat:

- prompt: `You:`
- assistant output: `🤖 Bot: ...`
- exit commands: `exit`, `quit`, `q`

## Ollama Configuration

`toy-bot` supports Ollama via OpenAI-compatible endpoints.

### Ollama Installation

Install Ollama before running `toy-bot` with a local model.

Official download page: [ollama.com/download](https://ollama.com/download)

Quick install options:

```bash
# macOS (Homebrew)
brew install ollama

# Linux
curl -fsSL https://ollama.com/install.sh | sh
```

After installation, start Ollama and pull a model:

```bash
ollama serve
ollama pull llama3.2
```

### Defaults

If you do not pass any config, the app uses:

- provider: `ollama`
- base URL: `http://localhost:11434`
- model: `llama3.2`
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
export TOYBOT_MODEL=llama3.2
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
swift run ToyBot --provider ollama --base-url http://localhost:11434 --model llama3.2
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
