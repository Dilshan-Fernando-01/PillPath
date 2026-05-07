//
//  MedicalEventEntity+CoreDataProperties.swift
//  PillPath
//

import Foundation
import CoreData

extension MedicalEventEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MedicalEventEntity> {
        NSFetchRequest<MedicalEventEntity>(entityName: "MedicalEventEntity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var eventDescription: String?
    @NSManaged public var date: Date?
    @NSManaged public var type: String?
    @NSManaged public var createdAt: Date?
}

extension MedicalEventEntity: Identifiable {}
