//
//  ScheduleEntity+CoreDataProperties.swift
//  PillPath
//

import Foundation
import CoreData

extension ScheduleEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ScheduleEntity> {
        NSFetchRequest<ScheduleEntity>(entityName: "ScheduleEntity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var frequency: String?
    @NSManaged public var intervalHours: Int32
    @NSManaged public var specificDaysJSON: String?
    @NSManaged public var mealTiming: String?
    @NSManaged public var startDate: Date?
    @NSManaged public var endDate: Date?
    @NSManaged public var isOngoing: Bool
    @NSManaged public var doseReminders: Bool
    @NSManaged public var notificationOffsetMinutes: Int32
    @NSManaged public var isActive: Bool

    // Relationships
    @NSManaged public var medication: MedicationEntity?
    @NSManaged public var scheduleTimes: NSSet?
    @NSManaged public var doseLogs: NSSet?
}

extension ScheduleEntity {
    @objc(addScheduleTimesObject:)  @NSManaged public func addToScheduleTimes(_ value: ScheduleTimeEntity)
    @objc(removeScheduleTimesObject:) @NSManaged public func removeFromScheduleTimes(_ value: ScheduleTimeEntity)
    @objc(addScheduleTimes:)        @NSManaged public func addToScheduleTimes(_ values: NSSet)
    @objc(removeScheduleTimes:)     @NSManaged public func removeFromScheduleTimes(_ values: NSSet)

    @objc(addDoseLogsObject:)   @NSManaged public func addToDoseLogs(_ value: DoseLogEntity)
    @objc(removeDoseLogsObject:) @NSManaged public func removeFromDoseLogs(_ value: DoseLogEntity)
    @objc(addDoseLogs:)         @NSManaged public func addToDoseLogs(_ values: NSSet)
    @objc(removeDoseLogs:)      @NSManaged public func removeFromDoseLogs(_ values: NSSet)
}

extension ScheduleEntity: Identifiable {}
