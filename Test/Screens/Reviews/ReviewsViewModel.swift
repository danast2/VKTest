import UIKit

// MARK: - View-model
final class ReviewsViewModel: NSObject {

    // MARK: Aliases & State
    typealias State = ReviewsViewModelState
    var onStateChange: ((State) -> Void)?

    private let reviewsProvider: ReviewsProvider
    private let ratingRenderer:  RatingRenderer
    private let decoder:         JSONDecoder

    private(set) var state: State

    // MARK: Init
    init(
        state: State = State(),
        reviewsProvider: ReviewsProvider = ReviewsProvider(),
        ratingRenderer:  RatingRenderer  = RatingRenderer(),
        decoder: JSONDecoder            = JSONDecoder()
    ) {
        self.state           = state
        self.reviewsProvider = reviewsProvider
        self.ratingRenderer  = ratingRenderer
        self.decoder         = decoder
    }
}

// MARK: – Public API
extension ReviewsViewModel {

    func reloadFromScratch() {
        state = State()
        onStateChange?(state)
        getReviews()
    }

    func getReviews() {
        guard state.shouldLoad else { return }
        state.shouldLoad = false
        reviewsProvider.getReviews(offset: state.offset, completion: gotReviews)
    }
}

// MARK: – Private helpers
private extension ReviewsViewModel {

    enum Assets {
        static let avatar = UIImage(named: "l5w5aIHioYc")
                       ??  UIImage(systemName: "person.crop.square")!
    }

    func gotReviews(_ result: ReviewsProvider.GetReviewsResult) {
        defer { onStateChange?(state) }

        guard
            case let .success(data) = result,
            let response = try? decoder.decode(Reviews.self, from: data)
        else {
            state.shouldLoad = true
            return
        }

        let total = response.items.count
        let start = state.offset
        let end   = min(start + state.limit, total)
        guard start < end else {
            state.shouldLoad = false
            return
        }

        state.items     += response.items[start..<end].map(makeReviewItem)
        state.offset     = end
        state.shouldLoad = end < total

        if !state.shouldLoad {
            state.items.removeAll { $0 is ReviewCountCellConfig }
            let countText = "\(response.count) отзывов"
                .attributed(font: .reviewCount, color: .reviewCount)
            state.items.append(ReviewCountCellConfig(text: countText))
        }
    }

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

// MARK: – Item factory
private extension ReviewsViewModel {

    typealias ReviewItem = ReviewCellConfig

    func makeReviewItem(_ review: Review) -> ReviewItem {

        let username = "\(review.first_name) \(review.last_name)"
            .attributed(font: .username)

        return ReviewItem(
            avatarURL:   review.avatar_url,
            username:    username,
            ratingImage: ratingRenderer.ratingImage(review.rating),
            reviewText:  review.text.attributed(font: .text),
            maxLines:    3,  
            created:     review.created.attributed(font: .created, color: .created),
            photoURLs:   Array((review.photo_urls ?? []).prefix(5)),
            onTapShowMore: { [weak self] id in self?.showMoreReview(with: id) }
        )
    }
}

// MARK: – UITableViewDataSource / Delegate
extension ReviewsViewModel: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tv: UITableView, numberOfRowsInSection s: Int) -> Int {
        state.items.count
    }

    func tableView(
        _ tv: UITableView,
        cellForRowAt ip: IndexPath
    ) -> UITableViewCell {
        let cfg  = state.items[ip.row]
        let cell = tv.dequeueReusableCell(withIdentifier: cfg.reuseId, for: ip)
        cfg.update(cell: cell)
        return cell
    }

    func tableView(_ tv: UITableView, heightForRowAt ip: IndexPath) -> CGFloat {
        state.items[ip.row].height(with: tv.bounds.size)
    }

    func scrollViewWillEndDragging(
        _ sv: UIScrollView, withVelocity _: CGPoint,
        targetContentOffset p: UnsafeMutablePointer<CGPoint>
    ) {
        if shouldLoadNextPage(scrollView: sv, targetOffsetY: p.pointee.y) {
            getReviews()
        }
    }

    private func shouldLoadNextPage(
        scrollView: UIScrollView,
        targetOffsetY: CGFloat,
        screensToLoadNextPage: Double = 2.5
    ) -> Bool {
        let remain = scrollView.contentSize.height
                  - scrollView.bounds.height
                  - targetOffsetY
        return remain <= scrollView.bounds.height * screensToLoadNextPage
    }
}
