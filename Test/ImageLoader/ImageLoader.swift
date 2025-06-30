//
//  ImageLoader.swift
//  Test
//
//  Created by Даниил Дементьев on 30.06.2025.
//

import UIKit

/// VERY simple loader: memory + disk (`Caches/Images`) + URLSession.
final class ImageLoader {

    static let shared = ImageLoader()

    private let memory = NSCache<NSURL, UIImage>()
    private let queue  = DispatchQueue(label: "ImageLoader", attributes: .concurrent)

    private init() {
        let dir = diskDir()
        try? FileManager.default.createDirectory(at: dir,
                                                 withIntermediateDirectories: true)
    }

    // MARK: public
    func load(_ url: URL, completion: @escaping (UIImage?) -> Void) {
        if let img = memory.object(forKey: url as NSURL) {
            return completion(img)
        }
        // disk
        let path = diskDir().appendingPathComponent(fileName(for: url))
        if let data = try? Data(contentsOf: path),
           let img  = UIImage(data: data) {
            memory.setObject(img, forKey: url as NSURL)
            return completion(img)
        }
        // network
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            var image: UIImage? = nil
            if let data, let img = UIImage(data: data) {
                image = img
                self?.memory.setObject(img, forKey: url as NSURL)
                try? data.write(to: path)
            }
            DispatchQueue.main.async { completion(image) }
        }.resume()
    }

    // MARK: helpers
    private func diskDir() -> URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Images")
    }
    private func fileName(for url: URL) -> String {
        url.absoluteString.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
    }
}
