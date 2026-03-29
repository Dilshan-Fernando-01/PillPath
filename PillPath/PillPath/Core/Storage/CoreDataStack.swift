//
//  CoreDataStack.swift
//  PillPath
//
//  Replaces the default Persistence.swift with a named, injectable stack.
//  Use CoreDataStack.shared in production; inject an in-memory stack in tests.
//

import CoreData

final class CoreDataStack {

    static let shared = CoreDataStack()

    let container: NSPersistentContainer

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "PillPath")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { _, error in
            if let error {
                // TODO: Replace with proper error handling before App Store submission.
                fatalError("CoreData load failed: \(error.localizedDescription)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    // MARK: - Save Helper

    func save() {
        let context = container.viewContext
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            // TODO: Surface this error to the user via an alert.
            print("CoreData save error: \(error.localizedDescription)")
        }
    }

    // MARK: - Background Context

    func newBackgroundContext() -> NSManagedObjectContext {
        container.newBackgroundContext()
    }
}
