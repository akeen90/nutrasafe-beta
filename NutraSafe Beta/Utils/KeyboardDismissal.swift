//
//  KeyboardDismissal.swift
//  NutraSafe Beta
//
//  Universal keyboard dismissal utility for tap-to-dismiss functionality
//  Applies to all views with text input fields
//

import SwiftUI

// MARK: - Keyboard Dismissal View Modifier

struct KeyboardDismissModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onTapGesture {
                // Dismiss keyboard when tapping outside text fields
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil,
                    from: nil,
                    for: nil
                )
            }
    }
}

// MARK: - View Extension

extension View {
    /// Adds tap-to-dismiss keyboard functionality to any view
    /// Apply to ScrollView or main container with text input fields
    func hideKeyboard() -> some View {
        self.modifier(KeyboardDismissModifier())
    }
}
