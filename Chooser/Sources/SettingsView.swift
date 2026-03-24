import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: GameSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                // Selection Mode
                Section {
                    Picker("Selection Mode", selection: $settings.selectionMode) {
                        ForEach(SelectionMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)

                    Text(settings.selectionMode.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Winner Selection")
                }

                // Custom weights (only shown for custom mode)
                if settings.selectionMode == .custom {
                    Section {
                        Stepper(
                            "Favored Position: \(ordinal(settings.favoredPosition)) finger",
                            value: $settings.favoredPosition,
                            in: 1...11
                        )

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Win Probability")
                                Spacer()
                                Text("\(Int(settings.favoredProbability))%")
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                            }
                            Slider(
                                value: $settings.favoredProbability,
                                in: 0...100,
                                step: 5
                            )
                            .tint(.orange)
                        }

                        Text("The \(ordinal(settings.favoredPosition)) finger placed on screen will have a \(Int(settings.favoredProbability))% chance of winning. Remaining probability is split evenly among others.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } header: {
                        Text("Custom Weights")
                    }
                }

                // Timing
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Stabilization Delay")
                            Spacer()
                            Text(String(format: "%.1fs", settings.stabilizationDelay))
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        Slider(
                            value: $settings.stabilizationDelay,
                            in: 0.5...5.0,
                            step: 0.5
                        )
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Countdown")
                            Spacer()
                            Text("\(Int(settings.countdownDuration))s")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        Slider(
                            value: $settings.countdownDuration,
                            in: 1...10,
                            step: 1
                        )
                    }
                } header: {
                    Text("Timing")
                }

                // Background Theme
                Section {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(BackgroundTheme.allCases) { theme in
                            Button {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    settings.backgroundTheme = theme
                                }
                            } label: {
                                VStack(spacing: 6) {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(
                                            LinearGradient(
                                                colors: theme.colors,
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(height: 50)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(
                                                    settings.backgroundTheme == theme
                                                        ? Color.accentColor
                                                        : Color.clear,
                                                    lineWidth: 2.5
                                                )
                                        )
                                        .overlay(
                                            settings.backgroundTheme == theme
                                                ? Image(systemName: "checkmark.circle.fill")
                                                    .foregroundStyle(.white)
                                                    .font(.system(size: 16, weight: .bold))
                                                : nil
                                        )

                                    Text(theme.rawValue)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundStyle(.primary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Background")
                }

                // Reset
                Section {
                    Button("Reset to Defaults", role: .destructive) {
                        settings.selectionMode = .random
                        settings.favoredPosition = 1
                        settings.favoredProbability = 80
                        settings.countdownDuration = 3
                        settings.stabilizationDelay = 1.5
                        settings.backgroundTheme = .midnight
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func ordinal(_ n: Int) -> String {
        let suffix: String
        let ones = n % 10
        let tens = (n / 10) % 10

        if tens == 1 {
            suffix = "th"
        } else {
            switch ones {
            case 1: suffix = "st"
            case 2: suffix = "nd"
            case 3: suffix = "rd"
            default: suffix = "th"
            }
        }
        return "\(n)\(suffix)"
    }
}

#Preview {
    SettingsView(settings: GameSettings())
}
