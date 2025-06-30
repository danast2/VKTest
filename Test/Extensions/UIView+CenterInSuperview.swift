//
//  UIView+CenterInSuperview.swift
//  Test
//
//  Created by Даниил Дементьев on 30.06.2025.
//

import UIKit

extension UIView {

    /// Добавляет `view` как сабвью и центрирует по X и Y за счёт Auto-Layout.
    func addAndCenter(_ view: UIView) {
        addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.centerXAnchor.constraint(equalTo: centerXAnchor),
            view.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
}
