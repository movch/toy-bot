extension OpenAIChatDTO.Request {
    init(
        model: String,
        history: [Message],
        profile: GenerationProfile,
        tools: [any Tool] = [],
        responseFormat: OpenAIChatDTO.ResponseFormat? = nil
    ) {
        let toolSchemas = tools.compactMap(\.openAIChatDTOSchema)
        self.init(
            model: model,
            messages: history.map(\.openAIChatDTO),
            temperature: profile.temperature,
            topP: profile.topP,
            tools: toolSchemas.isEmpty ? nil : toolSchemas,
            responseFormat: responseFormat
        )
    }
}
