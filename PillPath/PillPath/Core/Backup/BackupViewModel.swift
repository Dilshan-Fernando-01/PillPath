
import Foundation
import Combine

enum BackupViewState: Equatable {
    case idle
    case loading
    case success(String)
    case failure(String)
}

@MainActor
final class BackupViewModel: ObservableObject {

    @Published var state: BackupViewState = .idle
    @Published var lastBackupDate: Date?
    @Published var cloudBackupDate: Date?
    @Published var showRestoreConfirm = false
    @Published var showRestorePrompt = false
    @Published var errorMessage: String?

    private let service: BackupServiceProtocol

    init(service: BackupServiceProtocol = BackupService()) {
        self.service = service
        self.lastBackupDate = service.lastBackupDate()
    }

    func backup() async {
        state = .loading
        do {
            let date = try await service.backup()
            lastBackupDate = date
            state = .success("Backup saved \(date.formatted(.dateTime.day().month().year().hour().minute()))")
        } catch {
            state = .failure(error.localizedDescription)
        }
    }

    func restore() async {
        state = .loading
        do {
            try await service.restore()
            NotificationCenter.default.post(name: .dataRestored, object: nil)
            state = .success("Data restored successfully")
        } catch {
            state = .failure(error.localizedDescription)
        }
    }

    func checkCloudBackup() async {
        cloudBackupDate = try? await service.checkForBackup()
    }

    func autoBackupIfNeeded() async {
        guard let svc = service as? BackupService else { return }
        await svc.autoBackupIfNeeded()
        lastBackupDate = service.lastBackupDate()
    }

    func checkRestorePromptNeeded() async {
        let localCount = service.localMedicationCount()
        guard localCount == 0 else { return }
        let hasCloud = (try? await service.checkForBackup()) != nil
        if hasCloud { showRestorePrompt = true }
    }

    func dismissState() {
        if case .success = state { state = .idle }
        if case .failure = state { state = .idle }
    }
}
