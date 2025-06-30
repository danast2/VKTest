import Foundation

/// Модель отзыва (JSON).
struct Review: Decodable {

    let first_name: String
    let last_name:  String
    let rating:     Int
    let text:       String
    let created:    String
    let avatar_url: URL?
    let photo_urls: [URL]?

}
