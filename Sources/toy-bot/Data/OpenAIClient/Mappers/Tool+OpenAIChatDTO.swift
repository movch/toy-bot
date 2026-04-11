import Foundation

extension Tool {
    var openAIChatDTOSchema: OpenAIChatDTO.ToolSchema? {
        guard
            let data = parametersSchema.data(using: .utf8),
            let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }

        return OpenAIChatDTO.ToolSchema(
            type: "function",
            function: OpenAIChatDTO.FunctionSchema(
                name: name,
                description: description,
                parameters: dict.mapValues(AnyEncodable.init)
            )
        )
    }
}
