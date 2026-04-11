extension OpenAIChatDTO.Request {
    init(model: String, history: [Message], temperature: Double?) {
        self.init(
            model: model,
            messages: history.map(\.openAIChatDTO),
            temperature: temperature
        )
    }
}
