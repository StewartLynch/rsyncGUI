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

struct OperationResultsView: View {
    let operation: RSyncOperation
    let errors: [String]
    let terminationStatus: Int32
    @Binding var isPresented: Bool

    private var isSuccess: Bool { errors.isEmpty && terminationStatus == 0 }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if errors.isEmpty {
                successBody
            } else {
                errorList
            }
            Divider()
            footer
        }
        .frame(minWidth: 480, minHeight: isSuccess ? 280 : 420)
    }

    // MARK: - Subviews

    private var header: some View {
        HStack(spacing: 16) {
            Image(systemName: isSuccess ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 44))
                .foregroundStyle(isSuccess ? Color.green : Color.orange)

            VStack(alignment: .leading, spacing: 4) {
                Text("\(operation.rawValue) Complete")
                    .font(.title2)
                    .fontWeight(.bold)

                Text(isSuccess
                    ? "The \(operation.rawValue.lowercased()) operation finished with no errors."
                    : "The operation completed with \(errors.count) error\(errors.count == 1 ? "" : "s").")
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(20)
    }

    private var successBody: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: operation.systemImage)
                .font(.system(size: 56))
                .foregroundStyle(Color.accentColor.opacity(0.6))
            Text("All files were processed successfully.")
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var errorList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 6) {
                ForEach(errors, id: \.self) { error in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(.red)
                            .padding(.top, 1)
                        Text(error)
                            .font(.system(.callout, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.red.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var footer: some View {
        HStack {
            if terminationStatus != 0 {
                Text("Exit code: \(terminationStatus)")
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
}
