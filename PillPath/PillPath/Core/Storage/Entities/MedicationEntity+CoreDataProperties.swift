//
//  MedicationEntity+CoreDataProperties.swift
//  PillPath
//

import Foundation
import CoreData

extension MedicationEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MedicationEntity> {
        NSFetchRequest<MedicationEntity>(entityName: "MedicationEntity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var genericName: String?
    @NSManaged public var displayName: String?
    @NSManaged public var form: String?
    @NSManaged public var dosageAmount: Double
    @NSManaged public var dosageUnit: String?
    @NSManaged public var instructions: String?
    @NSManaged public var notes: String?
    @NSManaged public var photoURL: String?
    @NSManaged public var currentQuantity: Int32
    @NSManaged public var lowQuantityAlert: Bool
    @NSManaged public var lowQuantityThreshold: Int32
    @NSManaged public var isActive: Bool
    @NSManaged public var addedAt: Date?
    @NSManaged public var sideEffectsJSON: String?
    @NSManaged public var interactionsJSON: String?
    @NSManaged public var statusInfoJSON: String?

    // Relationships
    @NSManaged public var schedules: NSSet?
    @NSManaged public var doseLogs: NSSet?
}

// MARK: - Relationship Accessors

extension MedicationEntity {
    @objc(addSchedulesObject:)  @NSManaged public func addToSchedules(_ value: ScheduleEntity)
    @objc(removeSchedulesObject:) @NSManaged public func removeFromSchedules(_ value: ScheduleEntity)
    @objc(addSchedules:)        @NSManaged public func addToSchedules(_ values: NSSet)
    @objc(removeSchedules:)     @NSManaged public func removeFromSchedules(_ values: NSSet)

    @objc(addDoseLogsObject:)   @NSManaged public func addToDoseLogs(_ value: DoseLogEntity)
    @objc(removeDoseLogsObject:) @NSManaged public func removeFromDoseLogs(_ value: DoseLogEntity)
    @objc(addDoseLogs:)         @NSManaged public func addToDoseLogs(_ values: NSSet)
    @objc(removeDoseLogs:)      @NSManaged public func removeFromDoseLogs(_ values: NSSet)
}

extension MedicationEntity: Identifiable {}
