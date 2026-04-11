extension OpenAIChatDTO.Request {
    init(model: String, history: [Message], temperature: Double?, tools: [any Tool] = []) {
        let toolSchemas = tools.compactMap(\.openAIChatDTOSchema)
        self.init(
            model: model,
            messages: history.map(\.openAIChatDTO),
            temperature: temperature,
            tools: toolSchemas.isEmpty ? nil : toolSchemas
        )
    }
}
