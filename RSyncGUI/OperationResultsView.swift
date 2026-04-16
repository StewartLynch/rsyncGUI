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

struct OperationResultsView: View {
    let operation: RSyncOperation
    let errors: [String]
    let terminationStatus: Int32
    @Binding var isPresented: Bool

    private var isSuccess: Bool { terminationStatus == 0 }
    private var hasWarnings: Bool { !isSuccess && errors.isEmpty }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if isSuccess && errors.isEmpty {
                successBody
            } else if hasWarnings {
                warningBody
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
            Image(systemName: headerSymbolName)
                .font(.system(size: 44))
                .foregroundStyle(headerColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(headerTitle)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(headerMessage)
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

    private var warningBody: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.orange.opacity(0.8))
            Text("The operation finished with warnings.")
                .fontWeight(.semibold)
            Text("Review the exit code and console output for details about any skipped or partially transferred files.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 360)
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

    private var headerSymbolName: String {
        if isSuccess {
            "checkmark.circle.fill"
        } else if hasWarnings {
            "exclamationmark.triangle.fill"
        } else {
            "xmark.octagon.fill"
        }
    }

    private var headerColor: Color {
        if isSuccess {
            .green
        } else if hasWarnings {
            .orange
        } else {
            .red
        }
    }

    private var headerTitle: String {
        if isSuccess {
            "\(operation.rawValue) Complete"
        } else if hasWarnings {
            "\(operation.rawValue) Completed With Warnings"
        } else {
            "\(operation.rawValue) Failed"
        }
    }

    private var headerMessage: String {
        if isSuccess {
            "The \(operation.rawValue.lowercased()) operation finished with no errors."
        } else if hasWarnings {
            "The operation exited with a warning status but did not report stderr output."
        } else {
            "The operation failed with \(errors.count) error\(errors.count == 1 ? "" : "s")."
        }
    }
}
