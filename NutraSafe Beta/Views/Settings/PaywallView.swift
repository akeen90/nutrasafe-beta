import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss

    private var hasFreeTrial: Bool {
        if let offer = subscriptionManager.product?.subscription?.introductoryOffer {
            return offer.paymentMode == .freeTrial
        }
        return false
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

    private var disclosureText: String {
        var base = "Auto\u{2011}renews at \(priceText)"
        if hasFreeTrial { base += " after 1\u{2011}week free trial" }
        return base + ". Cancel anytime in Settings."
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
                            if hasFreeTrial {
                                Text("Start your 1\u{2011}week free trial")
                                    .foregroundColor(.green)
                            }
                        }

                        // Benefits card
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Why upgrade")
                                .font(.headline)
                            VStack(alignment: .leading, spacing: 12) {
                                Label("Nutrition insights for everyday decisions", systemImage: "chart.bar.doc.horizontal")
                                Label("Log reactions to spot patterns fast", systemImage: "waveform.path.ecg")
                                Label("Smart reminders for opened items and expiry", systemImage: "calendar.badge.clock")
                                Label("Waste less, save more — clearer fridge memory", systemImage: "leaf")
                            }
                            .padding(16)
                            .background(.ultraThinMaterial)
                            .cornerRadius(16)

                            HStack(spacing: 12) {
                                Label("Cancel anytime", systemImage: "xmark.circle")
                                Label("Private & secure", systemImage: "lock.shield")
                                Label("Easy restore", systemImage: "arrow.triangle.2.circlepath")
                            }
                            .foregroundColor(.secondary)
                            .font(.footnote)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 8)

                        // Primary CTA
                        Button(action: { Task { try? await subscriptionManager.purchase() } }) {
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
                            Button("Restore Purchases") { Task { try? await subscriptionManager.restore() } }
                            Button("Manage Subscription") { Task { await subscriptionManager.manageSubscriptions() } }
                        }
                        .buttonStyle(.bordered)

                        // Disclosure
                        Text(disclosureText)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
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