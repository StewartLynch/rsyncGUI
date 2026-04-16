//
//----------------------------------------------
// Original project: RSyncGUI
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
    /// Live flag state — passed from ContentView so the command updates
    /// as the user checks / unchecks options.
    let flags: [CommandFlag]

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

            // ── Live command ──────────────────────────────────────────────
            VStack(alignment: .leading, spacing: 6) {
                Text("Command")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                Text(operation.buildDisplayCommand(from: flags))
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
                    .animation(.easeInOut(duration: 0.2), value: operation.buildDisplayCommand(from: flags))
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

                ForEach(flags) { flag in
                    TokenRow(flag: flag)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 20)
        }
        .frame(width: 480)
    }
}

// MARK: - Token Row

private struct TokenRow: View {
    let flag: CommandFlag

    /// Disabled non-required flags are dimmed and struck through to show
    /// they have been removed from the active command.
    private var isDisabledByUser: Bool {
        !flag.isHidden && !flag.isRequired && !flag.isEnabled
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Badge
            HStack(spacing: 4) {
                Text(flag.token)
                    .font(.system(.caption, design: .monospaced))
                    .fontWeight(.semibold)
                    .strikethrough(isDisabledByUser)
                if flag.isRequired && !flag.isHidden {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 7))
                }
            }
            .foregroundStyle(isDisabledByUser ? Color.secondary : Color.accentColor)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(
                isDisabledByUser
                    ? Color.secondary.opacity(0.08)
                    : Color.accentColor.opacity(0.10)
            )
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .frame(minWidth: 96, alignment: .leading)
            .fixedSize()

            // Explanation
            VStack(alignment: .leading, spacing: 2) {
                Text(flag.explanation)
                    .font(.callout)
                    .foregroundStyle(isDisabledByUser ? Color.secondary : Color.primary)
                    .fixedSize(horizontal: false, vertical: true)

                if isDisabledByUser {
                    Text("Disabled — not included in the command")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(.vertical, 3)
        .animation(.easeInOut(duration: 0.2), value: isDisabledByUser)
    }
}

// MARK: - Preview

#Preview {
    CommandInfoView(
        operation: .copy,
        flags: RSyncOperation.copy.defaultFlags
    )
    .padding()
}
