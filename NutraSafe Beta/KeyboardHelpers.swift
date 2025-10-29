//
//  KeyboardHelpers.swift
//  NutraSafe Beta
//
//  Created on 2025-10-28.
//  Universal keyboard handling utilities for consistent UX across the app
//

import SwiftUI

// MARK: - Global Keyboard Dismissal Function
extension View {
    /// Dismisses the keyboard programmatically
    func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Tap to Dismiss Keyboard
extension View {
    /// Adds a tap gesture to dismiss keyboard when tapping on empty space
    /// Apply this to root views for global tap-to-dismiss behavior
    func dismissKeyboardOnTap() -> some View {
        self.onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}

// MARK: - Keyboard Toolbar for Number/Decimal Pads
extension View {
    /// Adds a "Close" button on the left and "Done" button on the right above the keyboard
    /// Use this on TextFields with .keyboardType(.decimalPad) or .keyboardType(.numberPad)
    func keyboardDismissToolbar() -> some View {
        self.toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Button("Close") {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .font(.body)

                Spacer()

                Button("Done") {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .font(.body)
                .fontWeight(.semibold)
            }
        }
    }
}

// MARK: - Standard TextField Modifiers
extension View {
    /// Applies standard keyboard handling to TextFields:
    /// - Shows "Done" button on keyboard
    /// - Dismisses keyboard when return/done is pressed
    /// - Works with all keyboard types
    func standardKeyboardBehavior() -> some View {
        self
            .submitLabel(.done)
            .onSubmit {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
    }

    /// Applies standard keyboard handling for search fields:
    /// - Shows "Search" button on keyboard
    /// - Executes the provided search action when return is pressed
    func searchKeyboardBehavior(onSearch: @escaping () -> Void) -> some View {
        self
            .submitLabel(.search)
            .onSubmit {
                onSearch()
            }
    }
}

// MARK: - Scroll Dismiss Modifier (iOS 16+)
extension View {
    /// Enables keyboard dismissal when scrolling
    /// Apply this to ScrollViews and Lists containing text input fields
    func dismissKeyboardOnScroll() -> some View {
        if #available(iOS 16.0, *) {
            return AnyView(self.scrollDismissesKeyboard(.interactively))
        } else {
            return AnyView(self)
        }
    }
}
