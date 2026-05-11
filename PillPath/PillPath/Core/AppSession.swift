
import Foundation

final class AppSession {
    static let shared = AppSession()
    private init() {}
    var currentUserId: String = ""
}
