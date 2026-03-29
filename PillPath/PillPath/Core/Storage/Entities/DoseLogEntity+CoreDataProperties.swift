//
//  DoseLogEntity+CoreDataProperties.swift
//  PillPath
//

import Foundation
import CoreData

extension DoseLogEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DoseLogEntity> {
        NSFetchRequest<DoseLogEntity>(entityName: "DoseLogEntity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var scheduledAt: Date?
    @NSManaged public var takenAt: Date?
    @NSManaged public var status: String?
    @NSManaged public var notes: String?

    @NSManaged public var medication: MedicationEntity?
    @NSManaged public var schedule: ScheduleEntity?
}

extension DoseLogEntity: Identifiable {}
