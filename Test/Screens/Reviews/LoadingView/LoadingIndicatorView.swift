//
//  LoadingIndicatorView.swift
//  Test
//
//  Created by Даниил Дементьев on 30.06.2025.
//

import UIKit

/// Кастомный инди­ка­тор загрузки: кольцо, «бегущее» по окружности.
final class LoadingIndicatorView: UIView {

    private let shape = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        setupLayer()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setupLayer() {
        let radius: CGFloat = 16
        let path = UIBezierPath(arcCenter: .zero,
                                radius: radius,
                                startAngle: -.pi/2,
                                endAngle: 3 * .pi/2,
                                clockwise: true)

        shape.path = path.cgPath
        shape.lineWidth = 3
        shape.strokeColor = UIColor.systemBlue.cgColor
        shape.fillColor = UIColor.clear.cgColor
        shape.lineCap = .round
        layer.addSublayer(shape)

        // позиционируем в центре
        shape.position = CGPoint(x: bounds.midX, y: bounds.midY)
        shape.bounds   = CGRect(origin: .zero, size: CGSize(width: radius*2, height: radius*2))
    }

    /// Запустить анимацию.
    func start() {
        isHidden = false
        if shape.animation(forKey: "rotate") == nil {
            addAnimations()
        }
    }

    /// Остановить и скрыть.
    func stop() {
        shape.removeAllAnimations()
        isHidden = true
    }

    private func addAnimations() {

        // 2) «бегущий» штрих
        let head = CABasicAnimation(keyPath: "strokeStart")
        head.fromValue = 0
        head.toValue   = 0.25
        head.duration  = 1
        head.repeatCount = .infinity
        head.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        let tail = CABasicAnimation(keyPath: "strokeEnd")
        tail.fromValue = 0
        tail.toValue   = 1
        tail.duration  = 1
        tail.repeatCount = .infinity
        tail.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        shape.add(head, forKey: "head")
        shape.add(tail, forKey: "tail")
    }
}
