enum GenerationProfile: Sendable {
    case deterministic
    case balanced
    case creative
}

extension GenerationProfile {
    var temperature: Double {
        switch self {
        case .deterministic: return 0.1
        case .balanced:      return 0.4
        case .creative:      return 0.8
        }
    }
}
