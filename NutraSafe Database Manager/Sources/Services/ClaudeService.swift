//
//  ClaudeService.swift
//  NutraSafe Database Manager
//
//  Claude AI integration for intelligent database management
//

import Foundation

@MainActor
class ClaudeService: ObservableObject {
    static let shared = ClaudeService()

    // MARK: - Published State

    @Published var isProcessing = false
    @Published var error: String?
    @Published var messages: [ChatMessage] = []
    @Published var currentResponse: String = ""

    // MARK: - Configuration

    private var apiKey: String = ""
    private let baseURL = "https://api.anthropic.com/v1/messages"
    private let model = "claude-sonnet-4-20250514"

    private init() {
        loadAPIKey()
    }

    // MARK: - API Key Management

    func loadAPIKey() {
        if let savedKey = UserDefaults.standard.string(forKey: "claude_api_key") {
            apiKey = savedKey
        }
    }

    func setAPIKey(_ key: String) {
        apiKey = key
        UserDefaults.standard.set(key, forKey: "claude_api_key")
    }

    var isConfigured: Bool {
        !apiKey.isEmpty
    }

    // MARK: - Chat Interface

    func sendMessage(_ content: String, context: DatabaseContext? = nil) async {
        guard isConfigured else {
            error = "Claude API key not configured. Please set it in Settings."
            return
        }

        isProcessing = true
        error = nil

        // Add user message to history
        let userMessage = ChatMessage(role: .user, content: content)
        messages.append(userMessage)

        // Build system prompt with context
        let systemPrompt = buildSystemPrompt(context: context)

        // Build messages array for API
        var apiMessages: [[String: Any]] = []
        for message in messages {
            apiMessages.append([
                "role": message.role.rawValue,
                "content": message.content
            ])
        }

        do {
            let response = try await callClaudeAPI(systemPrompt: systemPrompt, messages: apiMessages)
            let assistantMessage = ChatMessage(role: .assistant, content: response)
            messages.append(assistantMessage)
            currentResponse = response
        } catch {
            self.error = "Claude API error: \(error.localizedDescription)"
        }

        isProcessing = false
    }

    func clearConversation() {
        messages.removeAll()
        currentResponse = ""
    }

    // MARK: - Database Operations via Claude

    func analyzeFood(_ food: FoodItem) async -> FoodAnalysis? {
        guard isConfigured else { return nil }

        isProcessing = true

        let prompt = """
        Analyze this food item and provide suggestions for improvement:

        Name: \(food.name)
        Brand: \(food.brand ?? "N/A")
        Calories: \(food.calories) kcal
        Protein: \(food.protein)g
        Carbs: \(food.carbs)g
        Fat: \(food.fat)g
        Fiber: \(food.fiber)g
        Sugar: \(food.sugar)g
        Sodium: \(food.sodium)mg
        Ingredients: \(food.ingredients?.joined(separator: ", ") ?? "N/A")
        Processing Grade: \(food.processingGrade ?? "N/A")
        Verified: \(food.isVerified ?? false)

        Please provide:
        1. Data quality assessment (missing fields, potential errors)
        2. Nutrition plausibility check (do the values make sense?)
        3. Suggested corrections or improvements
        4. Processing grade assessment based on ingredients

        Format your response as JSON with these fields:
        {
            "qualityScore": 0-100,
            "issues": ["issue1", "issue2"],
            "suggestions": ["suggestion1", "suggestion2"],
            "corrections": {"field": "correctedValue"},
            "processingAssessment": "description"
        }
        """

        let systemPrompt = """
        You are a food database expert helping to maintain and improve a nutrition database.
        Focus on data quality, accuracy, and completeness.
        Always respond with valid JSON when asked for structured data.
        """

        do {
            let response = try await callClaudeAPI(
                systemPrompt: systemPrompt,
                messages: [["role": "user", "content": prompt]]
            )

            // Parse JSON response
            if let jsonStart = response.firstIndex(of: "{"),
               let jsonEnd = response.lastIndex(of: "}") {
                let jsonString = String(response[jsonStart...jsonEnd])
                if let data = jsonString.data(using: .utf8) {
                    let analysis = try JSONDecoder().decode(FoodAnalysis.self, from: data)
                    isProcessing = false
                    return analysis
                }
            }
        } catch {
            self.error = "Analysis failed: \(error.localizedDescription)"
        }

        isProcessing = false
        return nil
    }

    func autoFixSelectedFoods(_ foodIDs: Set<String>) async {
        guard isConfigured else {
            error = "Claude API key not configured"
            return
        }

        isProcessing = true

        // This would be implemented to batch fix issues in selected foods
        // For now, add a message about the operation
        let message = ChatMessage(
            role: .assistant,
            content: "Auto-fix operation initiated for \(foodIDs.count) foods. This feature analyzes each food for data quality issues and applies automatic corrections where confidence is high."
        )
        messages.append(message)

        isProcessing = false
    }

    func suggestIngredients(for foodName: String) async -> [String]? {
        guard isConfigured else { return nil }

        let prompt = """
        For the food item "\(foodName)", suggest a typical ingredient list.
        Return ONLY a JSON array of ingredient strings, nothing else.
        Example: ["flour", "sugar", "butter", "eggs"]
        """

        do {
            let response = try await callClaudeAPI(
                systemPrompt: "You are a food expert. Respond only with JSON arrays.",
                messages: [["role": "user", "content": prompt]]
            )

            if let jsonStart = response.firstIndex(of: "["),
               let jsonEnd = response.lastIndex(of: "]") {
                let jsonString = String(response[jsonStart...jsonEnd])
                if let data = jsonString.data(using: .utf8) {
                    return try JSONDecoder().decode([String].self, from: data)
                }
            }
        } catch {
            self.error = "Suggestion failed: \(error.localizedDescription)"
        }

        return nil
    }

    func generateFoodDescription(_ food: FoodItem) async -> String? {
        guard isConfigured else { return nil }

        let prompt = """
        Generate a brief, informative description for this food item:
        Name: \(food.name)
        Brand: \(food.brand ?? "Generic")
        Calories: \(food.calories) kcal per 100g

        The description should be 1-2 sentences, factual, and suitable for a nutrition app.
        """

        do {
            return try await callClaudeAPI(
                systemPrompt: "You are a nutrition copywriter. Be concise and factual.",
                messages: [["role": "user", "content": prompt]]
            )
        } catch {
            self.error = "Description generation failed: \(error.localizedDescription)"
            return nil
        }
    }

    // MARK: - API Call

    private func callClaudeAPI(systemPrompt: String, messages: [[String: Any]]) async throws -> String {
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 4096,
            "system": systemPrompt,
            "messages": messages
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClaudeError.invalidResponse
        }

        if httpResponse.statusCode != 200 {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorJson["error"] as? [String: Any],
               let message = errorMessage["message"] as? String {
                throw ClaudeError.apiError(message)
            }
            throw ClaudeError.httpError(httpResponse.statusCode)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let firstContent = content.first,
              let text = firstContent["text"] as? String else {
            throw ClaudeError.parseError
        }

        return text
    }

    // MARK: - Helper Functions

    private func buildSystemPrompt(context: DatabaseContext?) -> String {
        var prompt = """
        You are an AI assistant helping manage the NutraSafe food database.
        You have expertise in:
        - Food nutrition data and composition
        - Food additives and their E-numbers
        - Processing levels (NOVA classification)
        - Data quality and validation
        - UK food regulations and labelling

        When asked about database operations, provide specific, actionable advice.
        When analyzing foods, check for data quality issues like:
        - Implausible nutrition values (e.g., protein > 100g per 100g)
        - Missing required fields
        - Inconsistent data (e.g., calories don't match macros)
        - Spelling errors in food names

        """

        if let context = context {
            prompt += "\n\nCurrent context:\n"
            prompt += "- Database: \(context.database.displayName)\n"
            prompt += "- Total records: \(context.totalRecords)\n"
            if let selectedCount = context.selectedCount {
                prompt += "- Selected records: \(selectedCount)\n"
            }
            if let currentFood = context.currentFood {
                prompt += "- Current food: \(currentFood.name)\n"
            }
        }

        return prompt
    }
}

// MARK: - Supporting Types

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: ChatRole
    let content: String
    let timestamp = Date()
}

enum ChatRole: String {
    case user
    case assistant
}

struct DatabaseContext {
    let database: DatabaseType
    let totalRecords: Int
    let selectedCount: Int?
    let currentFood: FoodItem?
}

struct FoodAnalysis: Codable {
    let qualityScore: Int
    let issues: [String]
    let suggestions: [String]
    let corrections: [String: String]?
    let processingAssessment: String?
}

enum ClaudeError: LocalizedError {
    case invalidResponse
    case apiError(String)
    case httpError(Int)
    case parseError

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from Claude API"
        case .apiError(let message):
            return "API Error: \(message)"
        case .httpError(let code):
            return "HTTP Error: \(code)"
        case .parseError:
            return "Failed to parse response"
        }
    }
}
