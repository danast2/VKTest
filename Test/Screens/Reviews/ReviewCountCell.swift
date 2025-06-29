//
//  ReviewCountCell.swift
//  Test
//
//  Created by Даниил Дементьев on 30.06.2025.
//

import UIKit

// MARK: - Config

/// Конфигурация «ячейки количества отзывов».
struct ReviewCountCellConfig: TableCellConfig {

    static let reuseId = String(describing: ReviewCountCellConfig.self)

    /// Атрибутированный текст («127 отзывов»).
    let text: NSAttributedString

    func update(cell: UITableViewCell) {
        guard let cell = cell as? ReviewCountCell else { return }
        cell.countLabel.attributedText = text
    }

    func height(with size: CGSize) -> CGFloat {
        let insets = Layout.insets
        let bounding = text.boundingRect(
            width: size.width - insets.left - insets.right
        ).size.height
        return bounding + insets.top + insets.bottom
    }
}

// MARK: - Cell

final class ReviewCountCell: UITableViewCell {

    fileprivate let countLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        selectionStyle = .none
        contentView.addSubview(countLabel)
        countLabel.textAlignment = .center
        countLabel.numberOfLines = 0
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        countLabel.frame = bounds.inset(by: Layout.insets)
    }
}

// MARK: - Layout constants
private enum Layout {
    static let insets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
}
