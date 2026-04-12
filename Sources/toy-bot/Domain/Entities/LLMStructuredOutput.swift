/// How the chat completion response body should be constrained (maps to `response_format` on OpenAI-compatible APIs).
enum LLMStructuredOutput: Sendable {
    case none
    /// `{"type":"json_object"}` — valid JSON object, shape not enforced.
    case jsonObject
    /// JSON matching `IntentResponseDTO` (intent router classification).
    case intentRouter
}
