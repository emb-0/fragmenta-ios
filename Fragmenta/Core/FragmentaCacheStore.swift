import Foundation

actor FragmentaCacheStore {
    private let fileManager: FileManager
    private let directoryURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder.fragmenta

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager

        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        self.directoryURL = cachesDirectory.appendingPathComponent("FragmentaCache", isDirectory: true)

        self.encoder.keyEncodingStrategy = .convertToSnakeCase
        self.encoder.dateEncodingStrategy = .iso8601

        try? fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
    }

    func load<Value: Decodable>(_ type: Value.Type, forKey key: String) -> Value? {
        let fileURL = fileURL(forKey: key)

        guard
            fileManager.fileExists(atPath: fileURL.path),
            let data = try? Data(contentsOf: fileURL),
            let decodedValue = try? decoder.decode(Value.self, from: data)
        else {
            return nil
        }

        return decodedValue
    }

    func save<Value: Encodable>(_ value: Value, forKey key: String) throws {
        let fileURL = fileURL(forKey: key)
        let data = try encoder.encode(value)
        try data.write(to: fileURL, options: .atomic)
    }

    func removeValue(forKey key: String) throws {
        let fileURL = fileURL(forKey: key)
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return
        }

        try fileManager.removeItem(at: fileURL)
    }

    func removeAll() throws {
        guard fileManager.fileExists(atPath: directoryURL.path) else {
            return
        }

        let contents = try fileManager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)
        for url in contents {
            try fileManager.removeItem(at: url)
        }
    }

    private func fileURL(forKey key: String) -> URL {
        let filename = key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? UUID().uuidString
        return directoryURL.appendingPathComponent(filename).appendingPathExtension("json")
    }
}
