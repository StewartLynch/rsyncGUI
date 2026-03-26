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

struct ContentView: View {
    @State private var manager = RSyncManager()
    @State private var operation: RSyncOperation = .copy
    @State private var sourcePath = ""
    @State private var destinationPath = ""
    @State private var showConfirmation = false
    @State private var showResults = false
    @AppStorage("showConsole") private var showConsole: Bool = true

    private var canStart: Bool {
        !sourcePath.isEmpty &&
        (operation == .delete || !destinationPath.isEmpty) &&
        !manager.isRunning
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            operationPicker
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)

            Divider()

            pathSection
                .padding(.horizontal, 20)
                .padding(.vertical, 16)

            Divider()

            progressSection
                .padding(.horizontal, 20)
                .padding(.vertical, 14)

            Divider()

            consoleSection
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 8)

            actionBar
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
        }
        .frame(minWidth: 720, minHeight: 620)
        .confirmationDialog(
            operation.confirmationTitle,
            isPresented: $showConfirmation,
            titleVisibility: .visible
        ) {
            Button(operation.buttonLabel, role: .destructive) {
                startOperation()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(operation.confirmationMessage)
        }
        .sheet(isPresented: $showResults) {
            resultsSheet
        }
        .onChange(of: manager.state) { _, newState in
            if newState == .completed {
                showResults = true
            }
        }
        .onChange(of: showConsole) { _, newValue in
            manager.captureConsole = newValue
        }
        .onAppear {
            manager.captureConsole = showConsole
        }
    }

    // MARK: - Operation Picker

    private var operationPicker: some View {
        HStack(spacing: 12) {
            Text("Operation:")
                .fontWeight(.semibold)

            Picker("Operation", selection: $operation) {
                ForEach(RSyncOperation.allCases) { op in
                    Label(op.rawValue, systemImage: op.systemImage)
                        .tag(op)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            Spacer()

            stateIndicator
        }
    }

    @ViewBuilder
    private var stateIndicator: some View {
        switch manager.state {
        case .idle:
            EmptyView()
        case .running:
            Label("Running…", systemImage: "arrow.triangle.2.circlepath")
                .foregroundStyle(.orange)
                .symbolEffect(.rotate)
        case .completed:
            Label("Completed", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .cancelled:
            Label("Cancelled", systemImage: "xmark.circle.fill")
                .foregroundStyle(.secondary)
        case .failed:
            Label("Failed", systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
        }
    }

    // MARK: - Path Section

    /// Last path component of a path string (folder name).
    private func folderName(of path: String) -> String {
        URL(fileURLWithPath: path).lastPathComponent
    }

    /// True when Sync is active and the two folder names differ.
    private var syncFolderNameMismatch: Bool {
        guard operation == .sync,
              !sourcePath.isEmpty, !destinationPath.isEmpty else { return false }
        return folderName(of: sourcePath) != folderName(of: destinationPath)
    }

    private var pathSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            PathInputView(
                title: "Source:",
                path: $sourcePath,
                allowFiles: operation != .sync   // Sync requires a folder
            )

            if operation.requiresDestination {
                PathInputView(
                    title: operation.destinationLabel,
                    path: $destinationPath,
                    allowFiles: false,
                    helpText: operation.destinationHelp
                )
            }

            // Warn the user when syncing two folders that have different names —
            // that is almost always a mistake.
            if syncFolderNameMismatch {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("The source folder \"\(folderName(of: sourcePath))\" and sync target \"\(folderName(of: destinationPath))\" have different names. Make sure this is intentional — Sync will overwrite the target's contents.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(8)
                .background(Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
    }

    // MARK: - Progress Section

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Progress")
                    .fontWeight(.semibold)

                Spacer()

                if manager.totalFiles > 0 {
                    Text("\(manager.processedFiles) / \(manager.totalFiles) files")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .font(.callout)
                }

                if let pct = manager.progress {
                    Text("\(Int(pct * 100))%")
                        .monospacedDigit()
                        .fontWeight(.medium)
                        .frame(width: 40, alignment: .trailing)
                }
            }

            Group {
                if let progress = manager.progress {
                    ProgressView(value: progress)
                } else if manager.isRunning {
                    ProgressView()
                        .progressViewStyle(.linear)
                } else {
                    ProgressView(value: 0)
                        .opacity(0.25)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: manager.progress)
        }
    }

    // MARK: - Console Section

    private var consoleSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            // This VStack always claims all remaining vertical space so the
            // window content stays pinned to the top whether the scroll view
            // is visible or the collapsed placeholder is shown.
            HStack {
                Text("Console Output")
                    .fontWeight(.semibold)

                Spacer()

                // Toggle — persisted via @AppStorage so it survives relaunches
                Toggle(isOn: $showConsole) {
                    Label(
                        showConsole ? "Output On" : "Output Off",
                        systemImage: showConsole ? "terminal.fill" : "terminal"
                    )
                    .font(.caption)
                }
                .toggleStyle(.button)
                .buttonStyle(.borderless)
                .foregroundStyle(showConsole ? Color.accentColor : Color.secondary)
                .help(showConsole
                      ? "Hide console output (progress & errors still tracked)"
                      : "Show console output")
                .disabled(manager.isRunning)

                if showConsole && !manager.consoleOutput.isEmpty {
                    Button {
                        manager.consoleOutput = []
                    } label: {
                        Label("Clear", systemImage: "trash")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.secondary)
                    .disabled(manager.isRunning)
                }
            }

            if showConsole {
                ScrollViewReader { proxy in
                    ScrollView(.vertical) {
                        LazyVStack(alignment: .leading, spacing: 1) {
                            ForEach(Array(manager.consoleOutput.enumerated()), id: \.offset) { index, line in
                                Text(line)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundStyle(consoleColor(for: line))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .textSelection(.enabled)
                                    .id(index)
                            }
                        }
                        .padding(10)
                    }
                    .background(Color(nsColor: .textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.25), lineWidth: 1)
                    )
                    .frame(minHeight: 180, maxHeight: .infinity)
                    .onChange(of: manager.consoleOutput.count) { _, count in
                        guard count > 0 else { return }
                        withAnimation(.none) {
                            proxy.scrollTo(count - 1, anchor: .bottom)
                        }
                    }
                }
            } else {
                // Collapsed placeholder — keeps the layout stable
                HStack(spacing: 8) {
                    Image(systemName: "terminal")
                        .foregroundStyle(.secondary)
                    Text("Console output hidden — progress and errors are still tracked.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .padding(.horizontal, 12)
                .background(Color(nsColor: .textBackgroundColor).opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                )
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }

    // MARK: - Action Bar

    private var actionBar: some View {
        HStack(spacing: 12) {
            Button {
                if operation.requiresConfirmation {
                    showConfirmation = true
                } else {
                    startOperation()
                }
            } label: {
                Label(operation.buttonLabel, systemImage: operation.systemImage)
                    .frame(minWidth: 140)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canStart)
            .keyboardShortcut("r", modifiers: .command)

            Spacer()

            if manager.state == .completed {
                Button {
                    showResults = true
                } label: {
                    Label("View Results", systemImage: "list.bullet.rectangle")
                }
                .buttonStyle(.bordered)
            }

            if manager.isRunning {
                Button(role: .destructive) {
                    manager.cancel()
                } label: {
                    Label("Cancel", systemImage: "stop.circle.fill")
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .keyboardShortcut(".", modifiers: .command)
            }
        }
    }

    // MARK: - Results Sheet

    @ViewBuilder
    private var resultsSheet: some View {
        if operation == .compare {
            CompareResultsView(
                results: manager.compareResults,
                isPresented: $showResults
            )
        } else {
            OperationResultsView(
                operation: operation,
                errors: manager.errors,
                terminationStatus: manager.terminationStatus,
                isPresented: $showResults
            )
        }
    }

    // MARK: - Helpers

    private func startOperation() {
        Task {
            await manager.run(
                operation: operation,
                source: sourcePath,
                destination: destinationPath
            )
        }
    }

    private func consoleColor(for line: String) -> Color {
        if line.hasPrefix("❌") { return .red }
        if line.hasPrefix("⚠️") { return .orange }
        if line.hasPrefix("✅") { return .green }
        if line.hasPrefix("$") { return .accentColor }
        return .primary
    }
}

#Preview {
    ContentView()
}
