//
//  DataSeeder.swift
//  PillPath
//
//  Seeds sample stopped medications and past medical events on first launch.
//  Uses a UserDefaults flag so it only runs once per install.
//  Does NOT affect user-created medications or events.
//

import Foundation

struct DataSeeder {

    private static let seededKey = "pp_sample_data_seeded_v1"

    static func seedIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: seededKey) else { return }

        let medicationService = DIContainer.shared.resolve(MedicationServiceProtocol.self)
        let eventService      = DIContainer.shared.resolve(EventServiceProtocol.self)

        seedStoppedMedications(medicationService)
        seedMedicalEvents(eventService)

        UserDefaults.standard.set(true, forKey: seededKey)
    }


    private static func seedStoppedMedications(_ service: MedicationServiceProtocol) {
        let past: (Int) -> Date = { days in
            Calendar.current.date(byAdding: .day, value: -days, to: .now) ?? .now
        }

        let stopped: [Medication] = [
            Medication(
                name: "Amoxicillin",
                genericName: "Amoxicillin Trihydrate",
                form: .capsule,
                dosageAmount: 500,
                dosageUnit: .mg,
                instructions: "Take with food",
                isActive: false,
                addedAt: past(90),
                statusChange: MedicationStatusChange(
                    isActive: false,
                    effectiveDate: past(60),
                    reason: "Antibiotic course completed"
                )
            ),
            Medication(
                name: "Ibuprofen",
                genericName: "Ibuprofen",
                form: .tablet,
                dosageAmount: 400,
                dosageUnit: .mg,
                instructions: "Take after meals to reduce stomach irritation",
                isActive: false,
                addedAt: past(45),
                statusChange: MedicationStatusChange(
                    isActive: false,
                    effectiveDate: past(30),
                    reason: "Pain resolved"
                )
            ),
            Medication(
                name: "Cetirizine",
                genericName: "Cetirizine Hydrochloride",
                form: .tablet,
                dosageAmount: 10,
                dosageUnit: .mg,
                instructions: "Take once daily at bedtime",
                isActive: false,
                addedAt: past(120),
                statusChange: MedicationStatusChange(
                    isActive: false,
                    effectiveDate: past(90),
                    reason: "Seasonal allergies cleared"
                )
            ),
        ]

        for med in stopped {
            try? service.save(med)
        }
    }



    private static func seedMedicalEvents(_ service: EventServiceProtocol) {
        let past: (Int) -> Date = { days in
            Calendar.current.date(byAdding: .day, value: -days, to: .now) ?? .now
        }
        let future: (Int) -> Date = { days in
            Calendar.current.date(byAdding: .day, value: days, to: .now) ?? .now
        }

        let events: [MedicalEvent] = [
            MedicalEvent(
                title: "Annual Physical Exam",
                notes: "Blood pressure and cholesterol checked. Results normal.",
                provider: "Dr. Sarah Perera",
                date: past(60),
                type: .doctorVisit
            ),
            MedicalEvent(
                title: "Blood Test — Full Panel",
                notes: "CBC, lipid profile, blood glucose fasting. All within normal range.",
                provider: "National Hospital Laboratory",
                date: past(45),
                type: .test
            ),
            MedicalEvent(
                title: "Started new medication",
                notes: "Discussed dosage adjustment with GP. Monitoring for side effects.",
                provider: "Dr. Rohan Silva",
                date: past(30),
                type: .note
            ),
            MedicalEvent(
                title: "Follow-up Consultation",
                notes: "Review progress and refill prescription.",
                provider: "Dr. Sarah Perera",
                date: future(14),
                type: .doctorVisit
            ),
            MedicalEvent(
                title: "Dental Check-up",
                notes: "Routine dental examination and cleaning.",
                provider: "City Dental Clinic",
                date: future(21),
                type: .other
            ),
        ]

        for event in events {
            try? service.save(event)
        }
    }
}
