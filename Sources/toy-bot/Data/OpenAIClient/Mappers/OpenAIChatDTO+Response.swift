extension OpenAIChatDTO.Response {
    var firstDomainMessage: Message? {
        choices.first.map { $0.message.domain }
    }
}
