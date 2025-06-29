import Foundation

/// Модель отзыва.
struct Review: Decodable {

    /// Имя и фамилия пользователя.
    let first_name: String
    let last_name: String

    /// Оценка 1…5.
    let rating: Int

    /// Текст отзыва.
    let text: String
    /// Время создания отзыва.
    let created: String
}
