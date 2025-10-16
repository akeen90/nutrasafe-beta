//
//  TermsAndConditionsView.swift
//  NutraSafe Beta
//
//  Terms and Conditions for the NutraSafe application
//

import SwiftUI

struct TermsAndConditionsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    HStack {
                        Spacer()
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        Spacer()
                    }
                    .padding(.top, 20)

                    Text("Terms and Conditions")
                        .font(.system(size: 28, weight: .bold))
                        .padding(.horizontal)

                    Text("Last Updated: October 2025")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .padding(.horizontal)

                    Divider()
                        .padding(.horizontal)

                    // Content Sections
                    VStack(alignment: .leading, spacing: 20) {
                        TermsSection(
                            number: "1",
                            title: "Acceptance of Terms",
                            content: """
                            By downloading, installing, or using NutraSafe ("the App"), you agree to be bound by these Terms and Conditions. If you do not agree to these terms, please do not use the App.

                            These terms constitute a legally binding agreement between you and NutraSafe regarding your use of the App and its services.
                            """
                        )

                        TermsSection(
                            number: "2",
                            title: "Description of Service",
                            content: """
                            NutraSafe is a nutrition tracking and food safety information application that provides:

                            • Food diary and calorie tracking
                            • Nutritional analysis and grading
                            • Allergen detection and warnings
                            • Food additive information from comprehensive databases
                            • Ingredient analysis and safety ratings
                            • Barcode scanning and AI-powered food recognition
                            • Micronutrient tracking and daily value calculations
                            • Food reaction logging and pattern analysis
                            • Personalized nutrition goals and recommendations

                            All information is provided for educational and informational purposes only.
                            """
                        )

                        TermsSection(
                            number: "3",
                            title: "User Accounts and Data",
                            content: """
                            You are responsible for:
                            • Maintaining the confidentiality of your account credentials
                            • All activities that occur under your account
                            • Ensuring the accuracy of information you provide
                            • Notifying us of any unauthorized use of your account

                            We reserve the right to terminate accounts that violate these terms or engage in fraudulent activity.
                            """
                        )

                        TermsSection(
                            number: "4",
                            title: "Medical Disclaimer",
                            content: """
                            NutraSafe is NOT a medical device and does NOT provide medical advice, diagnosis, or treatment.

                            • The App is for informational and educational purposes only
                            • Information should not replace professional medical advice
                            • Always consult qualified healthcare providers for medical concerns
                            • Do not disregard or delay seeking medical advice based on App content
                            • In case of medical emergency, call emergency services immediately

                            Individual nutritional needs vary. The App's recommendations are general guidelines and may not be suitable for everyone, especially those with medical conditions, pregnant women, children, or elderly users.
                            """
                        )

                        TermsSection(
                            number: "5",
                            title: "Food Database and Accuracy",
                            content: """
                            Food information is sourced from:
                            • Public nutritional databases
                            • Manufacturer-provided data
                            • Third-party APIs and services
                            • User contributions and submissions

                            While we strive for accuracy, we cannot guarantee:
                            • Complete accuracy of all nutritional data
                            • Real-time updates for all products
                            • Detection of all allergens or ingredients
                            • Accuracy of barcode or AI scanning results

                            Always verify critical information (especially allergens) with product packaging and manufacturers.
                            """
                        )

                        TermsSection(
                            number: "6",
                            title: "Allergen and Safety Warnings",
                            content: """
                            The App provides allergen detection features, but:

                            • We cannot guarantee complete allergen detection
                            • Databases may contain errors or omissions
                            • Food formulations can change without notice
                            • Cross-contamination information may not be available

                            If you have severe allergies or medical conditions:
                            • Always read product labels yourself
                            • Verify ingredients with manufacturers
                            • Do not rely solely on the App for safety decisions
                            • Carry appropriate emergency medication
                            """
                        )

                        TermsSection(
                            number: "7",
                            title: "Additive Information",
                            content: """
                            The App provides information about food additives (E-numbers) from comprehensive databases including regulatory status, safety ratings, and potential health effects.

                            This information is:
                            • Compiled from public sources and scientific literature
                            • Subject to ongoing research and regulatory changes
                            • General guidance, not personalized advice
                            • Not a substitute for official regulatory guidance

                            Regulatory approval and safety standards vary by country. Information may not reflect your local jurisdiction's current regulations.
                            """
                        )

                        TermsSection(
                            number: "8",
                            title: "User-Generated Content",
                            content: """
                            By submitting content to the App (food entries, reviews, photos), you:

                            • Grant us a worldwide, royalty-free license to use, store, and display your content
                            • Confirm you have the rights to submit the content
                            • Agree not to submit false, misleading, or harmful information
                            • Understand we may remove content that violates these terms

                            We are not responsible for user-generated content and do not endorse user opinions or recommendations.
                            """
                        )

                        TermsSection(
                            number: "9",
                            title: "Intellectual Property",
                            content: """
                            The App and its content are protected by copyright, trademark, and other intellectual property laws.

                            You may not:
                            • Copy, modify, or distribute the App or its content
                            • Reverse engineer or decompile the App
                            • Remove copyright or proprietary notices
                            • Use the App's data for commercial purposes without permission

                            All trademarks, logos, and brand names are property of their respective owners.
                            """
                        )

                        TermsSection(
                            number: "10",
                            title: "Privacy and Data Collection",
                            content: """
                            We collect and process personal data as described in our Privacy Policy, including:

                            • Account information (email address)
                            • Nutrition and diet data you enter
                            • Food diary and tracking information
                            • Allergen and health preferences
                            • Usage analytics and diagnostics

                            Your data is stored securely using Firebase Cloud services. Please review our Privacy Policy for complete details.
                            """
                        )

                        TermsSection(
                            number: "11",
                            title: "Third-Party Services",
                            content: """
                            The App integrates with third-party services:

                            • Google AI (Gemini) for image recognition
                            • Firebase for authentication and data storage
                            • External nutritional databases and APIs
                            • Apple HealthKit for health data integration

                            Use of these services is subject to their respective terms and privacy policies. We are not responsible for third-party service availability, accuracy, or policies.
                            """
                        )

                        TermsSection(
                            number: "12",
                            title: "Barcode and AI Scanning",
                            content: """
                            The App offers barcode scanning and AI-powered food recognition features.

                            These features:
                            • May produce inaccurate or incomplete results
                            • Depend on database coverage and image quality
                            • Should be verified against actual product packaging
                            • Are provided "as-is" without guarantees of accuracy

                            Always confirm scanned information before relying on it for important decisions.
                            """
                        )

                        TermsSection(
                            number: "13",
                            title: "Limitation of Liability",
                            content: """
                            TO THE MAXIMUM EXTENT PERMITTED BY LAW:

                            • The App is provided "AS IS" without warranties of any kind
                            • We are not liable for any damages arising from App use
                            • We do not warrant accuracy, completeness, or reliability
                            • We are not responsible for decisions made based on App information
                            • Total liability is limited to the amount you paid for the App

                            This includes, but is not limited to, damages from:
                            • Allergic reactions or adverse health events
                            • Inaccurate nutritional or allergen information
                            • Data loss or security breaches
                            • App unavailability or technical issues
                            """
                        )

                        TermsSection(
                            number: "14",
                            title: "Indemnification",
                            content: """
                            You agree to indemnify and hold harmless NutraSafe, its developers, and affiliates from any claims, damages, or expenses arising from:

                            • Your use or misuse of the App
                            • Your violation of these Terms
                            • Your violation of any third-party rights
                            • Information you submit to the App
                            """
                        )

                        TermsSection(
                            number: "15",
                            title: "Changes to Terms",
                            content: """
                            We reserve the right to modify these Terms at any time. Changes will be effective immediately upon posting within the App.

                            Continued use of the App after changes constitutes acceptance of the modified Terms. We recommend reviewing these Terms periodically.
                            """
                        )

                        TermsSection(
                            number: "16",
                            title: "App Availability and Changes",
                            content: """
                            We reserve the right to:

                            • Modify, suspend, or discontinue the App at any time
                            • Change features, functionality, or pricing
                            • Limit access to certain features or regions
                            • Perform maintenance that may temporarily restrict access

                            We are not liable for any modifications or discontinuation of service.
                            """
                        )

                        TermsSection(
                            number: "17",
                            title: "Termination",
                            content: """
                            We may terminate or suspend your access immediately, without prior notice, for:

                            • Breach of these Terms
                            • Fraudulent or illegal activity
                            • Harmful conduct toward other users
                            • Failure to pay applicable fees

                            You may terminate your account at any time through the App settings. Upon termination, your right to use the App ceases immediately.
                            """
                        )

                        TermsSection(
                            number: "18",
                            title: "Governing Law",
                            content: """
                            These Terms are governed by the laws of the United Kingdom, without regard to conflict of law principles.

                            Any disputes arising from these Terms or App use shall be resolved through:
                            • Good faith negotiation
                            • Binding arbitration if negotiation fails
                            • Courts of competent jurisdiction in the UK as a last resort
                            """
                        )

                        TermsSection(
                            number: "19",
                            title: "Severability",
                            content: """
                            If any provision of these Terms is found to be unenforceable or invalid, that provision shall be limited or eliminated to the minimum extent necessary so that these Terms shall otherwise remain in full force and effect.
                            """
                        )

                        TermsSection(
                            number: "20",
                            title: "Contact Information",
                            content: """
                            For questions, concerns, or feedback regarding these Terms, please contact us through the App's support channels or email.

                            We aim to respond to all inquiries within 5-7 business days.
                            """
                        )
                    }
                    .padding(.horizontal)

                    // Footer
                    VStack(spacing: 12) {
                        Text("By using NutraSafe, you acknowledge that you have read, understood, and agree to be bound by these Terms and Conditions.")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)

                        Text("These terms protect both you and us. Please read them carefully.")
                            .font(.system(size: 13))
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
            .navigationTitle("Terms & Conditions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct TermsSection: View {
    let number: String
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Text(number)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.blue)
                    .frame(width: 30, alignment: .leading)

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
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
}
