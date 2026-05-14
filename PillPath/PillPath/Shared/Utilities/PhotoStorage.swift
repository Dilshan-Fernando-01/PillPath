
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

    static func url(for reference: String?) -> URL? {
        guard let reference, !reference.isEmpty else { return nil }
        let filename = (reference as NSString).lastPathComponent
        let url = documentsURL.appendingPathComponent(filename)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    static func writeData(_ data: Data, filename: String) -> String? {
        let safeFilename = (filename as NSString).lastPathComponent
        let url = documentsURL.appendingPathComponent(safeFilename)
        do {
            try data.write(to: url)
            return safeFilename
        } catch {
            return nil
        }
    }

    static func thumbnailData(from reference: String?, maxDimension: CGFloat = 512, maxBytes: Int = 700_000) -> Data? {
        guard let image = load(reference) else { return nil }
        let scale = min(maxDimension / image.size.width, maxDimension / image.size.height, 1.0)
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        var quality: CGFloat = 0.6
        while quality > 0.1 {
            if let data = resized.jpegData(compressionQuality: quality), data.count <= maxBytes {
                return data
            }
            quality -= 0.15
        }
        return nil
    }

    static func delete(_ reference: String?) {
        guard let reference, !reference.isEmpty else { return }
        let filename = (reference as NSString).lastPathComponent
        let url = documentsURL.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: url)
    }
}
