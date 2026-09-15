import Foundation

struct HistoryEntry: Codable, Equatable {
    var time: Date
    var prompt: String
    var response: String
}

enum HistoryStore {
    static let fileName = "history.json"
    static let cap = 20

    static var directoryURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Frontmost Copilot", isDirectory: true)
    }

    static var fileURL: URL {
        directoryURL.appendingPathComponent(fileName)
    }

    static func load() -> (entries: [HistoryEntry], error: Error?) {
        let fm = FileManager.default
        do {
            try fm.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        } catch {
            return ([], error)
        }
        guard fm.fileExists(atPath: fileURL.path) else {
            return ([], nil)
        }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let entries = try decoder.decode([HistoryEntry].self, from: data)
            return (entries, nil)
        } catch {
            return ([], error)
        }
    }

    static func save(_ entries: [HistoryEntry]) throws {
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let trimmed = Array(entries.prefix(cap))
        let data = try encoder.encode(trimmed)
        try data.write(to: fileURL, options: .atomic)
    }
}
