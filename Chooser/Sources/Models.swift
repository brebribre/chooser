import SwiftUI

// MARK: - Game Phase

enum GamePhase: Equatable {
    case idle
    case registering
    case countdown(remaining: Int)
    case revealing
    case result
}

// MARK: - Selection Mode

enum SelectionMode: String, CaseIterable, Identifiable {
    case random = "Random"
    case firstToTouch = "First to Touch"
    case lastToTouch = "Last to Touch"
    case custom = "Custom Weighted"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .random: return "Fair random selection"
        case .firstToTouch: return "First finger placed wins"
        case .lastToTouch: return "Last finger placed wins"
        case .custom: return "Weighted probability"
        }
    }
}

// MARK: - Finger Info

struct FingerInfo: Identifiable, Equatable {
    let id: ObjectIdentifier
    var position: CGPoint
    var color: Color
    var orderPlaced: Int
    var state: FingerState
    var timestamp: Date

    enum FingerState: Equatable {
        case active
        case eliminated
        case winner
    }

    static func == (lhs: FingerInfo, rhs: FingerInfo) -> Bool {
        lhs.id == rhs.id &&
        lhs.position == rhs.position &&
        lhs.state == rhs.state
    }
}

// MARK: - Color Palette

struct ColorPalette {
    static let colors: [Color] = [
        Color(red: 0.95, green: 0.26, blue: 0.21),  // Red
        Color(red: 0.13, green: 0.59, blue: 0.95),  // Blue
        Color(red: 0.30, green: 0.69, blue: 0.31),  // Green
        Color(red: 1.00, green: 0.76, blue: 0.03),  // Yellow
        Color(red: 0.61, green: 0.15, blue: 0.69),  // Purple
        Color(red: 1.00, green: 0.60, blue: 0.00),  // Orange
        Color(red: 0.91, green: 0.12, blue: 0.39),  // Pink
        Color(red: 0.00, green: 0.74, blue: 0.83),  // Cyan
        Color(red: 0.55, green: 0.76, blue: 0.29),  // Lime
        Color(red: 0.47, green: 0.33, blue: 0.28),  // Brown
        Color(red: 0.00, green: 0.47, blue: 0.42),  // Teal
    ]

    static func color(for index: Int) -> Color {
        colors[index % colors.count]
    }
}

// MARK: - Background Theme

enum BackgroundTheme: String, CaseIterable, Identifiable {
    case midnight = "Midnight"
    case ocean = "Ocean"
    case sunset = "Sunset"
    case aurora = "Aurora"
    case ember = "Ember"
    case forest = "Forest"
    case lavender = "Lavender"
    case charcoal = "Charcoal"

    var id: String { rawValue }

    var colors: [Color] {
        switch self {
        case .midnight:
            return [
                Color(red: 0.05, green: 0.05, blue: 0.15),
                Color(red: 0.10, green: 0.08, blue: 0.25),
                Color(red: 0.02, green: 0.02, blue: 0.08)
            ]
        case .ocean:
            return [
                Color(red: 0.02, green: 0.10, blue: 0.20),
                Color(red: 0.05, green: 0.20, blue: 0.35),
                Color(red: 0.01, green: 0.05, blue: 0.12)
            ]
        case .sunset:
            return [
                Color(red: 0.25, green: 0.05, blue: 0.15),
                Color(red: 0.35, green: 0.10, blue: 0.08),
                Color(red: 0.10, green: 0.02, blue: 0.08)
            ]
        case .aurora:
            return [
                Color(red: 0.02, green: 0.12, blue: 0.15),
                Color(red: 0.05, green: 0.20, blue: 0.18),
                Color(red: 0.08, green: 0.05, blue: 0.20)
            ]
        case .ember:
            return [
                Color(red: 0.20, green: 0.05, blue: 0.02),
                Color(red: 0.30, green: 0.12, blue: 0.02),
                Color(red: 0.08, green: 0.02, blue: 0.02)
            ]
        case .forest:
            return [
                Color(red: 0.02, green: 0.12, blue: 0.05),
                Color(red: 0.05, green: 0.20, blue: 0.10),
                Color(red: 0.02, green: 0.06, blue: 0.03)
            ]
        case .lavender:
            return [
                Color(red: 0.12, green: 0.05, blue: 0.20),
                Color(red: 0.18, green: 0.08, blue: 0.30),
                Color(red: 0.05, green: 0.02, blue: 0.10)
            ]
        case .charcoal:
            return [
                Color(red: 0.08, green: 0.08, blue: 0.08),
                Color(red: 0.12, green: 0.12, blue: 0.14),
                Color(red: 0.04, green: 0.04, blue: 0.04)
            ]
        }
    }
}

// MARK: - Settings

final class GameSettings: ObservableObject {
    private let defaults = UserDefaults.standard

    @Published var selectionMode: SelectionMode {
        didSet { defaults.set(selectionMode.rawValue, forKey: "selectionMode") }
    }
    @Published var favoredPosition: Int {
        didSet { defaults.set(favoredPosition, forKey: "favoredPosition") }
    }
    @Published var favoredProbability: Double {
        didSet { defaults.set(favoredProbability, forKey: "favoredProbability") }
    }
    @Published var countdownDuration: Double {
        didSet { defaults.set(countdownDuration, forKey: "countdownDuration") }
    }
    @Published var stabilizationDelay: Double {
        didSet { defaults.set(stabilizationDelay, forKey: "stabilizationDelay") }
    }
    @Published var backgroundTheme: BackgroundTheme {
        didSet { defaults.set(backgroundTheme.rawValue, forKey: "backgroundTheme") }
    }

    init() {
        let d = UserDefaults.standard
        if let raw = d.string(forKey: "selectionMode"),
           let mode = SelectionMode(rawValue: raw) {
            selectionMode = mode
        } else {
            selectionMode = .random
        }
        favoredPosition = d.object(forKey: "favoredPosition") as? Int ?? 1
        favoredProbability = d.object(forKey: "favoredProbability") as? Double ?? 80
        countdownDuration = d.object(forKey: "countdownDuration") as? Double ?? 2
        stabilizationDelay = d.object(forKey: "stabilizationDelay") as? Double ?? 1
        if let raw = d.string(forKey: "backgroundTheme"),
           let theme = BackgroundTheme(rawValue: raw) {
            backgroundTheme = theme
        } else {
            backgroundTheme = .midnight
        }
    }
}

