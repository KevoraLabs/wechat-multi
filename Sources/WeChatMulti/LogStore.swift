import Foundation

final class LogStore {
    let fileURL: URL

    private let fileManager = FileManager.default
    private let queue = DispatchQueue(label: "com.kevinxft.wechatmulti.logstore")

    init() {
        let directoryURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("WeChatMulti", isDirectory: true)
        fileURL = directoryURL.appendingPathComponent("events.log", isDirectory: false)
        ensureLogFileExists()
    }

    func append(_ message: String) {
        queue.sync {
            ensureLogFileExists()
            let timestamp = ISO8601DateFormatter().string(from: Date())
            let line = "[\(timestamp)] \(message)\n"
            guard let data = line.data(using: .utf8) else { return }

            if let handle = try? FileHandle(forWritingTo: fileURL) {
                defer { try? handle.close() }
                _ = try? handle.seekToEnd()
                try? handle.write(contentsOf: data)
            }
        }
    }

    func recentLines(limit: Int) -> [String] {
        queue.sync {
            guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else {
                return []
            }

            return content
                .split(separator: "\n", omittingEmptySubsequences: true)
                .suffix(limit)
                .map(String.init)
        }
    }

    private func ensureLogFileExists() {
        let directoryURL = fileURL.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: directoryURL.path) {
            try? fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
        }
        if !fileManager.fileExists(atPath: fileURL.path) {
            fileManager.createFile(atPath: fileURL.path, contents: Data())
        }
    }
}
