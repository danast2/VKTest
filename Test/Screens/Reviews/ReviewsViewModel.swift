import UIKit

/// Класс, описывающий бизнес-логику экрана отзывов.
final class ReviewsViewModel: NSObject {

    /// Замыкание, вызываемое при изменении `state`.
    var onStateChange: ((State) -> Void)?


    private let reviewsProvider: ReviewsProvider
    private let ratingRenderer: RatingRenderer
    private let decoder: JSONDecoder


    private var state: State

    init(
        state: State = State(),
        reviewsProvider: ReviewsProvider = ReviewsProvider(),
        ratingRenderer: RatingRenderer = RatingRenderer(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.state          = state
        self.reviewsProvider = reviewsProvider
        self.ratingRenderer = ratingRenderer
        self.decoder        = decoder
    }
}

// MARK: - Internal API
extension ReviewsViewModel {

    typealias State = ReviewsViewModelState

    /// Запрашиваем отзывы.
    func getReviews() {
        guard state.shouldLoad else { return }
        state.shouldLoad = false
        reviewsProvider.getReviews(offset: state.offset, completion: gotReviews)
    }
}

// MARK: - Private helpers
private extension ReviewsViewModel {

    enum Assets {
        static let avatarPlaceholder: UIImage = {
            UIImage(named: "l5w5aIHioYc") ??
            UIImage(systemName: "person.crop.square")!
        }()
    }

    // Получили данные с «сервера»
    func gotReviews(_ result: ReviewsProvider.GetReviewsResult) {
        do {
            let data    = try result.get()
            let reviews = try decoder.decode(Reviews.self, from: data)

            state.items      += reviews.items.map(makeReviewItem)
            state.offset     += state.limit
            state.shouldLoad  = state.offset < reviews.count
        } catch {
            state.shouldLoad  = true
        }
        onStateChange?(state)
    }

    /// Раскрыть длинный текст «Показать полностью…».
    func showMoreReview(with id: UUID) {
        guard
            let index = state.items.firstIndex(where: { ($0 as? ReviewItem)?.id == id }),
            var item  = state.items[index] as? ReviewItem
        else { return }

        item.maxLines = .zero
        state.items[index] = item
        onStateChange?(state)
    }
}

// MARK: - Item factory
private extension ReviewsViewModel {

    typealias ReviewItem = ReviewCellConfig

    func makeReviewItem(_ review: Review) -> ReviewItem {

        let avatar = Assets.avatarPlaceholder

        let username = "\(review.first_name) \(review.last_name)"
            .attributed(font: .username)

        let ratingImage = ratingRenderer.ratingImage(review.rating)

        let reviewText = review.text.attributed(font: .text)
        let created    = review.created.attributed(font: .created, color: .created)

        return ReviewItem(
            avatar: avatar,
            username: username,
            ratingImage: ratingImage,
            reviewText: reviewText,
            created: created,
            onTapShowMore: showMoreReview
        )
    }
}


// MARK: - UITableViewDataSource

extension ReviewsViewModel: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        state.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let config = state.items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: config.reuseId, for: indexPath)
        config.update(cell: cell)
        return cell
    }

}

// MARK: - UITableViewDelegate

extension ReviewsViewModel: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        state.items[indexPath.row].height(with: tableView.bounds.size)
    }

    /// Метод дозапрашивает отзывы, если до конца списка отзывов осталось два с половиной экрана по высоте.
    func scrollViewWillEndDragging(
        _ scrollView: UIScrollView,
        withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>
    ) {
        if shouldLoadNextPage(scrollView: scrollView, targetOffsetY: targetContentOffset.pointee.y) {
            getReviews()
        }
    }

    private func shouldLoadNextPage(
        scrollView: UIScrollView,
        targetOffsetY: CGFloat,
        screensToLoadNextPage: Double = 2.5
    ) -> Bool {
        let viewHeight = scrollView.bounds.height
        let contentHeight = scrollView.contentSize.height
        let triggerDistance = viewHeight * screensToLoadNextPage
        let remainingDistance = contentHeight - viewHeight - targetOffsetY
        return remainingDistance <= triggerDistance
    }

}
