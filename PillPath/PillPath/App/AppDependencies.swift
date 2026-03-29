//
//  AppDependencies.swift
//  PillPath
//
//  Single place to register all services into the DI container.
//  Call AppDependencies.register() once from PillPathApp.init().
//

import Foundation

struct AppDependencies {

    static func register() {
        let c = DIContainer.shared

        // ── Storage ──────────────────────────────────────────
        c.registerSingleton(CoreDataStack.self)       { CoreDataStack.shared }

        // ── Network ──────────────────────────────────────────
        c.registerSingleton(NetworkClientProtocol.self) { NetworkClient.shared }

        // ── Notifications ────────────────────────────────────
        c.registerSingleton(NotificationServiceProtocol.self) { NotificationService() }

        // ── Medications ───────────────────────────────────────
        c.registerSingleton(MedicationServiceProtocol.self) {
            MedicationService(
                coreData: c.resolve(CoreDataStack.self),
                network:  c.resolve(NetworkClientProtocol.self)
            )
        }
        c.registerSingleton(FDAServiceProtocol.self) {
            FDAService(network: c.resolve(NetworkClientProtocol.self))
        }

        // ── Scheduling ────────────────────────────────────────
        c.registerSingleton(ScheduleServiceProtocol.self) {
            ScheduleService(
                coreData:            c.resolve(CoreDataStack.self),
                notificationService: c.resolve(NotificationServiceProtocol.self)
            )
        }
        c.registerSingleton(DoseTrackingServiceProtocol.self) {
            DoseTrackingService(coreData: c.resolve(CoreDataStack.self))
        }
        c.registerSingleton(EventServiceProtocol.self) {
            EventService(coreData: c.resolve(CoreDataStack.self))
        }

        // ── Analytics ─────────────────────────────────────────
        c.registerSingleton(AnalyticsServiceProtocol.self) {
            AnalyticsService(coreData: c.resolve(CoreDataStack.self))
        }

        // ── Auth ──────────────────────────────────────────────
        c.registerSingleton(AuthServiceProtocol.self)       { AuthService() }
        c.registerSingleton(BiometricAuthServiceProtocol.self) { BiometricAuthService() }
        c.registerSingleton(GoogleSSOServiceProtocol.self)   { GoogleSSOService() }

        // ── OCR / Prescription Import ──────────────────────────
        c.registerSingleton(OCRServiceProtocol.self) { OCRService() }
        c.registerSingleton(MedicationExtractionServiceProtocol.self) { MedicationExtractionService() }
        c.registerSingleton(PrescriptionValidationServiceProtocol.self) {
            PrescriptionValidationService(fdaService: c.resolve(FDAServiceProtocol.self))
        }
        c.registerSingleton(BulkImportServiceProtocol.self) {
            BulkImportService(
                medicationService:   c.resolve(MedicationServiceProtocol.self),
                scheduleService:     c.resolve(ScheduleServiceProtocol.self),
                doseTrackingService: c.resolve(DoseTrackingServiceProtocol.self)
            )
        }
    }
}
