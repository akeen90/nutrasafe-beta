import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss

    private var hasFreeTrial: Bool {
        // Check if product has a free trial available
        guard let offer = subscriptionManager.product?.subscription?.introductoryOffer else {
            return false
        }
        return offer.paymentMode == .freeTrial
    }

    private var priceText: String {
        if let product = subscriptionManager.product {
            return "\(product.displayPrice)/month"
        }
        return "£1.99/month"
    }

    private var ctaText: String {
        hasFreeTrial ? "Start Free Trial" : "Subscribe"
    }

    private var headerSubtitle: String {
        // Keep dynamic - show trial message if eligible, otherwise show tagline
        hasFreeTrial ? "Smarter tracking. Stronger nutrition habits." : "Smarter tracking. Stronger nutrition habits."
    }

    private var showTrialText: Bool {
        hasFreeTrial
    }

    private var trialText: String {
        "1 week free, then \(priceText)"
    }

    private var benefitTitle: String {
        "Why Upgrade"
    }

    private var disclosureText: String {
        if hasFreeTrial {
            return "1 week free, then \(priceText)"
        } else {
            return "Auto\u{2011}renews at \(priceText). Cancel anytime in Settings."
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(colors: [Color(.systemBackground), Color(.secondarySystemBackground)], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "star.circle.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.purple)
                            Text("NutraSafe Pro")
                                .font(.system(size: 28, weight: .bold))
                            Text(priceText)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.primary)
                            Text(headerSubtitle)
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }

                        // Benefits card
                        VStack(alignment: .leading, spacing: 16) {
                            Text(benefitTitle)
                                .font(.headline)
                            VStack(alignment: .leading, spacing: 12) {
                                Label("Unlock deeper nutrition insights that guide better choices", systemImage: "chart.bar.doc.horizontal")
                                Label("Spot missing nutrients and build a balanced routine", systemImage: "waveform.path.ecg")
                                Label("Smart reminders for opened food expiry — know what's still safe to eat", systemImage: "calendar.badge.clock")
                                Label("Track reactions and discover what really works for you", systemImage: "heart.text.square")
                            }
                            .padding(16)
                            .background(.ultraThinMaterial)
                            .cornerRadius(16)

                            // Your Subscription section
                            VStack(spacing: 12) {
                                Text("Your Subscription")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                HStack(spacing: 6) {
                                    Text("Cancel anytime")
                                    Text("•")
                                    Text("Private & secure")
                                    Text("•")
                                    Text("Restore easily")
                                }
                                .foregroundColor(.secondary)
                                .font(.footnote)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 8)

                        // Primary CTA
                        Button(action: {
                            Task {
                                try? await subscriptionManager.purchase()
                                // Auto-dismiss on successful subscription
                                if subscriptionManager.isSubscribed {
                                    dismiss()
                                }
                            }
                        }) {
                            HStack {
                                if subscriptionManager.isPurchasing { ProgressView().scaleEffect(0.9) }
                                Text(ctaText)
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)

                        // Secondary actions
                        HStack(spacing: 12) {
                            Button("Restore Purchases") {
                                Task {
                                    try? await subscriptionManager.restore()
                                    // Auto-dismiss if subscription was restored
                                    if subscriptionManager.isSubscribed {
                                        dismiss()
                                    }
                                }
                            }
                            Button("Manage Subscription") { Task { await subscriptionManager.manageSubscriptions() } }
                        }
                        .buttonStyle(.bordered)

                        // Disclosure
                        Text(disclosureText)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        // Legal Links
                        HStack(spacing: 8) {
                            Button("Terms of Use") {
                                if let url = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/") {
                                    UIApplication.shared.open(url)
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.blue)

                            Text("•")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Button("Privacy Policy") {
                                if let url = URL(string: "https://nutrasafe-705c7.web.app/privacy") {
                                    UIApplication.shared.open(url)
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                        .padding(.top, 8)
                    }
                    .padding()
                }
            }
            .navigationTitle("Premium")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", role: .cancel) { dismiss() }
                }
            }
            .task { try? await subscriptionManager.load() }
        }
    }
}