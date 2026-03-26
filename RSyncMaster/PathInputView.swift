//
//----------------------------------------------
// Original project: RSyncMaster
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

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text(title)
                    .frame(width: 90, alignment: .trailing)
                    .fontWeight(.medium)

                TextField(
                    allowFiles ? "Type a path, or drag a file/folder here…" : "Type a folder path, or drag a folder here…",
                    text: $path
                )
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))
                .onDrop(of: [UTType.fileURL], isTargeted: $isDropTargeted) { providers in
                    handleDrop(providers: providers)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isDropTargeted ? Color.accentColor : Color.clear, lineWidth: 2)
                )
                .onChange(of: path) { _, _ in
                    validationMessage = nil
                }

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
        let (exists, isDir) = pathStatus(path)
        if exists {
            if !allowFiles && !isDir {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.red)
                    .help("Destination must be a folder")
            } else {
                Image(systemName: isDir ? "folder.fill" : "doc.fill")
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
            let (exists, isDir) = pathStatus(url.path(percentEncoded: false))
            guard exists else { return }
            if !allowFiles && !isDir {
                Task { @MainActor in
                    validationMessage = "Destination must be a folder."
                }
                return
            }
            Task { @MainActor in
                path = url.path(percentEncoded: false)
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
        }
    }

    // MARK: - Helpers

    private func pathStatus(_ p: String) -> (exists: Bool, isDirectory: Bool) {
        var isDir: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: p, isDirectory: &isDir)
        return (exists, isDir.boolValue)
    }
}
