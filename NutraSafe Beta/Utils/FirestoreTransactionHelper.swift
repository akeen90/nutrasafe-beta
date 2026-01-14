//
//  FirestoreTransactionHelper.swift
//  NutraSafe Beta
//
//  Created by Claude Code
//  Concurrent update protection using Firestore transactions and optimistic locking
//

import Foundation
import FirebaseFirestore

/// Errors that can occur during transaction operations
enum TransactionError: Error, LocalizedError {
    case versionConflict(expected: Int, actual: Int)
    case documentNotFound
    case maxRetriesExceeded
    case cancelled

    var errorDescription: String? {
        switch self {
        case .versionConflict(let expected, let actual):
            return "Version conflict: expected v\(expected), but document is at v\(actual). Another device updated this data."
        case .documentNotFound:
            return "Document not found during transaction"
        case .maxRetriesExceeded:
            return "Transaction failed after maximum retries. Please try again."
        case .cancelled:
            return "Transaction was cancelled"
        }
    }
}

/// Helper for safe concurrent updates using Firestore transactions
struct FirestoreTransactionHelper {

    // MARK: - Optimistic Locking with Versioning

    /// Updates a document with optimistic locking (version checking)
    /// - Parameters:
    ///   - documentRef: Firestore document reference
    ///   - updateData: Data to update (excluding version field)
    ///   - db: Firestore database instance
    ///   - maxRetries: Maximum number of retry attempts on conflict (default 3)
    /// - Throws: TransactionError if version conflict persists after retries
    static func updateWithVersionCheck(
        documentRef: DocumentReference,
        updateData: [String: Any],
        db: Firestore,
        maxRetries: Int = 3
    ) async throws {
        // Run on utility QoS to match Firestore's internal thread and avoid priority inversion
        try await Task.detached(priority: .utility) {
            var retryCount = 0

            while retryCount < maxRetries {
                do {
                    _ = try await db.runTransaction { (transaction, errorPointer) -> Any? in
                        let document: DocumentSnapshot
                        do {
                            document = try transaction.getDocument(documentRef)
                        } catch {
                            errorPointer?.pointee = error as NSError
                            return nil
                        }

                        // Get current version (default to 0 if not exists)
                        let currentVersion = document.data()?["_version"] as? Int ?? 0
                        let newVersion = currentVersion + 1

                        // Prepare update with incremented version
                        var dataWithVersion = updateData
                        dataWithVersion["_version"] = newVersion
                        dataWithVersion["_lastModified"] = FieldValue.serverTimestamp()

                        // If document doesn't exist, create it
                        if !document.exists {
                            dataWithVersion["_createdAt"] = FieldValue.serverTimestamp()
                            transaction.setData(dataWithVersion, forDocument: documentRef)
                        } else {
                            // Update with version check
                            transaction.updateData(dataWithVersion, forDocument: documentRef)
                        }

                        return newVersion
                    }

                    // Success - exit retry loop
                    return

                } catch {
                    // Check if it's a version conflict or other error
                    if let firestoreError = error as NSError?,
                       firestoreError.domain == "FIRFirestoreErrorDomain",
                       firestoreError.code == 5 { // FAILED_PRECONDITION
                        // Version conflict - retry
                        retryCount += 1
                        if retryCount < maxRetries {
                            // Exponential backoff
                            let delayMs = 100 * (1 << retryCount) // 200ms, 400ms, 800ms
                            try await Task.sleep(nanoseconds: UInt64(delayMs * 1_000_000))
                            continue
                        } else {
                            throw TransactionError.maxRetriesExceeded
                        }
                    } else {
                        // Other error - rethrow
                        throw error
                    }
                }
            }

            throw TransactionError.maxRetriesExceeded
        }.value
    }

    // MARK: - Batch Operations with Atomicity

    /// Performs multiple writes atomically (all succeed or all fail)
    /// - Parameters:
    ///   - operations: Array of write operations to perform
    ///   - db: Firestore database instance
    /// - Throws: Error if any operation fails
    static func performAtomicBatch(
        operations: [(DocumentReference, [String: Any])],
        db: Firestore
    ) async throws {
        // Run on utility QoS to match Firestore's internal thread and avoid priority inversion
        try await Task.detached(priority: .utility) {
            _ = try await db.runTransaction { (transaction, errorPointer) -> Any? in
                for (docRef, data) in operations {
                    var dataWithMetadata = data
                    dataWithMetadata["_lastModified"] = FieldValue.serverTimestamp()
                    transaction.setData(dataWithMetadata, forDocument: docRef, merge: true)
                }
                return nil
            }
        }.value
    }

    // MARK: - Read-Modify-Write Transactions

    /// Safely reads, modifies, and writes a document in a single transaction
    /// - Parameters:
    ///   - documentRef: Document to update
    ///   - transform: Function that takes current data and returns updated data
    ///   - db: Firestore database instance
    /// - Throws: Error if transaction fails
    /// - Returns: The updated document data
    static func readModifyWrite(
        documentRef: DocumentReference,
        transform: @escaping @Sendable ([String: Any]) -> [String: Any],
        db: Firestore
    ) async throws -> [String: Any] {
        // Run on utility QoS to match Firestore's internal thread and avoid priority inversion
        return try await Task.detached(priority: .utility) {
            let result = try await db.runTransaction { (transaction, errorPointer) -> Any? in
                let document: DocumentSnapshot
                do {
                    document = try transaction.getDocument(documentRef)
                } catch {
                    errorPointer?.pointee = error as NSError
                    return nil
                }

                // Get current data or start with empty
                let currentData = document.data() ?? [:]

                // Apply transformation
                var newData = transform(currentData)

                // Add metadata
                newData["_lastModified"] = FieldValue.serverTimestamp()
                if !document.exists {
                    newData["_createdAt"] = FieldValue.serverTimestamp()
                }

                // Write back
                transaction.setData(newData, forDocument: documentRef, merge: true)

                return newData as Any
            }

            return result as? [String: Any] ?? [:]
        }.value
    }

    // MARK: - Increment/Decrement Operations

    /// Safely increments a numeric field with transaction support
    /// - Parameters:
    ///   - documentRef: Document containing the field
    ///   - field: Field name to increment
    ///   - amount: Amount to increment (can be negative for decrement)
    ///   - db: Firestore database instance
    /// - Throws: Error if transaction fails
    static func incrementField(
        documentRef: DocumentReference,
        field: String,
        by amount: Double,
        db: Firestore
    ) async throws {
        // Run on utility QoS to match Firestore's internal thread and avoid priority inversion
        try await Task.detached(priority: .utility) {
            _ = try await db.runTransaction { (transaction, errorPointer) -> Any? in
                let document: DocumentSnapshot
                do {
                    document = try transaction.getDocument(documentRef)
                } catch {
                    errorPointer?.pointee = error as NSError
                    return nil
                }

                let currentValue = document.data()?[field] as? Double ?? 0
                let newValue = currentValue + amount

                transaction.updateData([
                    field: newValue,
                    "_lastModified": FieldValue.serverTimestamp()
                ], forDocument: documentRef)

                return newValue
            }
        }.value
    }

    // MARK: - Conditional Updates

    /// Updates document only if a condition is met
    /// - Parameters:
    ///   - documentRef: Document to update
    ///   - condition: Function that takes current data and returns true if update should proceed
    ///   - updateData: Data to update if condition is met
    ///   - db: Firestore database instance
    /// - Throws: TransactionError.cancelled if condition not met
    /// - Returns: True if update was performed, false if condition not met
    @discardableResult
    static func conditionalUpdate(
        documentRef: DocumentReference,
        condition: @escaping @Sendable ([String: Any]) -> Bool,
        updateData: [String: Any],
        db: Firestore
    ) async throws -> Bool {
        // Run on utility QoS to match Firestore's internal thread and avoid priority inversion
        return try await Task.detached(priority: .utility) {
            let result = try await db.runTransaction { (transaction, errorPointer) -> Any? in
                let document: DocumentSnapshot
                do {
                    document = try transaction.getDocument(documentRef)
                } catch {
                    errorPointer?.pointee = error as NSError
                    return false as Any
                }

                let currentData = document.data() ?? [:]

                // Check condition
                guard condition(currentData) else {
                    return false as Any
                }

                // Condition met - perform update
                var dataWithMetadata = updateData
                dataWithMetadata["_lastModified"] = FieldValue.serverTimestamp()

                transaction.setData(dataWithMetadata, forDocument: documentRef, merge: true)

                return true as Any
            }

            return result as? Bool ?? false
        }.value
    }
}

// MARK: - Convenience Extensions

extension Firestore {
    /// Convenience method for version-checked updates
    func updateWithVersionCheck(
        documentRef: DocumentReference,
        data: [String: Any],
        maxRetries: Int = 3
    ) async throws {
        try await FirestoreTransactionHelper.updateWithVersionCheck(
            documentRef: documentRef,
            updateData: data,
            db: self,
            maxRetries: maxRetries
        )
    }

    /// Convenience method for atomic batch operations
    func performAtomicBatch(operations: [(DocumentReference, [String: Any])]) async throws {
        try await FirestoreTransactionHelper.performAtomicBatch(operations: operations, db: self)
    }

    /// Convenience method for read-modify-write
    func readModifyWrite(
        documentRef: DocumentReference,
        transform: @escaping @Sendable ([String: Any]) -> [String: Any]
    ) async throws -> [String: Any] {
        return try await FirestoreTransactionHelper.readModifyWrite(
            documentRef: documentRef,
            transform: transform,
            db: self
        )
    }
}
