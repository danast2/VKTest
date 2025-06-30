import UIKit

/// Класс, описывающий бизнес-логику экрана отзывов.
final class ReviewsViewModel: NSObject {

    // MARK: - Aliases & State
    typealias State = ReviewsViewModelState
    var onStateChange: ((State) -> Void)?

    private let reviewsProvider: ReviewsProvider
    private let ratingRenderer:  RatingRenderer
    private let decoder:         JSONDecoder

    private var state: State

    // MARK: - Init
    init(
        state: State = State(),
        reviewsProvider: ReviewsProvider = ReviewsProvider(),
        ratingRenderer: RatingRenderer   = RatingRenderer(),
        decoder: JSONDecoder            = JSONDecoder()
    ) {
        self.state           = state
        self.reviewsProvider = reviewsProvider
        self.ratingRenderer  = ratingRenderer
        self.decoder         = decoder
    }
}

extension ReviewsViewModel {
/// Перезагрузка с нуля (для Pull-to-Refresh)
    func reloadFromScratch() {
        state = State()          // сбрасываем оффсет/флаги/элементы
        onStateChange?(state)    // очистить таблицу мгновенно
        getReviews()             // запрашиваем первую страницу
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

// MARK: - Private
private extension ReviewsViewModel {

    enum Assets {
        /// Плейсхолдер-аватар.
        static let avatar = UIImage(named: "l5w5aIHioYc")
                       ??  UIImage(systemName: "person.crop.square")!
    }

    // ───────────────────────────────────────────────────────────────────── gotReviews
    func gotReviews(_ result: ReviewsProvider.GetReviewsResult) {
        defer { onStateChange?(state) }

        guard
            case let .success(data) = result,
            let response = try? decoder.decode(Reviews.self, from: data)
        else {
            state.shouldLoad = true
            return
        }

        // пагинация
        let total = response.items.count
        let start = state.offset
        let end   = min(start + state.limit, total)
        guard start < end else {
            state.shouldLoad = false
            return
        }

        state.items      += response.items[start..<end].map(makeReviewItem)
        state.offset      = end
        state.shouldLoad  = end < total

        // финальная ячейка-счётчик
        if !state.shouldLoad {
            state.items.removeAll { $0 is ReviewCountCellConfig }
            let countText = "\(response.count) отзывов"
                .attributed(font: .reviewCount, color: .reviewCount)
            state.items.append(ReviewCountCellConfig(text: countText))
        }
    }

    // раскрываем текст отзыва
    func showMoreReview(with id: UUID) {
        guard
            let idx  = state.items.firstIndex(where: { ($0 as? ReviewItem)?.id == id }),
            var item = state.items[idx] as? ReviewItem
        else { return }

        item.maxLines = .zero
        state.items[idx] = item
        onStateChange?(state)
    }
}

// MARK: - Item factory
private extension ReviewsViewModel {

    typealias ReviewItem = ReviewCellConfig

    func makeReviewItem(_ review: Review) -> ReviewItem {

        let username = "\(review.first_name) \(review.last_name)"
            .attributed(font: .username)

        // картинки из Assets
        let photos = review.photo_asset_names?
            .compactMap { UIImage(named: $0) }
            .prefix(3) ?? []

        // ⚠️ порядок аргументов должен совпадать с memberwise-инициализатором
        return ReviewItem(
            avatar: Assets.avatar,
            username: username,
            ratingImage: ratingRenderer.ratingImage(review.rating),
            reviewText: review.text.attributed(font: .text),
            /* maxLines omitted → default 3 */
            created: review.created.attributed(font: .created, color: .created),
            photos: Array(photos),
            onTapShowMore: { [weak self] id in self?.showMoreReview(with: id) }
        )
    }
}

// MARK: - UITableViewDataSource
extension ReviewsViewModel: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        state.items.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cfg  = state.items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: cfg.reuseId, for: indexPath)
        cfg.update(cell: cell)
        return cell
    }
}

// MARK: - UITableViewDelegate
extension ReviewsViewModel: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        state.items[indexPath.row].height(with: tableView.bounds.size)
    }

    func scrollViewWillEndDragging(
        _ scrollView: UIScrollView,
        withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>
    ) {
        if shouldLoadNextPage(
            scrollView: scrollView,
            targetOffsetY: targetContentOffset.pointee.y
        ) {
            getReviews()
        }
    }

    private func shouldLoadNextPage(
        scrollView: UIScrollView,
        targetOffsetY: CGFloat,
        screensToLoadNextPage: Double = 2.5
    ) -> Bool {
        let viewH  = scrollView.bounds.height
        let contH  = scrollView.contentSize.height
        let trig   = viewH * screensToLoadNextPage
        let remain = contH - viewH - targetOffsetY
        return remain <= trig
    }
}
