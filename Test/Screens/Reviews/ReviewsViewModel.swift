import UIKit

/// Класс, описывающий бизнес-логику экрана отзывов.
final class ReviewsViewModel: NSObject {

    typealias State = ReviewsViewModelState
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
        self.state           = state
        self.reviewsProvider = reviewsProvider
        self.ratingRenderer  = ratingRenderer
        self.decoder         = decoder
    }
}

// MARK: - Public API
extension ReviewsViewModel {

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
        /// Плейсхолдер-аватар (имя ассета из .xcassets).
        static let avatar: UIImage =
            UIImage(named: "l5w5aIHioYc") ??
            UIImage(systemName: "person.crop.square")!
    }

    private func gotReviews(_ result: ReviewsProvider.GetReviewsResult) {
        defer { onStateChange?(state) }

        guard
            case let .success(data) = result,
            let response = try? decoder.decode(Reviews.self, from: data)
        else {
            state.shouldLoad = true
            return
        }

        // -------- пагинация, как раньше --------
        let total = response.items.count
        let start = state.offset
        let end   = min(start + state.limit, total)
        guard start < end else {
            state.shouldLoad = false
            return
        }

        state.items += response.items[start..<end].map(makeReviewItem)
        state.offset     = end
        state.shouldLoad = end < total

        // -------- count-item --------
        if !state.shouldLoad {                    // дошли до конца списка
            // 1. убираем старый (если перезагружали данные)
            state.items.removeAll { $0 is ReviewCountCellConfig }

            // 2. вставляем новый в самый конец
            let countText = "\(response.count) отзывов"
                .attributed(font: .reviewCount, color: .reviewCount)

            state.items.append(ReviewCountCellConfig(text: countText))
        }
    }


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

        let username = "\(review.first_name) \(review.last_name)"
            .attributed(font: .username)

        return ReviewItem(
            avatar:       Assets.avatar,
            username:     username,
            ratingImage:  ratingRenderer.ratingImage(review.rating),
            reviewText:   review.text.attributed(font: .text),
            created:      review.created.attributed(font: .created, color: .created),
            onTapShowMore: { [weak self] id in self?.showMoreReview(with: id) }
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
