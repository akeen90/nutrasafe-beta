import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss

    private var hasFreeTrial: Bool {
        // Check if product has a free trial available AND user is eligible
        // This ensures "Start Free Trial" only shows to users who can actually get the trial
        guard let offer = subscriptionManager.product?.subscription?.introductoryOffer else {
            return false
        }
        // Must check BOTH: product has trial offer AND user hasn't used it before
        return offer.paymentMode == .freeTrial && subscriptionManager.isEligibleForTrial
    }

    private var priceText: String {
        if let product = subscriptionManager.product {
            return "\(product.displayPrice)/month"
        }
        return "£2.99/month"
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
                                Label("Access detailed nutrition information and data", systemImage: "chart.bar.doc.horizontal")
                                Label("Track your nutrient intake against reference values", systemImage: "waveform.path.ecg")
                                Label("Smart reminders for opened food expiry", systemImage: "calendar.badge.clock")
                                Label("Log food reactions and identify patterns", systemImage: "heart.text.square")
                            }
                            .padding(16)
                            .background(.ultraThinMaterial)
                            .cornerRadius(16)

                            // Disclaimer
                            Text("For informational purposes only. Not medical advice. Consult healthcare professionals for dietary guidance.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                                .padding(.horizontal, 8)

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
                                if subscriptionManager.isPurchasing {
                                    ProgressView().scaleEffect(0.9)
                                } else if !subscriptionManager.isProductLoaded {
                                    ProgressView().scaleEffect(0.9)
                                    Text("Loading...")
                                        .font(.system(size: 18, weight: .semibold))
                                } else {
                                    Text(ctaText)
                                        .font(.system(size: 18, weight: .semibold))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(!subscriptionManager.isProductLoaded || subscriptionManager.isPurchasing)

                        // Error message with retry
                        if let error = subscriptionManager.purchaseError {
                            VStack(spacing: 12) {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)

                                Button("Try Again") {
                                    Task {
                                        subscriptionManager.purchaseError = nil
                                        try? await subscriptionManager.load()
                                    }
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }

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