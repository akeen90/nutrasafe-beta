//
//  PrivacyPolicyView.swift
//  NutraSafe Beta
//
//  Privacy Policy for the NutraSafe application
//

import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    HStack {
                        Spacer()
                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                        Spacer()
                    }
                    .padding(.top, 20)

                    Text("Privacy Policy")
                        .font(.system(size: 28, weight: .bold))
                        .padding(.horizontal)

                    Text("Last Updated: October 2025")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .padding(.horizontal)

                    // Introduction
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your Privacy Matters")
                            .font(.system(size: 20, weight: .semibold))

                        Text("""
                        NutraSafe is committed to protecting your privacy. This Privacy Policy explains how we collect, use, store, and protect your personal information when you use our nutrition tracking and food safety application.

                        We believe in transparency and give you control over your data. Please read this policy carefully to understand our practices.
                        """)
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    Divider()
                        .padding(.horizontal)

                    // Content Sections
                    VStack(alignment: .leading, spacing: 20) {
                        PrivacySection(
                            icon: "person.circle.fill",
                            iconColor: AppPalette.standard.accent,
                            title: "1. Information We Collect",
                            content: """
                            Account Information:
                            • Email address (for authentication)
                            • Password (encrypted and never stored in plain text)
                            • Account creation date

                            Nutrition & Health Data:
                            • Food diary entries and meal logs
                            • Calorie and macronutrient tracking data
                            • Weight history and body measurements
                            • Height and BMI calculations
                            • Nutrition goals and preferences
                            • Allergen and sensitivity information
                            • Food reaction logs and symptoms
                            • Micronutrient intake tracking
                            • Fasting and exercise data

                            Usage Information:
                            • Foods scanned or searched
                            • Feature usage patterns
                            • App interaction analytics
                            • Crash reports and diagnostics
                            • Device type and operating system version

                            Camera & Photos:
                            • Photos of food labels and barcodes (only when you use scanning features)
                            • Processed temporarily for AI recognition
                            • Not stored permanently unless you save them to your diary
                            """
                        )

                        PrivacySection(
                            icon: "gear.circle.fill",
                            iconColor: .purple,
                            title: "2. How We Use Your Information",
                            content: """
                            We use your data to:

                            Core Functionality:
                            • Provide nutrition tracking and analysis
                            • Calculate personalized nutrition recommendations
                            • Detect allergens in foods based on your profile
                            • Analyze food safety and additive information
                            • Track your progress toward health goals
                            • Synchronize data across your devices

                            Improve the App:
                            • Identify and fix bugs and errors
                            • Understand which features are most useful
                            • Optimize performance and user experience
                            • Develop new features based on usage patterns

                            Safety & Security:
                            • Detect and prevent fraudulent activity
                            • Protect against security threats
                            • Ensure data integrity and accuracy
                            • Comply with legal obligations

                            We do NOT:
                            • Sell your personal data to third parties
                            • Use your health data for advertising
                            • Share identifiable information without consent
                            • Track you across other apps or websites
                            """
                        )

                        PrivacySection(
                            icon: "cloud.fill",
                            iconColor: .cyan,
                            title: "3. Data Storage and Security",
                            content: """
                            Where Your Data is Stored:
                            • All data is stored securely using Google Firebase Cloud Services
                            • Servers are located in secure data centers with industry-standard protection
                            • Data is encrypted both in transit (HTTPS/TLS) and at rest
                            • We use Firebase Authentication for secure login

                            Security Measures:
                            • Strong encryption protocols (AES-256)
                            • Secure authentication tokens
                            • Regular security audits and updates
                            • Access controls and monitoring
                            • Automatic logout after inactivity
                            • Protection against common attacks (SQL injection, XSS, etc.)

                            Data Backup:
                            • Automatic cloud backups ensure you don't lose your data
                            • Backups are encrypted with the same standards as live data
                            • You can export your data at any time
                            """
                        )

                        PrivacySection(
                            icon: "arrow.triangle.2.circlepath.circle.fill",
                            iconColor: .green,
                            title: "4. Data Sharing and Third Parties",
                            content: """
                            Service Providers We Use:
                            • Google Firebase (authentication, database, cloud storage)
                            • Google AI Gemini (for AI-powered food recognition)
                            • External nutrition databases (for food information)

                            These providers:
                            • Process data on our behalf only
                            • Are bound by strict data protection agreements
                            • Cannot use your data for their own purposes
                            • Maintain industry-standard security

                            We Share Data When:
                            • Required by law or legal process
                            • Necessary to protect rights and safety
                            • Investigating potential policy violations
                            • With your explicit consent

                            We Never:
                            • Sell your data to advertisers or marketers
                            • Share identifiable health data for commercial purposes
                            • Provide data to insurance companies
                            • Use your information for targeted advertising
                            """
                        )

                        PrivacySection(
                            icon: "healthkit",
                            iconColor: .pink,
                            title: "5. Apple HealthKit Integration",
                            content: """
                            If you enable HealthKit integration:

                            Data We Access:
                            • Exercise calorie data (with your permission)
                            • Dietary energy/nutrition data (if shared)
                            • Weight and body measurements (if shared)

                            Important Notes:
                            • HealthKit data never leaves your device without consent
                            • We only read data you explicitly authorize
                            • HealthKit data is not uploaded to our servers
                            • Used locally on your device for calculations only
                            • You can revoke HealthKit access anytime in Settings

                            We comply with Apple's HealthKit data usage policies and never share HealthKit data with third parties or use it for advertising.
                            """
                        )

                        PrivacySection(
                            icon: "person.fill.checkmark",
                            iconColor: .orange,
                            title: "6. Your Privacy Rights",
                            content: """
                            You Have the Right To:

                            Access Your Data:
                            • View all data we store about you
                            • Request a copy of your data in readable format
                            • Understand how your data is being used

                            Control Your Data:
                            • Edit or update your information anytime
                            • Delete specific entries or data points
                            • Export all your data in JSON format
                            • Permanently delete your entire account

                            Privacy Settings:
                            • Choose which features to enable
                            • Control safety alerts and notifications
                            • Manage HealthKit data sharing
                            • Opt out of analytics and diagnostics

                            To exercise these rights, use the Data & Privacy settings in the app or contact our support team.
                            """
                        )

                        PrivacySection(
                            icon: "trash.circle.fill",
                            iconColor: .red,
                            title: "7. Data Retention and Deletion",
                            content: """
                            How Long We Keep Your Data:
                            • Active account data: Stored while your account is active
                            • Deleted entries: Removed immediately from active database
                            • Backups: Retained for up to 30 days, then permanently deleted
                            • Analytics: Aggregated/anonymized data retained indefinitely

                            Deleting Your Data:
                            • Delete specific entries: Use delete buttons in the app
                            • Delete all data: Go to Settings → Data & Privacy → Delete All Data
                            • Delete account: Go to Settings → Account → Delete Account

                            After Deletion:
                            • Data is immediately removed from production systems
                            • Backups are purged within 30 days
                            • Some aggregated analytics may remain (anonymized)
                            • Deletion is permanent and cannot be undone

                            We retain data only as long as necessary for the purposes outlined in this policy.
                            """
                        )

                        PrivacySection(
                            icon: "shield.lefthalf.filled",
                            iconColor: AppPalette.standard.accent,
                            title: "8. Children's Privacy",
                            content: """
                            NutraSafe is not intended for children under 13 years of age.

                            • We do not knowingly collect data from children under 13
                            • We do not target or market to children
                            • If we discover data from a child under 13, we delete it immediately

                            Parents/Guardians:
                            • May use the app to track nutrition for children under their supervision
                            • Are responsible for data entered about their children
                            • Should review this policy before allowing children to use the app

                            If you believe we have inadvertently collected data from a child under 13, please contact us immediately.
                            """
                        )

                        PrivacySection(
                            icon: "location.circle.fill",
                            iconColor: .green,
                            title: "9. Location Data",
                            content: """
                            NutraSafe does NOT collect or track your location data.

                            • We do not use GPS or location services
                            • We do not track where you eat or shop
                            • We do not create location-based profiles
                            • Location permissions are never requested

                            Any location-related features (if added in future) will be clearly disclosed and require explicit opt-in consent.
                            """
                        )

                        PrivacySection(
                            icon: "dollarsign.circle.fill",
                            iconColor: .yellow,
                            title: "10. Advertising and Marketing",
                            content: """
                            NutraSafe currently does not display advertisements.

                            If we introduce ads in the future:
                            • We will update this policy with clear notice
                            • Ads will not be personalized based on your health data
                            • You will have options to limit ad tracking
                            • We will never sell your personal data to advertisers

                            Marketing Communications:
                            • We may send service-related emails (password resets, updates)
                            • We do not send promotional emails (currently)
                            • You can opt out of any future marketing emails
                            """
                        )

                        PrivacySection(
                            icon: "globe.europe.africa.fill",
                            iconColor: .purple,
                            title: "11. International Data Transfers",
                            content: """
                            Your data may be transferred to and stored in countries outside your country of residence, including:

                            • United States (Firebase servers)
                            • European Union (Firebase regions)
                            • Other countries where our service providers operate

                            When we transfer data internationally:
                            • We ensure adequate protection through contractual agreements
                            • We comply with applicable data protection laws
                            • We use encryption during transit
                            • We maintain the same security standards globally

                            If you are in the EU/EEA or UK, we comply with GDPR requirements for international data transfers.
                            """
                        )

                        PrivacySection(
                            icon: "exclamationmark.triangle.fill",
                            iconColor: .red,
                            title: "12. Data Breach Notification",
                            content: """
                            In the unlikely event of a data breach:

                            • We will investigate immediately
                            • We will notify affected users promptly (within 72 hours when possible)
                            • We will inform relevant authorities as required by law
                            • We will provide guidance on protective measures
                            • We will take steps to prevent future breaches

                            Our Commitment:
                            • Regular security audits and penetration testing
                            • Continuous monitoring for suspicious activity
                            • Rapid response protocols for security incidents
                            • Transparent communication if issues occur
                            """
                        )

                        PrivacySection(
                            icon: "doc.text.fill",
                            iconColor: .orange,
                            title: "13. Legal Basis for Processing (GDPR)",
                            content: """
                            For users in the EU/EEA/UK, we process your data based on:

                            Consent:
                            • When you create an account and agree to our terms
                            • When you enable optional features (HealthKit, AI scanning)
                            • You can withdraw consent anytime

                            Contractual Necessity:
                            • To provide the services you requested
                            • To maintain your account and sync data
                            • To fulfill our obligations under Terms of Use

                            Legitimate Interests:
                            • Improving app functionality and user experience
                            • Detecting and preventing fraud
                            • Ensuring security and integrity

                            Legal Obligation:
                            • Complying with laws and regulations
                            • Responding to legal requests
                            """
                        )

                        PrivacySection(
                            icon: "pencil.circle.fill",
                            iconColor: AppPalette.standard.accent,
                            title: "14. Changes to This Privacy Policy",
                            content: """
                            We may update this Privacy Policy from time to time to reflect:
                            • Changes in our practices
                            • New features or functionality
                            • Legal or regulatory requirements
                            • Improvements based on user feedback

                            When We Update:
                            • We will post the new policy in the app
                            • We will update the "Last Updated" date
                            • We will notify you of significant changes
                            • Continued use constitutes acceptance of changes

                            We recommend reviewing this policy periodically to stay informed about how we protect your privacy.
                            """
                        )

                        PrivacySection(
                            icon: "envelope.circle.fill",
                            iconColor: .green,
                            title: "15. Contact Us",
                            content: """
                            Questions, Concerns, or Requests:

                            If you have questions about this Privacy Policy or want to exercise your privacy rights, please contact us through:

                            • App support channels (Settings → About → Help)
                            • Email support (check app for current address)
                            • Privacy request form (if available)

                            We aim to respond to all privacy inquiries within 5-7 business days.

                            Data Protection Officer:
                            For formal privacy complaints or GDPR-related matters, you may contact our Data Protection Officer through the channels above.

                            You also have the right to lodge a complaint with your local data protection authority if you believe we have not addressed your concerns adequately.
                            """
                        )
                    }
                    .padding(.horizontal)

                    // Footer
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(AppPalette.standard.accent)
                            Text("Your Privacy is Protected")
                                .font(.system(size: 16, weight: .semibold))
                        }

                        Text("We are committed to maintaining the highest standards of privacy and security. Your trust is important to us, and we will never compromise your personal information.")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 40)
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppAnimatedBackground().ignoresSafeArea())
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}

struct PrivacySection: View {
    let icon: String
    let iconColor: Color
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(iconColor)
                    .frame(width: 36)

                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
            }

            Text(content)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(Color.adaptiveCard)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
}
