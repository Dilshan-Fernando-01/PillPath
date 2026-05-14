
import Foundation

enum DocumentStorage {

    private static var attachmentsURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let folder = docs.appendingPathComponent("event_attachments", isDirectory: true)
        if !FileManager.default.fileExists(atPath: folder.path) {
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        return folder
    }

    static func save(from sourceURL: URL) -> String? {
        let originalExt = sourceURL.pathExtension
        let filename = "event_doc_\(UUID().uuidString).\(originalExt.isEmpty ? "dat" : originalExt)"
        let destination = attachmentsURL.appendingPathComponent(filename)

        let scoped = sourceURL.startAccessingSecurityScopedResource()
        defer { if scoped { sourceURL.stopAccessingSecurityScopedResource() } }

        do {
            let data = try Data(contentsOf: sourceURL)
            try data.write(to: destination)
            return filename
        } catch {
            return nil
        }
    }

    static func url(for reference: String?) -> URL? {
        guard let reference, !reference.isEmpty else { return nil }
        let filename = (reference as NSString).lastPathComponent
        let url = attachmentsURL.appendingPathComponent(filename)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    static func delete(_ reference: String?) {
        guard let url = url(for: reference) else { return }
        try? FileManager.default.removeItem(at: url)
    }
}
