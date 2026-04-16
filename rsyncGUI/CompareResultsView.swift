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

struct CompareResultsView: View {
    let results: [CompareResult]
    @Binding var isPresented: Bool

    @State private var filter: ChangeType? = nil
    @State private var searchText = ""

    private var displayed: [CompareResult] {
        results.filter { item in
            let typeMatch = filter == nil || item.changeType == filter
            let textMatch = searchText.isEmpty || item.path.localizedCaseInsensitiveContains(searchText)
            return typeMatch && textMatch
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if results.isEmpty {
                identicalView
            } else {
                filterBar
                Divider()
                resultsList
            }
            Divider()
            footer
        }
        .frame(minWidth: 640, minHeight: 520)
    }

    // MARK: - Subviews

    private var header: some View {
        HStack(spacing: 14) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 40))
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 3) {
                Text("Comparison Results")
                    .font(.title2)
                    .fontWeight(.bold)
                Text(results.isEmpty
                    ? "Source and destination are identical."
                    : "\(results.count) difference\(results.count == 1 ? "" : "s") found.")
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if !results.isEmpty {
                TextField("Search paths…", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 180)
            }
        }
        .padding(20)
    }

    private var identicalView: some View {
        VStack(spacing: 14) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)
            Text("No Differences Found")
                .font(.title3)
                .fontWeight(.semibold)
            Text("Source and destination contain the same files.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(label: "All (\(results.count))", type: nil)

                let newCount = count(of: .newFile)
                if newCount > 0 { filterChip(label: "New (\(newCount))", type: .newFile) }

                let modCount = count(of: .modified)
                if modCount > 0 { filterChip(label: "Modified (\(modCount))", type: .modified) }

                let delCount = count(of: .deleted)
                if delCount > 0 { filterChip(label: "Deleted (\(delCount))", type: .deleted) }

                let attrCount = count(of: .attributeChanged)
                if attrCount > 0 { filterChip(label: "Changed (\(attrCount))", type: .attributeChanged) }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    @ViewBuilder
    private func filterChip(label: String, type: ChangeType?) -> some View {
        let isSelected = filter == type
        let chipColor: Color = type?.color ?? .secondary

        Button(label) { filter = type }
            .buttonStyle(.bordered)
            .tint(isSelected ? chipColor : .secondary)
            .fontWeight(isSelected ? .semibold : .regular)
    }

    private var resultsList: some View {
        Table(displayed) {
            TableColumn("Change") { item in
                HStack(spacing: 6) {
                    Image(systemName: item.changeType.systemImage)
                        .foregroundStyle(item.changeType.color)
                    Text(item.changeType.label)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(item.changeType.color.opacity(0.12))
                        .foregroundStyle(item.changeType.color)
                        .clipShape(Capsule())
                }
            }
            .width(min: 90, ideal: 100, max: 110)

            TableColumn("Path") { item in
                Text(item.path)
                    .font(.system(.callout, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            TableColumn("Code") { item in
                Text(item.itemCode)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            .width(min: 80, ideal: 90, max: 100)
        }
    }

    private var footer: some View {
        HStack {
            if !displayed.isEmpty {
                Text("Showing \(displayed.count) of \(results.count) items")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Done") { isPresented = false }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
        }
        .padding(16)
    }

    // MARK: - Helpers

    private func count(of type: ChangeType) -> Int {
        results.filter { $0.changeType == type }.count
    }
}
