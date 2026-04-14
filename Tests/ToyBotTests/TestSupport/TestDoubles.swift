import Foundation
@testable import ToyBot

enum TestFailure: Error {
    case noStubbedResponse
}

actor MockLLMClient: LLMClient {
    struct Call: Sendable {
        let history: [Message]
        let toolsCount: Int
        let profile: GenerationProfile
        let structuredOutput: LLMStructuredOutput
    }

    private var queuedResults: [Result<Message, Error>]
    private(set) var calls: [Call] = []

    init(results: [Result<Message, Error>]) {
        self.queuedResults = results
    }

    func sendMessage(
        history: [Message],
        tools: [any Tool],
        profile: GenerationProfile,
        structuredOutput: LLMStructuredOutput
    ) async throws -> Message {
        calls.append(
            Call(
                history: history,
                toolsCount: tools.count,
                profile: profile,
                structuredOutput: structuredOutput
            )
        )
        guard !queuedResults.isEmpty else {
            throw TestFailure.noStubbedResponse
        }
        return try queuedResults.removeFirst().get()
    }
}

actor StubIntentRouter: IntentRouter {
    private var intents: [Intent]
    private(set) var classifyCallCount = 0

    init(intents: [Intent]) {
        self.intents = intents
    }

    func classify(history: [Message]) async throws -> Intent {
        classifyCallCount += 1
        if intents.isEmpty {
            return .directChat
        }
        return intents.removeFirst()
    }
}

actor StubActionExecutor: ActionExecutor {
    private var results: [String]
    private(set) var receivedIntents: [Intent] = []

    init(results: [String]) {
        self.results = results
    }

    func execute(intent: Intent) async throws -> String {
        receivedIntents.append(intent)
        if results.isEmpty {
            return ""
        }
        return results.removeFirst()
    }
}

actor StubSynthesizer: Synthesizer {
    private let output: Message
    private(set) var calls: [(history: [Message], context: String)] = []

    init(output: Message) {
        self.output = output
    }

    func synthesize(history: [Message], collectedContext: String) async throws -> Message {
        calls.append((history, collectedContext))
        return output
    }
}

struct StubAgent: Agent {
    let llmClient: LLMClient
    let systemPrompt: String
    let toolRegistry: ToolRegistry
}

struct StubTool: Tool {
    let name: String
    let description: String = "stub"
    let parametersSchema: String = "{}"
    let executeImpl: @Sendable (String) async throws -> String

    init(name: String, executeImpl: @escaping @Sendable (String) async throws -> String) {
        self.name = name
        self.executeImpl = executeImpl
    }

    func execute(toolArguments: String) async throws -> String {
        try await executeImpl(toolArguments)
    }
}

struct StubSkillRegistry: SkillRegistry {
    let metadata: [Skill.Metadata]
    let skillsById: [String: Skill]

    init(metadata: [Skill.Metadata] = [], skillsById: [String: Skill] = [:]) {
        self.metadata = metadata
        self.skillsById = skillsById
    }

    func loadSkill(id: String) throws -> Skill {
        guard let skill = skillsById[id] else {
            throw SkillRegistryError.skillNotFound(id)
        }
        return skill
    }
}

actor StubHttpClient: HttpClient {
    private var queued: [Result<ResponseData, Error>]
    private(set) var requests: [URLRequest] = []

    init(queued: [Result<ResponseData, Error>]) {
        self.queued = queued
    }

    func request(_ urlRequest: URLRequest) async throws -> ResponseData {
        requests.append(urlRequest)
        guard !queued.isEmpty else {
            throw TestFailure.noStubbedResponse
        }
        return try queued.removeFirst().get()
    }
}

final class StubResponseDecoder: ResponseDecoder, @unchecked Sendable {
    var next: Any
    private(set) var receivedStatusCodes: [Int] = []

    init(next: Any) {
        self.next = next
    }

    func map<T>(_ responseData: ResponseData) throws -> T where T: Decodable {
        receivedStatusCodes.append(responseData.response.statusCode)
        guard let casted = next as? T else {
            throw TestFailure.noStubbedResponse
        }
        return casted
    }
}
