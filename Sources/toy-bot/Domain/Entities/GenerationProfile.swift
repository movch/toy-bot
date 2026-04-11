enum GenerationProfile: Sendable {
    case deterministic
    case balanced
    case creative
}

extension GenerationProfile {
    /// Used with tools / JSON-like outputs: low randomness.
    var temperature: Double {
        switch self {
        case .deterministic: return 0.1
        case .balanced:      return 0.4
        case .creative:      return 0.8
        }
    }

    /// Nucleus sampling. Lower = less mass on unlikely tokens (helps paths and tool JSON on small models).
    var topP: Double {
        switch self {
        case .deterministic: return 0.90
        case .balanced:      return 0.95
        case .creative:      return 0.98
        }
    }
}
