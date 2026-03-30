import SwiftUI

/// Full-screen paywall sheet — clean iOS-style upgrade prompt.
struct UpgradeView: View {
    @ObservedObject private var store = StoreManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var animateCrown = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.05, blue: 0.18),
                        Color(red: 0.02, green: 0.02, blue: 0.08)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Scrollable content
                    ScrollView {
                        VStack(spacing: 24) {

                            // Crown icon
                            ZStack {
                                Circle()
                                    .fill(.yellow.opacity(0.1))
                                    .frame(width: 100, height: 100)

                                Circle()
                                    .fill(.yellow.opacity(0.05))
                                    .frame(width: 130, height: 130)

                                Image(systemName: "crown.fill")
                                    .font(.system(size: 44))
                                    .foregroundStyle(.yellow)
                            }
                            .padding(.top, 24)

                            // Title
                            VStack(spacing: 6) {
                                Text("Choosr Pro")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)

                                Text("Unlock the full experience")
                                    .font(.system(size: 16))
                                    .foregroundStyle(.white.opacity(0.6))
                            }

                            // Feature list
                            VStack(spacing: 16) {
                                FeatureRow(
                                    icon: "slider.horizontal.3",
                                    iconColor: .orange,
                                    title: "Decide Who Wins",
                                    subtitle: "Control who wins with adjustable probability per player"
                                )

                                FeatureRow(
                                    icon: "paintpalette.fill",
                                    iconColor: .purple,
                                    title: "Premium Themes",
                                    subtitle: "Beautiful gradient backgrounds — Midnight, Ocean, Sunset & more"
                                )

                                FeatureRow(
                                    icon: "heart.fill",
                                    iconColor: .pink,
                                    title: "Support Development",
                                    subtitle: "One-time purchase, no subscriptions, no ads"
                                )
                            }
                            .padding(.horizontal, 24)
                        }
                    }

                    // Pinned purchase button at bottom
                    VStack(spacing: 10) {
                        Button {
                            Task { await store.purchase() }
                        } label: {
                            HStack(spacing: 8) {
                                if case .purchasing = store.purchaseState {
                                    ProgressView()
                                        .tint(.black)
                                } else {
                                    Text("Upgrade for \(priceText)")
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                }
                            }
                            .frame(maxWidth: 500)
                            .frame(height: 56)
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(
                                    colors: [.yellow, .orange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundStyle(.black)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .buttonStyle(.plain)
                        .disabled(store.purchaseState == .purchasing)

                        // Restore
                        Button {
                            Task { await store.restore() }
                        } label: {
                            Text("Restore Purchase")
                                .font(.system(size: 14))
                                .foregroundStyle(.white.opacity(0.4))
                        }

                        // Status messages
                        if case .failed(let msg) = store.purchaseState {
                            Text(msg)
                                .font(.caption)
                                .foregroundStyle(.red.opacity(0.8))
                        }

                        if case .restored = store.purchaseState {
                            Text("Purchase restored!")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 34)
                    .padding(.top, 12)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 0.02, green: 0.02, blue: 0.08),
                                Color(red: 0.02, green: 0.02, blue: 0.08).opacity(0.95)
                            ],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.white.opacity(0.3))
                            .font(.system(size: 28))
                    }
                }
            }
            .onAppear {
                animateCrown = true
            }
            .onChange(of: store.isPremium) { newValue in
                if newValue {
                    // Auto-dismiss after successful purchase
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        dismiss()
                    }
                }
            }
        }
    }

    private var priceText: String {
        store.product?.displayPrice ?? "€1.99"
    }
}

// MARK: - Feature Row

private struct FeatureRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.5))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
    }
}

// MARK: - Equatable for PurchaseState (used by .disabled)

extension StoreManager.PurchaseState: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.purchasing, .purchasing),
             (.purchased, .purchased), (.restored, .restored):
            return true
        case (.failed(let a), .failed(let b)):
            return a == b
        default:
            return false
        }
    }
}

#Preview {
    UpgradeView()
}
