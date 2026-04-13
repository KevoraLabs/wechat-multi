import SwiftUI

@main
struct WeChatMultiApp: App {
    @StateObject private var viewModel = WeChatMultiViewModel()

    var body: some Scene {
        MenuBarExtra {
            MenuBarContent(viewModel: viewModel)
        } label: {
            Image(systemName: viewModel.menuBarSymbolName)
                .symbolRenderingMode(.monochrome)
                .font(.system(size: 15, weight: .semibold))
        }
        .menuBarExtraStyle(.menu)

        Settings {
            EmptyView()
        }
    }
}

private struct MenuBarContent: View {
    @ObservedObject var viewModel: WeChatMultiViewModel

    var body: some View {
        Group {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.primaryStatusText)
                        .font(.headline)

                    Text(viewModel.cloneStatusText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(viewModel.destinationPath)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
                .frame(maxWidth: 320, alignment: .leading)
            }

            Section {
                Button {
                    viewModel.createOrUpdateClone()
                } label: {
                    Label(viewModel.cloneExists ? "更新微信副本" : "创建微信副本", systemImage: "doc.on.doc")
                }
                .disabled(!viewModel.canManageClone)

                Button {
                    viewModel.launchPrimaryWeChat()
                } label: {
                    Label("启动主微信", systemImage: "message")
                }
                .disabled(!viewModel.primaryWeChatExists)

                Button {
                    viewModel.launchClone()
                } label: {
                    Label("启动微信副本", systemImage: "message.badge")
                }
                .disabled(!viewModel.cloneExists)

                Button {
                    viewModel.launchBoth()
                } label: {
                    Label("同时启动两个实例", systemImage: "rectangle.on.rectangle")
                }
                .disabled(!viewModel.canLaunchBoth)

                Button(role: .destructive) {
                    viewModel.deleteClone()
                } label: {
                    Label("删除微信副本", systemImage: "trash")
                }
                .disabled(!viewModel.cloneExists)
            }

            Section {
                Button {
                    viewModel.openCloneInFinder()
                } label: {
                    Label("在访达中显示副本", systemImage: "folder")
                }
                .disabled(!viewModel.cloneExists)

                Button {
                    viewModel.openLogFile()
                } label: {
                    Label("打开日志文件", systemImage: "doc.text")
                }

                Button {
                    viewModel.refresh()
                } label: {
                    Label("刷新状态", systemImage: "arrow.clockwise")
                }
            }

            if let message = viewModel.lastMessage {
                Section("最近结果") {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: 320, alignment: .leading)
                        .textSelection(.enabled)
                }
            }

            Divider()

            Button {
                NSApp.terminate(nil)
            } label: {
                Label("退出", systemImage: "power")
            }
            .keyboardShortcut("q")
        }
    }
}
