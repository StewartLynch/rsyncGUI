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

struct CommandInfoView: View {
    let operation: RSyncOperation

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Header ────────────────────────────────────────────────────
            HStack(spacing: 10) {
                Image(systemName: operation.systemImage)
                    .font(.title3)
                    .foregroundStyle(.tint)
                Text("\(operation.rawValue) — Command Reference")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 14)

            Divider()

            // ── Full command ──────────────────────────────────────────────
            VStack(alignment: .leading, spacing: 6) {
                Text("Command")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                Text(operation.commandInfo.command)
                    .font(.system(.callout, design: .monospaced))
                    .foregroundStyle(.primary)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(nsColor: .textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 7)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
                    .textSelection(.enabled)
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 12)

            Divider()

            // ── Token table ───────────────────────────────────────────────
            VStack(alignment: .leading, spacing: 6) {
                Text("Flags & Arguments")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .padding(.bottom, 4)

                ForEach(operation.commandInfo.tokens) { token in
                    TokenRow(token: token)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 20)
        }
        .frame(width: 460)
    }
}

// MARK: - Token Row

private struct TokenRow: View {
    let token: CommandToken

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(token.token)
                .font(.system(.caption, design: .monospaced))
                .fontWeight(.semibold)
                .foregroundStyle(.tint)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(Color.accentColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .frame(minWidth: 90, alignment: .leading)
                // Fixed width so all explanations align regardless of token length
                .fixedSize()

            Text(token.explanation)
                .font(.callout)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 3)
    }
}

// MARK: - Preview

#Preview {
    CommandInfoView(operation: .copy)
        .padding()
}
