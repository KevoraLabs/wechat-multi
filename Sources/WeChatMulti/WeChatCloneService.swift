import AppKit
import Foundation

enum WeChatMultiConstants {
    static let cloneBundleIdentifier = "com.tencent.xin.WeChatMulti"
    static let cloneDisplayName = "WeChat 2"
    static let cloneAppURL: URL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Applications", isDirectory: true)
        .appendingPathComponent("WeChat-2.app", isDirectory: true)
}

struct WeChatCloneStatus {
    let primaryAppURL: URL?
    let cloneAppURL: URL
    let cloneExists: Bool
}

enum WeChatCloneError: LocalizedError {
    case primaryWeChatNotFound
    case cloneNotFound
    case invalidInfoPlist
    case failedToTerminateClone
    case processFailed(String)

    var errorDescription: String? {
        switch self {
        case .primaryWeChatNotFound:
            return "没有找到主微信，请先安装官方微信。"
        case .cloneNotFound:
            return "还没有创建微信副本。"
        case .invalidInfoPlist:
            return "副本的 Info.plist 无法解析。"
        case .failedToTerminateClone:
            return "无法在更新前关闭微信副本，请手动退出后重试。"
        case let .processFailed(message):
            return message
        }
    }
}

final class WeChatCloneService {
    private let fileManager = FileManager.default
    private let logStore: LogStore

    init(logStore: LogStore) {
        self.logStore = logStore
    }

    func status() -> WeChatCloneStatus {
        let cloneURL = WeChatMultiConstants.cloneAppURL
        return WeChatCloneStatus(
            primaryAppURL: locatePrimaryWeChat(),
            cloneAppURL: cloneURL,
            cloneExists: fileManager.fileExists(atPath: cloneURL.path)
        )
    }

    func createOrUpdateClone() async throws {
        guard let primaryURL = locatePrimaryWeChat() else {
            throw WeChatCloneError.primaryWeChatNotFound
        }

        logStore.append("开始创建副本，源路径: \(primaryURL.path)")

        try await terminateRunningCloneIfNeeded()
        try ensureCloneParentDirectory()

        if fileManager.fileExists(atPath: WeChatMultiConstants.cloneAppURL.path) {
            try fileManager.removeItem(at: WeChatMultiConstants.cloneAppURL)
            logStore.append("已删除旧副本")
        }

        try fileManager.copyItem(at: primaryURL, to: WeChatMultiConstants.cloneAppURL)
        logStore.append("已复制到 \(WeChatMultiConstants.cloneAppURL.path)")

        try patchInfoPlist()
        try runProcess(
            executableURL: URL(fileURLWithPath: "/usr/bin/codesign"),
            arguments: ["--force", "--deep", "--sign", "-", WeChatMultiConstants.cloneAppURL.path]
        )

        logStore.append("副本重签名完成")
    }

    func launchPrimaryWeChat() async throws {
        guard let primaryURL = locatePrimaryWeChat() else {
            throw WeChatCloneError.primaryWeChatNotFound
        }
        try await launchApp(at: primaryURL)
        logStore.append("已启动主微信")
    }

    func launchClone() async throws {
        guard fileManager.fileExists(atPath: WeChatMultiConstants.cloneAppURL.path) else {
            throw WeChatCloneError.cloneNotFound
        }
        try await launchApp(at: WeChatMultiConstants.cloneAppURL)
        logStore.append("已启动微信副本")
    }

    func launchBoth() async throws {
        try await launchPrimaryWeChat()
        try await Task.sleep(nanoseconds: 300_000_000)
        try await launchClone()
    }

    func deleteClone() async throws {
        guard fileManager.fileExists(atPath: WeChatMultiConstants.cloneAppURL.path) else {
            throw WeChatCloneError.cloneNotFound
        }
        try await terminateRunningCloneIfNeeded()
        try fileManager.removeItem(at: WeChatMultiConstants.cloneAppURL)
        logStore.append("已删除副本")
    }

    private func locatePrimaryWeChat() -> URL? {
        let bundleIdentifiers = [
            "com.tencent.xinWeChat",
            "com.tencent.wechat",
            "com.tencent.xin"
        ]

        for bundleIdentifier in bundleIdentifiers {
            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier),
               fileManager.fileExists(atPath: url.path) {
                return url
            }
        }

        let candidates = [
            URL(fileURLWithPath: "/Applications/WeChat.app"),
            fileManager.homeDirectoryForCurrentUser
                .appendingPathComponent("Applications", isDirectory: true)
                .appendingPathComponent("WeChat.app", isDirectory: true)
        ]

        return candidates.first(where: { fileManager.fileExists(atPath: $0.path) })
    }

    private func ensureCloneParentDirectory() throws {
        let parentURL = WeChatMultiConstants.cloneAppURL.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: parentURL.path) {
            try fileManager.createDirectory(at: parentURL, withIntermediateDirectories: true, attributes: nil)
            logStore.append("已创建目录 \(parentURL.path)")
        }
    }

    private func patchInfoPlist() throws {
        let infoPlistURL = WeChatMultiConstants.cloneAppURL
            .appendingPathComponent("Contents", isDirectory: true)
            .appendingPathComponent("Info.plist", isDirectory: false)

        let data = try Data(contentsOf: infoPlistURL)
        guard var plist = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
            throw WeChatCloneError.invalidInfoPlist
        }

        plist["CFBundleIdentifier"] = WeChatMultiConstants.cloneBundleIdentifier
        plist["CFBundleDisplayName"] = WeChatMultiConstants.cloneDisplayName
        plist["CFBundleName"] = WeChatMultiConstants.cloneDisplayName

        let updatedData = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        try updatedData.write(to: infoPlistURL)
        logStore.append("已修改副本 Bundle ID 为 \(WeChatMultiConstants.cloneBundleIdentifier)")
    }

    private func terminateRunningCloneIfNeeded() async throws {
        let runningApps = NSRunningApplication.runningApplications(
            withBundleIdentifier: WeChatMultiConstants.cloneBundleIdentifier
        )

        guard !runningApps.isEmpty else {
            return
        }

        logStore.append("检测到微信副本正在运行，准备关闭")

        runningApps.forEach { $0.terminate() }

        let deadline = Date().addingTimeInterval(5)
        while Date() < deadline {
            let stillRunning = NSRunningApplication.runningApplications(
                withBundleIdentifier: WeChatMultiConstants.cloneBundleIdentifier
            )
            if stillRunning.isEmpty {
                logStore.append("微信副本已关闭")
                return
            }
            try await Task.sleep(nanoseconds: 200_000_000)
        }

        throw WeChatCloneError.failedToTerminateClone
    }

    private func launchApp(at url: URL) async throws {
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            NSWorkspace.shared.openApplication(at: url, configuration: configuration) { _, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: ())
            }
        }
    }

    private func runProcess(executableURL: URL, arguments: [String]) throws {
        let process = Process()
        process.executableURL = executableURL
        process.arguments = arguments

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = outputPipe

        try process.run()
        process.waitUntilExit()

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard process.terminationStatus == 0 else {
            throw WeChatCloneError.processFailed(
                output.isEmpty ? "系统签名命令执行失败。" : "系统签名命令执行失败：\(output)"
            )
        }
    }
}
