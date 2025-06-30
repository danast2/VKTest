import UIKit

final class ReviewsViewController: UIViewController {

    private lazy var reviewsView = makeReviewsView()
    private let viewModel: ReviewsViewModel
    private let loader = LoadingIndicatorView(frame: CGRect(origin: .zero,
                                                                size: CGSize(width: 40, height: 40)))

    init(viewModel: ReviewsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = reviewsView
        title = "Отзывы"
        view.addAndCenter(loader)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewModel()
        loader.start()
        viewModel.getReviews()
        reviewsView.refreshControl.addTarget(
            self,
            action: #selector(didPullToRefresh),
            for: .valueChanged
        )
    }

    @objc private func didPullToRefresh() {
        viewModel.reloadFromScratch()
    }

}

// MARK: - Private

private extension ReviewsViewController {

    func makeReviewsView() -> ReviewsView {
        let reviewsView = ReviewsView()
        reviewsView.tableView.delegate = viewModel
        reviewsView.tableView.dataSource = viewModel
        return reviewsView
    }

    func setupViewModel() {
        viewModel.onStateChange = { [weak self] _ in
            guard let self else { return }
            self.reviewsView.tableView.reloadData()

            if !self.loader.isHidden, !self.viewModel.state.items.isEmpty {
                self.loader.stop()
            }
            if self.reviewsView.refreshControl.isRefreshing {
                self.reviewsView.refreshControl.endRefreshing()
            }
        }
    }

}
