import AppKit
import Foundation

@MainActor
final class WeChatMultiViewModel: ObservableObject {
    @Published private(set) var primaryWeChatExists = false
    @Published private(set) var cloneExists = false
    @Published private(set) var primaryStatusText = "正在检测微信..."
    @Published private(set) var cloneStatusText = "正在读取副本状态..."
    @Published private(set) var destinationPath = WeChatMultiConstants.cloneAppURL.path
    @Published private(set) var lastMessage: String?
    @Published private(set) var isBusy = false

    private let logStore = LogStore()
    private lazy var service = WeChatCloneService(logStore: logStore)

    init() {
        refresh()
    }

    var menuBarSymbolName: String {
        if isBusy {
            return "arrow.clockwise.circle.fill"
        }
        if !primaryWeChatExists {
            return "exclamationmark.circle.fill"
        }
        if cloneExists {
            return "message.fill"
        }
        return "message"
    }

    var canManageClone: Bool {
        primaryWeChatExists && !isBusy
    }

    var canLaunchBoth: Bool {
        primaryWeChatExists && cloneExists && !isBusy
    }

    func refresh() {
        let status = service.status()
        primaryWeChatExists = status.primaryAppURL != nil
        cloneExists = status.cloneExists
        destinationPath = status.cloneAppURL.path
        primaryStatusText = status.primaryAppURL == nil ? "未检测到主微信" : "已检测到主微信"
        cloneStatusText = status.cloneExists ? "微信副本已准备好" : "微信副本尚未创建"
        lastMessage = logStore.recentLines(limit: 1).first
    }

    func createOrUpdateClone() {
        runAction(successMessage: "微信副本已更新") {
            try await self.service.createOrUpdateClone()
        }
    }

    func launchPrimaryWeChat() {
        runAction(successMessage: "主微信已启动") {
            try await self.service.launchPrimaryWeChat()
        }
    }

    func launchClone() {
        runAction(successMessage: "微信副本已启动") {
            try await self.service.launchClone()
        }
    }

    func launchBoth() {
        runAction(successMessage: "两个微信实例已启动") {
            try await self.service.launchBoth()
        }
    }

    func deleteClone() {
        runAction(successMessage: "微信副本已删除") {
            try await self.service.deleteClone()
        }
    }

    func openCloneInFinder() {
        guard cloneExists else { return }
        NSWorkspace.shared.activateFileViewerSelecting([WeChatMultiConstants.cloneAppURL])
    }

    func openLogFile() {
        let url = logStore.fileURL
        if !FileManager.default.fileExists(atPath: url.path) {
            logStore.append("日志文件已创建")
        }
        NSWorkspace.shared.open(url)
        refresh()
    }

    private func runAction(successMessage: String, action: @escaping () async throws -> Void) {
        guard !isBusy else { return }
        isBusy = true

        Task {
            defer {
                self.isBusy = false
                self.refresh()
            }

            do {
                try await action()
                self.logStore.append(successMessage)
            } catch {
                self.logStore.append("失败: \(error.localizedDescription)")
            }
        }
    }
}
