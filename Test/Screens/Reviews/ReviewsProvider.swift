import Foundation

/// Класс для загрузки отзывов.
final class ReviewsProvider {

    private let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }
}

// MARK: - Internal API
extension ReviewsProvider {

    typealias GetReviewsResult = Result<Data, GetReviewsError>

    enum GetReviewsError: Error {
        case badURL
        case badData(Error)
    }

    /// «Запрос» отзывов. Теперь выполняется асинхронно.
    func getReviews(offset: Int = 0, completion: @escaping (GetReviewsResult) -> Void) {

        DispatchQueue.global(qos: .userInitiated).async { [bundle] in
            guard let url = bundle.url(forResource: "getReviews.response", withExtension: "json") else {
                return DispatchQueue.main.async { completion(.failure(.badURL)) }
            }

            usleep(.random(in: 100_000...1_000_000))

            do {
                let data = try Data(contentsOf: url)
                // ⬅️ Возвращаем результат НА ГЛАВНЫЙ ПОТОК
                DispatchQueue.main.async { completion(.success(data)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(.badData(error))) }
            }
        }
    }
}
