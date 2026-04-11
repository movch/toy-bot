extension Message {
    var openAIChatDTO: OpenAIChatDTO.Message {
        switch self {
        case .system(content: let content):
            return OpenAIChatDTO.Message(role: .system, content: content, toolCalls: nil, toolCallId: nil)
        case .user(content: let content):
            return OpenAIChatDTO.Message(role: .user, content: content, toolCalls: nil, toolCallId: nil)
        case .assistant(content: let content, toolCalls: let toolCalls):
            let dtoToolCalls = toolCalls.isEmpty ? nil : toolCalls.map {
                OpenAIChatDTO.ToolCallDTO(
                    id: $0.id,
                    type: "function",
                    function: OpenAIChatDTO.FunctionCallDTO(name: $0.toolName, arguments: $0.toolArguments)
                )
            }
            return OpenAIChatDTO.Message(
                role: .assistant,
                content: content.isEmpty ? nil : content,
                toolCalls: dtoToolCalls,
                toolCallId: nil
            )
        case .tool(content: let content, toolCallId: let toolCallId):
            return OpenAIChatDTO.Message(role: .tool, content: content, toolCalls: nil, toolCallId: toolCallId)
        }
    }
}

extension OpenAIChatDTO.Message {
    var domain: Message {
        switch role {
        case .system:
            return .system(content: content ?? "")
        case .user:
            return .user(content: content ?? "")
        case .assistant:
            let toolCalls = (self.toolCalls ?? []).map {
                ToolCall(id: $0.id, toolName: $0.function.name, toolArguments: $0.function.arguments)
            }
            return .assistant(content: content ?? "", toolCalls: toolCalls)
        case .tool:
            return .tool(content: content ?? "", toolCallId: toolCallId ?? "")
        }
    }
}
