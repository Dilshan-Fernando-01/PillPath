
import Foundation
import UIKit

enum PhotoStorage {

    private static var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    static func save(_ image: UIImage, quality: CGFloat = 0.8) -> String? {
        guard let data = image.jpegData(compressionQuality: quality) else { return nil }
        let filename = "med_photo_\(UUID().uuidString).jpg"
        let url = documentsURL.appendingPathComponent(filename)
        do {
            try data.write(to: url)
            return filename
        } catch {
            return nil
        }
    }

    static func load(_ reference: String?) -> UIImage? {
        guard let reference, !reference.isEmpty else { return nil }
        let filename = (reference as NSString).lastPathComponent
        let url = documentsURL.appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    static func delete(_ reference: String?) {
        guard let reference, !reference.isEmpty else { return }
        let filename = (reference as NSString).lastPathComponent
        let url = documentsURL.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: url)
    }
}
