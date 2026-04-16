//
//----------------------------------------------
// Original project: rsyncGUI
//
// Follow me on Mastodon: https://iosdev.space/@StewartLynch
// Follow me on Threads: https://www.threads.net/@stewartlynch
// Follow me on Bluesky: https://bsky.app/profile/stewartlynch.bsky.social
// Follow me on X: https://x.com/StewartLynch
// Follow me on LinkedIn: https://linkedin.com/in/StewartLynch
// Email: slynch@createchsol.com
// Subscribe on YouTube: https://youTube.com/@StewartLynch
// Buy me a ko-fi:  https://ko-fi.com/StewartLynch
//----------------------------------------------
// Copyright © 2026 CreaTECH Solutions (Stewart Lynch). All rights reserved.

import SwiftUI
import UniformTypeIdentifiers
import AppKit

struct PathInputView: View {
    let title: String
    @Binding var path: String
    /// When `true`, the open panel and drag target accept files AND folders.
    /// When `false` (destination), only folders are accepted.
    let allowFiles: Bool
    /// Optional hint shown in small text below the row (e.g. to explain Sync semantics).
    var helpText: String? = nil

    @State private var isDropTargeted = false
    @State private var validationMessage: String? = nil

    private var placeholderText: String {
        allowFiles
            ? "Drag a file or folder here, or choose one in Finder"
            : "Drag a folder here, or choose one in Finder"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text(title)
                    .frame(width: 90, alignment: .trailing)
                    .fontWeight(.medium)

                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(nsColor: .textBackgroundColor))

                    HStack {
                        Text(path.isEmpty ? placeholderText : path)
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(path.isEmpty ? .secondary : .primary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .textSelection(.enabled)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)

                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.clear)
                        .contentShape(RoundedRectangle(cornerRadius: 6))
                        .onDrop(of: [UTType.fileURL], isTargeted: $isDropTargeted) { providers in
                            handleDrop(providers: providers)
                        }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isDropTargeted ? Color.accentColor : Color.secondary.opacity(0.25), lineWidth: isDropTargeted ? 2 : 1)
                )

                Button {
                    openPanel()
                } label: {
                    Image(systemName: "folder.badge.plus")
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Browse for \(title.lowercased().replacingOccurrences(of: ":", with: ""))")
                .help("Browse for a \(allowFiles ? "file or folder" : "folder")")

                // Status icon
                if !path.isEmpty {
                    pathStatusIcon
                }
            }

            if let msg = validationMessage {
                Text(msg)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.leading, 98)
            }

            if let hint = helpText {
                Text(hint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 98)
            }
        }
    }

    @ViewBuilder
    private var pathStatusIcon: some View {
        let status = pathStatus(path)
        if status.exists {
            if !allowFiles && !status.isDirectory {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.red)
                    .help("Destination must be a folder")
            } else {
                Image(systemName: status.isDirectory ? "folder.fill" : "doc.fill")
                    .foregroundStyle(.secondary)
            }
        } else {
            Image(systemName: "questionmark.circle")
                .foregroundStyle(.secondary)
                .help("Path does not exist")
        }
    }

    // MARK: - Drop Handler

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        _ = provider.loadObject(ofClass: URL.self) { url, _ in
            guard let url else { return }
            let status = pathStatus(url.path(percentEncoded: false))
            guard status.exists else { return }
            if !allowFiles && !status.isDirectory {
                Task { @MainActor in
                    validationMessage = "Destination must be a folder."
                }
                return
            }
            Task { @MainActor in
                path = url.path(percentEncoded: false)
                validationMessage = nil
            }
        }
        return true
    }

    // MARK: - Open Panel

    private func openPanel() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = allowFiles
        panel.canCreateDirectories = false
        panel.message = allowFiles
            ? "Select a file or folder"
            : (helpText != nil ? "Select the target folder to sync into" : "Select a destination folder")
        panel.prompt = "Select"

        if panel.runModal() == .OK, let url = panel.url {
            path = url.path(percentEncoded: false)
            validationMessage = nil
        }
    }

    // MARK: - Helpers

    private func pathStatus(_ p: String) -> PathStatus {
        var isDir: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: p, isDirectory: &isDir)
        guard exists else {
            return PathStatus(exists: false, isDirectory: false)
        }

        let url = URL(fileURLWithPath: p)
        let values = try? url.resourceValues(forKeys: [.isPackageKey])
        let isPackage = values?.isPackage ?? false
        return PathStatus(exists: true, isDirectory: isDir.boolValue && !isPackage)
    }
}

private struct PathStatus {
    let exists: Bool
    let isDirectory: Bool
}
