//
//  HealthKitModels.swift
//  NutraSafe Beta
//
//  Domain models for HealthKit
//

import Foundation
import SwiftUI
import FirebaseFirestore

struct FridgeItem {
    let id: UUID
    let userId: String
    let name: String
    let quantity: Int
    let unit: String
    let expiryDate: Date?
    let category: String
    let notes: String?
    let dateAdded: Date
    
    init(userId: String, name: String, quantity: Int, unit: String, 
         expiryDate: Date? = nil, category: String = "Other", notes: String? = nil) {
        self.id = UUID()
        self.userId = userId
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.expiryDate = expiryDate
        self.category = category
        self.notes = notes
        self.dateAdded = Date()
    }
    
    init(id: UUID, userId: String, name: String, quantity: Int, unit: String,
         expiryDate: Date?, category: String, notes: String?, dateAdded: Date) {
        self.id = id
        self.userId = userId
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.expiryDate = expiryDate
        self.category = category
        self.notes = notes
        self.dateAdded = dateAdded
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id.uuidString,
            "userId": userId,
            "name": name,
            "quantity": quantity,
            "unit": unit,
            "expiryDate": expiryDate != nil ? Timestamp(date: expiryDate!) : NSNull(),
            "category": category,
            "notes": notes ?? "",
            "dateAdded": Timestamp(date: dateAdded)
        ]
    }
    
    static func fromDictionary(_ data: [String: Any]) -> FridgeItem? {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let userId = data["userId"] as? String,
              let name = data["name"] as? String,
              let quantity = data["quantity"] as? Int,
              let unit = data["unit"] as? String,
              let category = data["category"] as? String,
              let dateAddedTimestamp = data["dateAdded"] as? Timestamp else {
            return nil
        }
        
        let notes = data["notes"] as? String
        let expiryDate = (data["expiryDate"] as? Timestamp)?.dateValue()
        
        return FridgeItem(
            id: id,
            userId: userId,
            name: name,
            quantity: quantity,
            unit: unit,
            expiryDate: expiryDate,
            category: category,
            notes: notes,
            dateAdded: dateAddedTimestamp.dateValue()
        )
    }
}

