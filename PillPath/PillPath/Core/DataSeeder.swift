

import Foundation

struct DataSeeder {

    private static let seededKey = "pp_sample_data_seeded_v4"

    static func seedIfNeeded() {
        UserDefaults.standard.set(true, forKey: seededKey)
    }
}
