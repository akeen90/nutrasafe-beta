import Foundation

final class GradeCache {
    static let processing: NSCache<NSString, NSString> = {
        let cache = NSCache<NSString, NSString>()
        cache.countLimit = 500 // Maximum 500 cached grades
        return cache
    }()

    static let sugar: NSCache<NSString, NSString> = {
        let cache = NSCache<NSString, NSString>()
        cache.countLimit = 500 // Maximum 500 cached grades
        return cache
    }()
}
