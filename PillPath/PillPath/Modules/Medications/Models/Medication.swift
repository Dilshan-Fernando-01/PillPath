//
//  Medication.swift
//  PillPath — Medications Module
//
//  Pure Swift domain model — no CoreData imports here.
//  Updated to match the 8-step Add Medication flow.
//

import Foundation

// MARK: - MedicationStatusChange

struct MedicationStatusChange: Codable, Hashable {
    var isActive: Bool          // false = stopped, true = resumed
    var effectiveDate: Date     // when the change takes effect
    var reason: String          // user-supplied reason

    var formattedDate: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: effectiveDate)
    }
}

// MARK: - Medication

struct Medication: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var genericName: String?
    var displayName: String?            // User-set label e.g. "Red pill for heart"
    var form: MedicationForm
    var dosageAmount: Double            // Numeric quantity (1, 0.5, 2…)
    var dosageUnit: DosageUnit          // pills / mg / ml
    var instructions: String?
    var notes: String?
    var photoURL: String?
    var currentQuantity: Int
    var lowQuantityAlert: Bool
    var lowQuantityThreshold: Int
    var isActive: Bool
    var addedAt: Date
    var sideEffects: [String]
    var interactions: [String]
    var statusChange: MedicationStatusChange?   // most recent stop/resume record

    init(
        id: UUID = .init(),
        name: String,
        genericName: String? = nil,
        displayName: String? = nil,
        form: MedicationForm = .tablet,
        dosageAmount: Double = 1.0,
        dosageUnit: DosageUnit = .pills,
        instructions: String? = nil,
        notes: String? = nil,
        photoURL: String? = nil,
        currentQuantity: Int = 0,
        lowQuantityAlert: Bool = false,
        lowQuantityThreshold: Int = 5,
        isActive: Bool = true,
        addedAt: Date = .now,
        sideEffects: [String] = [],
        interactions: [String] = [],
        statusChange: MedicationStatusChange? = nil
    ) {
        self.id = id
        self.name = name
        self.genericName = genericName
        self.displayName = displayName
        self.form = form
        self.dosageAmount = dosageAmount
        self.dosageUnit = dosageUnit
        self.instructions = instructions
        self.notes = notes
        self.photoURL = photoURL
        self.currentQuantity = currentQuantity
        self.lowQuantityAlert = lowQuantityAlert
        self.lowQuantityThreshold = lowQuantityThreshold
        self.isActive = isActive
        self.addedAt = addedAt
        self.sideEffects = sideEffects
        self.interactions = interactions
        self.statusChange = statusChange
    }

    /// Formatted dosage string e.g. "500mg" or "1 pill"
    var dosageDisplay: String {
        let amount = dosageAmount.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(dosageAmount))
            : String(dosageAmount)
        return "\(amount) \(dosageUnit.displayName)"
    }
}

// MARK: - Enums

enum MedicationForm: String, Codable, CaseIterable, Identifiable {
    case tablet    = "tablet"
    case capsule   = "capsule"
    case liquid    = "liquid"
    case injection = "injection"
    case patch     = "patch"
    case inhaler   = "inhaler"
    case other     = "other"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .tablet:    return "Tablet"
        case .capsule:   return "Capsule"
        case .liquid:    return "Liquid"
        case .injection: return "Injection"
        case .patch:     return "Patch"
        case .inhaler:   return "Inhaler"
        case .other:     return "Other"
        }
    }

    var systemIcon: String {
        switch self {
        case .tablet:    return "pills"
        case .capsule:   return "capsule"
        case .liquid:    return "drop"
        case .injection: return "syringe"
        case .patch:     return "bandage"
        case .inhaler:   return "wind"
        case .other:     return "cross.case"
        }
    }
}

enum DosageUnit: String, Codable, CaseIterable, Identifiable {
    case pills = "pills"
    case mg    = "mg"
    case ml    = "ml"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .pills: return "pills"
        case .mg:    return "mg"
        case .ml:    return "ml"
        }
    }
}
