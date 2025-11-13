import Foundation

final class GradeCache {
    static let processing = NSCache<NSString, NSString>()
    static let sugar = NSCache<NSString, NSString>()
}
