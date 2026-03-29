//
//  ScheduleTimeEntity+CoreDataProperties.swift
//  PillPath
//

import Foundation
import CoreData

extension ScheduleTimeEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ScheduleTimeEntity> {
        NSFetchRequest<ScheduleTimeEntity>(entityName: "ScheduleTimeEntity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var hour: Int32
    @NSManaged public var minute: Int32
    @NSManaged public var label: String?

    @NSManaged public var schedule: ScheduleEntity?
}

extension ScheduleTimeEntity: Identifiable {}
