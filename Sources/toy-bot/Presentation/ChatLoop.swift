import Darwin

final class ChatLoop {
    private let agentSession: any AgentSession

    init(agentSession: any AgentSession) {
        self.agentSession = agentSession
    }
    
    func runChatLoop() async {
        print("(Press Enter twice to send — supports multi-line input)")
        while true {
            print("\n>>> ", terminator: "")
            fflush(stdout)

            var lines: [String] = []
            while let line = readLine() {
                if line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { break }
                lines.append(line)
            }

            guard !lines.isEmpty else { continue }

            let normalized = lines.joined(separator: "\n")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if ["exit", "quit", "q"].contains(normalized.lowercased()) {
                print("👋 Shutting down...")
                break
            }

            do {
                print("🤖 Bot: (typing...)", terminator: "")
                fflush(stdout)
                let response = try await agentSession.chat(normalized)
                print("\r\(String(repeating: " ", count: 30))\r", terminator: "")
                print("🤖 Bot: \(response.content)")
            } catch {
                print("\r\(String(repeating: " ", count: 30))\r", terminator: "")
                print("\n❌ \(ErrorFormatter.userMessage(for: error))")
            }
        }
    }
}
