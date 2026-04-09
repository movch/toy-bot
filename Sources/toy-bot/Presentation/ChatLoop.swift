import Darwin

final class ChatLoop {
    private let agentSession: AgentSession
    
    init(agentSession: AgentSession) {
        self.agentSession = agentSession
    }
    
    func runChatLoop() async {
        while true {
            print("\nYou: ", terminator: "")
            guard let input = readLine() else { continue }
            
            let normalized = input.trimmingCharacters(in: .whitespacesAndNewlines)
            if normalized.isEmpty { continue }
            
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
                print("\n❌ Error: \(error.localizedDescription)")
            }
        }
    }
}
