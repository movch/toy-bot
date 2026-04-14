import Testing
@testable import ToyBot

struct DeterministicIntentResolverTests {
    private let sut = DeterministicIntentResolver()

    @Test
    func searchWithSinglePathPromotesToReadFile() {
        let intent = sut.resolve(after: .searchFile(keyword: "ToyBot"), result: "Sources/toy-bot/ToyBot.swift")
        #expect(intent == .readFile(path: "Sources/toy-bot/ToyBot.swift"))
    }

    @Test
    func searchWithFewPathsChoosesShallowPath() {
        let output = """
        Sources/a.swift
        Sources/very/deep/path/file.swift
        """
        let intent = sut.resolve(after: .searchFile(keyword: "a"), result: output)
        #expect(intent == .readFile(path: "Sources/a.swift"))
    }

    @Test
    func searchWithTooManyPathsReturnsNil() {
        let output = """
        1.swift
        2.swift
        3.swift
        4.swift
        5.swift
        6.swift
        """
        let intent = sut.resolve(after: .searchFile(keyword: "x"), result: output)
        #expect(intent == nil)
    }

    @Test
    func readWithNonErrorOutputPromotesToDirectChat() {
        let intent = sut.resolve(after: .readFile(path: "a.swift"), result: "file body")
        #expect(intent == .directChat)
    }

    @Test
    func bashWithSinglePathPromotesToReadFile() {
        let intent = sut.resolve(after: .bash(command: "ls"), result: "README.md")
        #expect(intent == .readFile(path: "README.md"))
    }

    @Test
    func errorOutputsNeverResolve() {
        let searchIntent = sut.resolve(after: .searchFile(keyword: "x"), result: "Error: failed")
        let readIntent = sut.resolve(after: .readFile(path: "x"), result: "error: not found")
        let bashIntent = sut.resolve(after: .bash(command: "ls"), result: "ERROR: boom")

        #expect(searchIntent == nil)
        #expect(readIntent == nil)
        #expect(bashIntent == nil)
    }
}
