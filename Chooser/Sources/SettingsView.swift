import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: GameSettings
    @StateObject private var store = StoreManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showUpgradeSheet = false

    var body: some View {
        NavigationStack {
            Form {
                // ── Selection Mode ──
                Section {
                    if store.isPremium {
                        Picker("Selection Mode", selection: $settings.selectionMode) {
                            ForEach(SelectionMode.allCases) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.menu)
                    } else {
                        HStack {
                            Text("Selection Mode")
                            Spacer()
                            Text("Random")
                                .foregroundStyle(.secondary)
                        }
                    }

                    Text(settings.selectionMode.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Winner Selection")
                }

                // ── Custom Weights (premium only) ──
                if settings.selectionMode == .custom && store.isPremium {
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

                // ── Timing (free) ──
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

                // ── Background Theme (premium only) ──
                if store.isPremium {
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
                }

                // ── Chooser Pro (single unified section for free users) ──
                if !store.isPremium {
                    Section {
                        Button {
                            showUpgradeSheet = true
                        } label: {
                            VStack(alignment: .leading, spacing: 14) {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(.yellow.opacity(0.15))
                                            .frame(width: 44, height: 44)
                                        Image(systemName: "crown.fill")
                                            .foregroundStyle(.yellow)
                                            .font(.system(size: 20))
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Chooser Pro")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundStyle(.primary)
                                        Text("Unlock the full experience")
                                            .font(.system(size: 13))
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.secondary)
                                }

                                VStack(alignment: .leading) {
                                    ProFeatureRow(icon: "hand.tap.fill", text: "Decide who wins — rig the outcome")
                                    ProFeatureRow(icon: "paintpalette.fill", text: "8 premium background themes")
                                }

                                // Theme preview strip
                                HStack(spacing: 6) {
                                    ForEach(BackgroundTheme.allCases.prefix(6)) { theme in
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(
                                                LinearGradient(
                                                    colors: theme.colors,
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(height: 28)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                }

                // ── Restore + Reset ──
                Section {
                    if !store.isPremium {
                        Button("Restore Purchases") {
                            Task { await store.restore() }
                        }
                    }

                    Button("Reset to Defaults", role: .destructive) {
                        settings.selectionMode = .random
                        settings.favoredPosition = 1
                        settings.favoredProbability = 80
                        settings.countdownDuration = 2
                        settings.stabilizationDelay = 1
                        if store.isPremium {
                            settings.backgroundTheme = .midnight
                        }
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
            .sheet(isPresented: $showUpgradeSheet) {
                UpgradeView()
                    .interactiveDismissDisabled(false)
                    .presentationDetents([.large])
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

// MARK: - Pro Feature Row

private struct ProFeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.yellow)
                .font(.system(size: 13))
                .frame(width: 20)
            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView(settings: GameSettings())
}
