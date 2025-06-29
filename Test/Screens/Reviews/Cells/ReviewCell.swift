import UIKit

/// Конфигурация ячейки. Содержит данные для отображения в ячейке.
struct ReviewCellConfig {

    // MARK: Public — данные

    /// Уникальный идентификатор конфигурации.
    let id = UUID()

    /// Аватар пользователя.
    let avatar: UIImage?
    /// Имя пользователя.
    let username: NSAttributedString
    /// Картинка рейтинга.
    let ratingImage: UIImage
    /// Текст отзыва.
    let reviewText: NSAttributedString
    /// Максимальное количество строк текста (0 — без ограничений).
    var maxLines = 3
    /// Время создания.
    let created: NSAttributedString

    /// Callback «Показать полностью…».
    let onTapShowMore: (UUID) -> Void

    // MARK: Private — layout-кэш

    fileprivate let layout = ReviewCellLayout()
}

// MARK: - TableCellConfig
extension ReviewCellConfig: TableCellConfig {

    static let reuseId = String(describing: ReviewCellConfig.self)

    func update(cell: UITableViewCell) {
        guard let cell = cell as? ReviewCell else { return }

        cell.avatarImageView.image = avatar
        cell.usernameLabel.attributedText = username
        cell.ratingImageView.image = ratingImage
        cell.reviewTextLabel.attributedText = reviewText
        cell.reviewTextLabel.numberOfLines = maxLines
        cell.createdLabel.attributedText = created

        cell.config = self
    }

    func height(with size: CGSize) -> CGFloat {
        layout.height(config: self, maxWidth: size.width)
    }
}

// MARK: - Private static
private extension ReviewCellConfig {
    static let showMoreText = "Показать полностью..."
        .attributed(font: .showMore, color: .showMore)
}


// MARK: - Cell

final class ReviewCell: UITableViewCell {

    // MARK: Subviews
    fileprivate let avatarImageView = UIImageView()
    fileprivate let usernameLabel = UILabel()
    fileprivate let ratingImageView = UIImageView()
    fileprivate let reviewTextLabel = UILabel()
    fileprivate let createdLabel = UILabel()
    fileprivate let showMoreButton = UIButton()

    // Конфигурация, чтобы тянуть layout
    fileprivate var config: Config?

    // MARK: Init
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        guard let layout = config?.layout else { return }

        avatarImageView.frame = layout.avatarFrame
        usernameLabel.frame = layout.usernameLabelFrame
        ratingImageView.frame = layout.ratingImageViewFrame
        reviewTextLabel.frame = layout.reviewTextLabelFrame
        showMoreButton.frame = layout.showMoreButtonFrame
        createdLabel.frame = layout.createdLabelFrame
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        avatarImageView.image = nil
        usernameLabel.attributedText = nil
        ratingImageView.image = nil
        reviewTextLabel.attributedText = nil
        createdLabel.attributedText = nil
        showMoreButton.removeTarget(nil, action: nil, for: .allEvents)
    }
}

// MARK: - Private helpers
private extension ReviewCell {

    func setupCell() {
        selectionStyle = .none
        contentView.backgroundColor = .systemBackground
        setupAvatar()
        setupUsername()
        setupRating()
        setupReviewText()
        setupCreated()
        setupShowMore()
    }

    func setupAvatar() {
        contentView.addSubview(avatarImageView)
        avatarImageView.layer.cornerRadius = Layout.avatarCornerRadius
        avatarImageView.clipsToBounds = true
        avatarImageView.contentMode = .scaleAspectFill
    }

    func setupUsername() {
        contentView.addSubview(usernameLabel)
        usernameLabel.numberOfLines = 1
    }

    func setupRating() {
        contentView.addSubview(ratingImageView)
        ratingImageView.contentMode = .left
    }

    func setupReviewText() {
        contentView.addSubview(reviewTextLabel)
        reviewTextLabel.numberOfLines = 0
        reviewTextLabel.lineBreakMode = .byWordWrapping
    }

    func setupCreated() {
        contentView.addSubview(createdLabel)
    }

    func setupShowMore() {
        contentView.addSubview(showMoreButton)
        showMoreButton.contentVerticalAlignment = .fill
        showMoreButton.setAttributedTitle(Config.showMoreText, for: .normal)

        showMoreButton.addAction(
            UIAction { [weak self] _ in
                guard let cfg = self?.config else { return }
                cfg.onTapShowMore(cfg.id)
            },
            for: .touchUpInside
        )
    }

}

// MARK: - Layout
/// Расчёт фреймов сабвью + итоговой высоты ячейки.
final class ReviewCellLayout {

    // MARK: Размеры
    static let avatarSize = CGSize(width: 36, height: 36)
    static let avatarCornerRadius: CGFloat = 18
    private static let showMoreButtonSize = ReviewCellConfig.showMoreText.size()

    // MARK: Фреймы
    private(set) var avatarFrame = CGRect.zero
    private(set) var usernameLabelFrame = CGRect.zero
    private(set) var ratingImageViewFrame = CGRect.zero
    private(set) var reviewTextLabelFrame = CGRect.zero
    private(set) var showMoreButtonFrame = CGRect.zero
    private(set) var createdLabelFrame = CGRect.zero

    // MARK: Отступы
    private let insets = UIEdgeInsets(top: 9, left: 12, bottom: 9, right: 12)
    private let avatarToUsernameSpacing: CGFloat = 10
    private let usernameToRatingSpacing: CGFloat = 6
    private let ratingToTextSpacing: CGFloat = 6
    private let reviewTextToCreatedSpacing: CGFloat = 6
    private let showMoreToCreatedSpacing: CGFloat = 6

    // MARK: Layout
    func height(config: ReviewCellConfig, maxWidth: CGFloat) -> CGFloat {

        let contentWidth = maxWidth - insets.left - insets.right

        // 1. Аватар
        avatarFrame = CGRect(origin: CGPoint(x: insets.left, y: insets.top),
                             size: Self.avatarSize)

        // 2. Имя
        let usernameX = avatarFrame.maxX + avatarToUsernameSpacing
        let usernameMaxWidth = contentWidth - Self.avatarSize.width - avatarToUsernameSpacing
        let usernameSize = config.username.boundingRect(width: usernameMaxWidth).size
        usernameLabelFrame = CGRect(origin: CGPoint(x: usernameX, y: insets.top),
                                    size: usernameSize)

        // 3. Рейтинг (под именем)
        ratingImageViewFrame = CGRect(origin: CGPoint(x: usernameX,
                                                      y: usernameLabelFrame.maxY + usernameToRatingSpacing),
                                      size: config.ratingImage.size)

        // 4. Текст отзыва
        var maxY = max(avatarFrame.maxY, ratingImageViewFrame.maxY) + ratingToTextSpacing

        var showMore = false
        if !config.reviewText.isEmpty() {
            let fullTextHeight = config.reviewText.boundingRect(width: contentWidth).height
            let limitedHeight = (config.reviewText.font()?.lineHeight ?? 0) * CGFloat(config.maxLines)
            showMore = config.maxLines != 0 && fullTextHeight > limitedHeight

            let textHeight = showMore ? limitedHeight : fullTextHeight
            reviewTextLabelFrame = CGRect(x: insets.left,
                                          y: maxY,
                                          width: contentWidth,
                                          height: textHeight)
            maxY = reviewTextLabelFrame.maxY + reviewTextToCreatedSpacing
        }

        // 5. Кнопка «Показать полностью…»
        if showMore {
            showMoreButtonFrame = CGRect(origin: CGPoint(x: insets.left, y: maxY),
                                         size: Self.showMoreButtonSize)
            maxY = showMoreButtonFrame.maxY + showMoreToCreatedSpacing
        } else {
            showMoreButtonFrame = .zero
        }

        // 6. Дата создания
        let createdSize = config.created.boundingRect(width: contentWidth).size
        createdLabelFrame = CGRect(origin: CGPoint(x: insets.left, y: maxY),
                                   size: createdSize)

        // 7. Итог
        return createdLabelFrame.maxY + insets.bottom
    }
}

// MARK: - Typealias

fileprivate typealias Config = ReviewCellConfig
fileprivate typealias Layout = ReviewCellLayout
