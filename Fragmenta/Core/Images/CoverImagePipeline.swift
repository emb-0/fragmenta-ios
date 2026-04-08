import Foundation
#if canImport(UIKit)
import UIKit
import ImageIO
#endif

#if canImport(UIKit)
final class CoverImagePipeline: @unchecked Sendable {
    static let shared = CoverImagePipeline()

    private let session: URLSession
    private let memoryCache = NSCache<NSString, UIImage>()
    private let lock = NSLock()
    private var inFlightTasks: [NSString: Task<UIImage, Error>] = [:]

    init(session: URLSession? = nil) {
        if let session {
            self.session = session
        } else {
            let configuration = URLSessionConfiguration.default
            configuration.requestCachePolicy = .returnCacheDataElseLoad
            configuration.timeoutIntervalForRequest = 30
            configuration.timeoutIntervalForResource = 60
            configuration.urlCache = URLCache(
                memoryCapacity: 64 * 1_024 * 1_024,
                diskCapacity: 256 * 1_024 * 1_024,
                diskPath: "fragmenta-cover-cache"
            )
            self.session = URLSession(configuration: configuration)
        }

        memoryCache.countLimit = 120
        memoryCache.totalCostLimit = 48 * 1_024 * 1_024
    }

    func image(for url: URL, maxPixelSize: CGFloat) async throws -> UIImage {
        let cacheKey = NSString(string: "\(url.absoluteString)|\(Int(maxPixelSize.rounded()))")

        if let cached = memoryCache.object(forKey: cacheKey) {
            return cached
        }

        let task: Task<UIImage, Error>
        lock.lock()
        if let existingTask = inFlightTasks[cacheKey] {
            task = existingTask
            lock.unlock()
        } else {
            let session = self.session
            task = Task(priority: .utility) {
                var request = URLRequest(url: url)
                request.cachePolicy = .returnCacheDataElseLoad

                let (data, response) = try await session.data(for: request)
                guard
                    let httpResponse = response as? HTTPURLResponse,
                    (200 ..< 300).contains(httpResponse.statusCode)
                else {
                    throw URLError(.badServerResponse)
                }

                guard let image = Self.downsampledImage(from: data, maxPixelSize: maxPixelSize) else {
                    throw URLError(.cannotDecodeContentData)
                }

                return image
            }
            inFlightTasks[cacheKey] = task
            lock.unlock()
        }

        do {
            let image = try await task.value
            memoryCache.setObject(image, forKey: cacheKey, cost: image.fragmentaCacheCost)
            lock.lock()
            inFlightTasks[cacheKey] = nil
            lock.unlock()
            return image
        } catch {
            lock.lock()
            inFlightTasks[cacheKey] = nil
            lock.unlock()
            throw error
        }
    }

    func prefetch(urls: [URL], maxPixelSize: CGFloat) async {
        await withTaskGroup(of: Void.self) { group in
            for url in urls.prefix(30) {
                group.addTask { [weak self] in
                    guard let self else {
                        return
                    }

                    _ = try? await self.image(for: url, maxPixelSize: maxPixelSize)
                }
            }
        }
    }

    func clear() {
        memoryCache.removeAllObjects()
        session.configuration.urlCache?.removeAllCachedResponses()

        lock.lock()
        let tasks = inFlightTasks.values
        inFlightTasks.removeAll()
        lock.unlock()

        tasks.forEach { $0.cancel() }
    }

    private static func downsampledImage(from data: Data, maxPixelSize: CGFloat) -> UIImage? {
        let options = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, options) else {
            return nil
        }

        let downsampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: max(120, Int(maxPixelSize.rounded()))
        ] as CFDictionary

        guard let image = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) else {
            return nil
        }

        return UIImage(cgImage: image)
    }
}

private extension UIImage {
    var fragmentaCacheCost: Int {
        guard let cgImage else {
            return 0
        }

        return cgImage.bytesPerRow * cgImage.height
    }
}
#endif
