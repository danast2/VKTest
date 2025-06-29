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

    let photos: [UIImage]

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

        for (idx, imgView) in cell.photoImageViews.enumerated() {
            if idx < photos.count {
                imgView.isHidden = false              // ✅ NEW
                imgView.image    = photos[idx]        // 🔄 EDIT
            } else {
                imgView.isHidden = true               // ✅ NEW
                imgView.image    = nil
            }
        }

        cell.avatarImageView.image        = avatar
        cell.usernameLabel.attributedText = username
        cell.ratingImageView.image        = ratingImage
        cell.reviewTextLabel.attributedText = reviewText
        cell.reviewTextLabel.numberOfLines  = maxLines
        cell.createdLabel.attributedText  = created

        cell.showMoreButton.isHidden = maxLines == .zero

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
    fileprivate var photoImageViews: [UIImageView] = []

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

        for (idx, frame) in layout.photoFrames.enumerated() {
            photoImageViews[idx].frame = frame
        }

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
        photoImageViews.forEach { $0.image = nil }
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
        setupPhotos()
    }

    private func setupPhotos() {
        (0..<3).forEach { _ in
            let iv = UIImageView()
            iv.layer.cornerRadius = Layout.photoCornerRadius
            iv.clipsToBounds = true
            iv.contentMode = .scaleAspectFill
            photoImageViews.append(iv)
            contentView.addSubview(iv)
        }
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

    private func setupShowMore() {
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
/// Отвечает за вычисление фреймов сабвью и итоговой высоты ячейки.
final class ReviewCellLayout {

    // MARK: Константы ─ размеры
    static let avatarSize         = CGSize(width: 36, height: 36)
    static let avatarCornerRadius = 18.0
    static let photoCornerRadius  = 8.0
    private static let showMoreButtonSize = ReviewCellConfig.showMoreText.size()
    private static let photoSize  = CGSize(width: 55, height: 66)

    // MARK: Фреймы
    private(set) var avatarFrame         = CGRect.zero
    private(set) var usernameLabelFrame  = CGRect.zero
    private(set) var ratingImageViewFrame = CGRect.zero
    private(set) var photoFrames: [CGRect] = []
    private(set) var reviewTextLabelFrame = CGRect.zero
    private(set) var showMoreButtonFrame  = CGRect.zero
    private(set) var createdLabelFrame    = CGRect.zero

    // MARK: Константы ─ отступы
    private let insets                    = UIEdgeInsets(top: 9, left: 12, bottom: 9, right: 12)
    private let avatarToUsernameSpacing   = 10.0
    private let usernameToRatingSpacing   = 6.0
    private let ratingToTextSpacing       = 6.0
    private let photosSpacing             = 8.0
    private let photosToTextSpacing       = 10.0
    private let reviewTextToCreatedSpacing = 6.0
    private let showMoreToCreatedSpacing  = 6.0

    // MARK: Расчёт
    /// Возвращает высоту ячейки при ширине `maxWidth`.
    func height(config: ReviewCellConfig, maxWidth: CGFloat) -> CGFloat {

        let contentWidth = maxWidth - insets.left - insets.right

        // 1. Аватар ------------------------------------------------------------
        avatarFrame = CGRect(
            origin: CGPoint(x: insets.left, y: insets.top),
            size: Self.avatarSize
        )

        // 2. Имя ---------------------------------------------------------------
        let usernameX        = avatarFrame.maxX + avatarToUsernameSpacing
        let usernameMaxWidth = contentWidth - Self.avatarSize.width - avatarToUsernameSpacing
        let usernameSize     = config.username.boundingRect(width: usernameMaxWidth).size

        usernameLabelFrame = CGRect(
            origin: CGPoint(x: usernameX, y: insets.top),
            size: usernameSize
        )

        // 3. Рейтинг ----------------------------------------------------------
        ratingImageViewFrame = CGRect(
            origin: CGPoint(
                x: usernameX,
                y: usernameLabelFrame.maxY + usernameToRatingSpacing
            ),
            size: config.ratingImage.size
        )

        // 4. Базовая точка Y для следующих элементов --------------------------
        var maxY = max(avatarFrame.maxY, ratingImageViewFrame.maxY) + ratingToTextSpacing

        // 5. Фото (если есть) --------------------------------------------------
        if !config.photos.isEmpty {
            photoFrames = config.photos.enumerated().map { idx, _ in
                CGRect(
                    x: insets.left + CGFloat(idx)*(Self.photoSize.width + photosSpacing),
                    y: maxY,
                    width: Self.photoSize.width,
                    height: Self.photoSize.height
                )
            }
            maxY = maxY + Self.photoSize.height + photosToTextSpacing
        } else {
            photoFrames = []
        }

        // 6. Текст отзыва ------------------------------------------------------
        var showMoreNeeded = false
        if !config.reviewText.isEmpty() {
            let fullHeight    = config.reviewText.boundingRect(width: contentWidth).height
            let limitedHeight = (config.reviewText.font()?.lineHeight ?? 0) * CGFloat(config.maxLines)
            showMoreNeeded    = config.maxLines != 0 && fullHeight > limitedHeight

            let textHeight = showMoreNeeded ? limitedHeight : fullHeight
            reviewTextLabelFrame = CGRect(
                x: insets.left, y: maxY,
                width: contentWidth, height: textHeight
            )
            maxY = reviewTextLabelFrame.maxY + reviewTextToCreatedSpacing
        }

        // 7. Кнопка «Показать полностью…» -------------------------------------
        if showMoreNeeded {
            showMoreButtonFrame = CGRect(
                origin: CGPoint(x: insets.left, y: maxY),
                size: Self.showMoreButtonSize
            )
            maxY = showMoreButtonFrame.maxY + showMoreToCreatedSpacing
        } else {
            showMoreButtonFrame = .zero
        }

        // 8. Дата --------------------------------------------------------------
        let createdSize = config.created.boundingRect(width: contentWidth).size
        createdLabelFrame = CGRect(
            origin: CGPoint(x: insets.left, y: maxY),
            size: createdSize
        )

        // 9. Итоговая высота ---------------------------------------------------
        return createdLabelFrame.maxY + insets.bottom
    }
}


// MARK: - Typealias

fileprivate typealias Config = ReviewCellConfig
fileprivate typealias Layout = ReviewCellLayout
