import SwiftUI

struct OnboardingView: View {
    @State private var currentStep = 0
    @State private var acceptedTerms = false
    @State private var acceptedPrivacy = false
    @State private var acceptedHealthDisclaimer = false
    @State private var acceptedDataProcessing = false
    @Binding var isComplete: Bool
    
    private let totalSteps = 5
    
    var body: some View {
        VStack {
            // Progress indicator
            ProgressView(value: Double(currentStep), total: Double(totalSteps))
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .padding(.horizontal)
                .padding(.top)
            
            TabView(selection: $currentStep) {
                WelcomeStepView()
                    .tag(0)
                
                HealthDisclaimerStepView(accepted: $acceptedHealthDisclaimer)
                    .tag(1)
                
                PrivacyGDPRStepView(
                    acceptedPrivacy: $acceptedPrivacy,
                    acceptedDataProcessing: $acceptedDataProcessing
                )
                    .tag(2)
                
                TermsStepView(accepted: $acceptedTerms)
                    .tag(3)
                
                CompleteStepView()
                    .tag(4)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            
            // Navigation buttons
            HStack {
                if currentStep > 0 {
                    Button("Back") {
                        withAnimation {
                            currentStep -= 1
                        }
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.blue)
                }
                
                Spacer()
                
                if currentStep < totalSteps - 1 {
                    Button("Continue") {
                        withAnimation {
                            currentStep += 1
                        }
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(canContinue ? Color.blue : Color.gray)
                    .cornerRadius(8)
                    .disabled(!canContinue)
                } else {
                    Button("Get Started") {
                        isComplete = true
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(allAccepted ? Color.green : Color.gray)
                    .cornerRadius(8)
                    .disabled(!allAccepted)
                }
            }
            .padding()
        }
    }
    
    private var canContinue: Bool {
        switch currentStep {
        case 0: return true
        case 1: return acceptedHealthDisclaimer
        case 2: return acceptedPrivacy && acceptedDataProcessing
        case 3: return acceptedTerms
        default: return true
        }
    }
    
    private var allAccepted: Bool {
        acceptedTerms && acceptedPrivacy && acceptedHealthDisclaimer && acceptedDataProcessing
    }
}

struct WelcomeStepView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer()
                
                // App icon and name
                VStack(spacing: 16) {
                    Text("🥗")
                        .font(.system(size: 80))
                    
                    Text("Welcome to NutraSafe")
                        .font(.system(size: 28, weight: .bold))
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 16) {
                    Text("Your Personal Nutrition & Allergen Companion")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Text("Designed specifically for UK users with comprehensive allergen detection, nutrition tracking, and health monitoring.")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    FeatureRow(icon: "🛡️", title: "Allergen Protection", description: "Advanced allergen detection with UK food database")
                    FeatureRow(icon: "📊", title: "Nutrition Tracking", description: "Comprehensive nutrition analysis with NHS guidelines")
                    FeatureRow(icon: "💓", title: "Health Integration", description: "Apple Health compatibility for complete wellness tracking")
                    FeatureRow(icon: "🔒", title: "Privacy First", description: "GDPR compliant with your data staying secure")
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Spacer()
            }
            .padding()
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(icon)
                .font(.system(size: 24))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(nil)
            }
        }
    }
}

struct HealthDisclaimerStepView: View {
    @Binding var accepted: Bool
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("⚕️")
                            .font(.system(size: 32))
                        Text("Important Health Information")
                            .font(.system(size: 22, weight: .bold))
                    }
                    
                    Text("Please read this carefully before continuing")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    HealthDisclaimerSection(
                        title: "🏥 Not Medical Advice",
                        content: "NutraSafe is not a medical device and does not provide medical advice, diagnosis, or treatment. This app is designed for general nutritional information and allergen awareness only."
                    )
                    
                    HealthDisclaimerSection(
                        title: "🩺 Consult Your Healthcare Provider",
                        content: "Always consult with your GP, dietitian, or other qualified healthcare professional regarding dietary concerns, allergies, or medical conditions. If you have severe allergies, continue following your existing medical management plan."
                    )
                    
                    HealthDisclaimerSection(
                        title: "⚠️ No Liability for Allergen Information",
                        content: "While we strive for accuracy, we cannot guarantee the completeness or accuracy of allergen information. Always check product labels and verify with manufacturers, especially for severe allergies."
                    )
                    
                    HealthDisclaimerSection(
                        title: "🚨 Emergency Situations",
                        content: "In case of severe allergic reaction, call 999 immediately. This app is not designed for emergency situations and should never replace seeking immediate medical attention."
                    )
                    
                    HealthDisclaimerSection(
                        title: "🍽️ Individual Dietary Needs",
                        content: "Nutritional needs vary by individual. This app provides general guidance based on UK dietary guidelines but may not be suitable for all medical conditions or dietary requirements."
                    )
                }
                
                VStack(spacing: 12) {
                    Divider()
                    
                    Button(action: {
                        accepted.toggle()
                    }) {
                        HStack {
                            Image(systemName: accepted ? "checkmark.square.fill" : "square")
                                .foregroundColor(accepted ? .green : .gray)
                            
                            Text("I understand that NutraSafe is not a medical device and does not replace professional healthcare advice. I will continue to follow my healthcare provider's guidance for all medical matters.")
                                .font(.system(size: 14))
                                .multilineTextAlignment(.leading)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding()
        }
    }
}

struct HealthDisclaimerSection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
            
            Text(content)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .lineLimit(nil)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct PrivacyGDPRStepView: View {
    @Binding var acceptedPrivacy: Bool
    @Binding var acceptedDataProcessing: Bool
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("🔒")
                            .font(.system(size: 32))
                        Text("Privacy & Data Protection")
                            .font(.system(size: 22, weight: .bold))
                    }
                    
                    Text("Your privacy rights under UK GDPR")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    GDPRSection(
                        title: "📱 What Data We Collect",
                        content: "• Nutrition and food diary entries\n• Allergen preferences and dietary restrictions\n• Health data you choose to sync from Apple Health\n• Anonymous usage analytics to improve the app"
                    )
                    
                    GDPRSection(
                        title: "🛡️ How We Protect Your Data",
                        content: "• All personal data encrypted in transit and at rest\n• Servers located in the UK/EU for GDPR compliance\n• No data sharing with third parties without your consent\n• Regular security audits and updates"
                    )
                    
                    GDPRSection(
                        title: "⚖️ Your Rights Under UK GDPR",
                        content: "• Right to access your personal data\n• Right to correct inaccurate information\n• Right to delete your data (right to be forgotten)\n• Right to data portability\n• Right to object to data processing"
                    )
                    
                    GDPRSection(
                        title: "📊 Lawful Basis for Processing",
                        content: "We process your data based on:\n• Your consent for optional features\n• Legitimate interest for app functionality\n• Vital interest for allergen safety features\n• Legal obligation for health and safety compliance"
                    )
                    
                    GDPRSection(
                        title: "🕒 Data Retention",
                        content: "• Active account data retained while you use the app\n• Anonymous analytics retained for 2 years maximum\n• Account deletion removes all personal data within 30 days\n• Legal right to request immediate deletion"
                    )
                }
                
                VStack(spacing: 16) {
                    Divider()
                    
                    Button(action: {
                        acceptedPrivacy.toggle()
                    }) {
                        HStack {
                            Image(systemName: acceptedPrivacy ? "checkmark.square.fill" : "square")
                                .foregroundColor(acceptedPrivacy ? .green : .gray)
                            
                            Text("I agree to the Privacy Policy and understand how my data will be processed under UK GDPR.")
                                .font(.system(size: 14))
                                .multilineTextAlignment(.leading)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        acceptedDataProcessing.toggle()
                    }) {
                        HStack {
                            Image(systemName: acceptedDataProcessing ? "checkmark.square.fill" : "square")
                                .foregroundColor(acceptedDataProcessing ? .green : .gray)
                            
                            Text("I consent to the processing of my health and nutrition data for the purposes of app functionality and allergen safety features.")
                                .font(.system(size: 14))
                                .multilineTextAlignment(.leading)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Text("Data Controller: NutraSafe Ltd, UK\nContact: privacy@nutrasafe.com")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top)
                }
            }
            .padding()
        }
    }
}

struct GDPRSection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
            
            Text(content)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .lineLimit(nil)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct TermsStepView: View {
    @Binding var accepted: Bool
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("📋")
                            .font(.system(size: 32))
                        Text("Terms & Conditions")
                            .font(.system(size: 22, weight: .bold))
                    }
                    
                    Text("UK Terms of Service")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    TermsSection(
                        title: "📱 App Usage",
                        content: "NutraSafe is provided as-is for personal, non-commercial use. You agree to use the app responsibly and not to misuse or attempt to circumvent security measures."
                    )
                    
                    TermsSection(
                        title: "💷 Subscription & Billing",
                        content: "Free features are provided at no cost. Premium features, if any, will be clearly disclosed with pricing in GBP. Billing managed through App Store with standard Apple terms applying."
                    )
                    
                    TermsSection(
                        title: "🔄 Updates & Changes",
                        content: "We may update the app and these terms periodically. Material changes will be communicated through the app or email. Continued use constitutes acceptance of updated terms."
                    )
                    
                    TermsSection(
                        title: "⚖️ Limitation of Liability",
                        content: "Under English law, our liability is limited to the maximum extent permitted. We are not liable for indirect damages or losses arising from app use, except where prohibited by law."
                    )
                    
                    TermsSection(
                        title: "🏴󠁧󠁢󠁥󠁮󠁧󠁿 Governing Law",
                        content: "These terms are governed by English and Welsh law. Any disputes will be resolved in the courts of England and Wales. UK consumer rights remain protected under applicable legislation."
                    )
                    
                    TermsSection(
                        title: "📞 Contact & Support",
                        content: "For support or legal inquiries:\nEmail: support@nutrasafe.com\nAddress: NutraSafe Ltd, [UK Address]\nPhone: [UK Contact Number]"
                    )
                }
                
                VStack(spacing: 12) {
                    Divider()
                    
                    Button(action: {
                        accepted.toggle()
                    }) {
                        HStack {
                            Image(systemName: accepted ? "checkmark.square.fill" : "square")
                                .foregroundColor(accepted ? .green : .gray)
                            
                            Text("I agree to the Terms & Conditions and understand my rights as a UK consumer.")
                                .font(.system(size: 14))
                                .multilineTextAlignment(.leading)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding()
        }
    }
}

struct TermsSection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
            
            Text(content)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .lineLimit(nil)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct CompleteStepView: View {
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 24) {
                Text("🎉")
                    .font(.system(size: 80))
                
                Text("You're All Set!")
                    .font(.system(size: 28, weight: .bold))
                
                Text("Welcome to NutraSafe! You can now start tracking your nutrition, managing allergies, and maintaining a healthier lifestyle with confidence.")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
            
            VStack(spacing: 16) {
                QuickTipRow(icon: "👤", title: "Set up your profile", description: "Add your dietary preferences and allergen information")
                QuickTipRow(icon: "📱", title: "Enable Apple Health", description: "Sync exercise energy and health data")
                QuickTipRow(icon: "🔍", title: "Start food tracking", description: "Search, scan, or manually add your meals")
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            Spacer()
        }
        .padding()
    }
}

struct QuickTipRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(icon)
                .font(.system(size: 20))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    OnboardingView(isComplete: .constant(false))
}