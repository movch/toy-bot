extension Message {
    var openAIChatDTO: OpenAIChatDTO.Message {
        OpenAIChatDTO.Message(role: role.openAIChatDTO, content: content)
    }
}

extension OpenAIChatDTO.Message {
    var domain: Message {
        Message(role: role.domain, content: content)
    }
}
