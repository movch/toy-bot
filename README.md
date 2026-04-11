# toy-bot

Minimal Swift CLI agent with tool calling support and an OpenAI-compatible client.

## Current Architecture

Tool-calling agent built on a clean layered architecture:

- `ChatLoop` (`Presentation`): handles terminal input/output and loop control (`exit`, `quit`, `q`).
- `AgentSession` (protocol, `Domain/Interfaces`); `InMemoryAgentSession` (`Application/Agent`): owns conversation history and runs the tool-calling loop:
  1. append user message,
  2. call LLM with full history and tool schemas,
  3. if response contains tool calls — execute them, append results, call LLM again,
  4. repeat until LLM returns a plain text response,
  5. rollback last user message on LLM request failure.
- `Agent` / `ChatAgent` (`Application/Agent`): binds `LLMClient`, system prompt, and `ToolRegistry`.
- `ToolRegistry` (`Application/Tools`): holds available tools, dispatches execution by name.
- `Tool` (protocol, `Domain/Interfaces`): name, description, `parametersSchema` (JSON Schema string), and `execute`.
- `OpenAIClient` (`Data`): provider-agnostic chat completion client with function calling support.

### Built-in tools

| Tool | Description |
|---|---|
| `read_file` | Read the full contents of a file at a given path |
| `bash` | Execute a bash command and return stdout + stderr |

### Message domain model

`Message` is an enum — each case carries exactly the data it needs:

```swift
enum Message {
    case system(content: String)
    case user(content: String)
    case assistant(content: String, toolCalls: [ToolCall])
    case tool(content: String, toolCallId: String)
}
```

## Running

```bash
swift run
```

When started, the app prints active config and enters interactive chat:

- prompt: `>>> `
- assistant output: `🤖 Bot: ...`
- tool execution: `🔨 Tool: <name>`
- exit commands: `exit`, `quit`, `q`

## Ollama Configuration

`toy-bot` defaults to Ollama with a local model. For best results with tool calling, use a model that supports function calling (e.g. `llama3.2`, `qwen2.5`).

### Ollama Installation

Official download page: [ollama.com/download](https://ollama.com/download)

```bash
# macOS (Homebrew)
brew install ollama

# Linux
curl -fsSL https://ollama.com/install.sh | sh
```

Start Ollama and pull a model:

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

| Variable | Description |
|---|---|
| `TOYBOT_PROVIDER` | `ollama` or `openai` |
| `TOYBOT_BASE_URL` | Override base URL |
| `TOYBOT_MODEL` | Model name |
| `TOYBOT_API_TOKEN` | API token (optional for Ollama) |
| `OLLAMA_HOST` | Fallback base URL for Ollama |

```bash
export TOYBOT_PROVIDER=ollama
export TOYBOT_MODEL=llama3.2
swift run
```

## Configure via CLI Arguments

```bash
swift run ToyBot --provider ollama --base-url http://localhost:11434 --model llama3.2
swift run ToyBot --provider openai --token sk-... --model gpt-4o-mini
```

Supported flags: `--provider`, `--base-url`, `--model`, `--token`, `--ollama-host`

## Configuration Priority

1. CLI arguments
2. Environment variables
3. Built-in defaults

## Notes for Ollama

- Token is not required for local Ollama; `Authorization` header is omitted when no token is set.
- Request timeout is set to 5 minutes to accommodate slow local inference.
- If you run Ollama remotely and need auth, pass `--token` or `TOYBOT_API_TOKEN`.
