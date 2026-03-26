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

import Foundation
import Observation

enum RSyncState: Equatable {
    case idle
    case running
    case completed
    case cancelled
    case failed
}

@Observable
final class RSyncManager {
    var consoleOutput: [String] = []
    var progress: Double? = nil
    var totalFiles: Int = 0
    var processedFiles: Int = 0
    var state: RSyncState = .idle
    var errors: [String] = []
    var compareResults: [CompareResult] = []
    var terminationStatus: Int32 = 0

    /// When false, per-line output is skipped (progress + errors still work).
    var captureConsole: Bool = true

    private var currentProcess: Process?

    var isRunning: Bool { state == .running }

    // MARK: - Public API

    func run(
        operation: RSyncOperation,
        source: String,
        destination: String,
        flags: [CommandFlag]
    ) async {
        reset()
        state = .running

        let flagArgs = operation.activeArgFlags(from: flags)

        switch operation {

        case .copy:
            // No trailing slash on source → rsync recreates the named folder inside
            // the destination. --delete removes stale files already in dest/FolderName/.
            await executeRSync(
                arguments: flagArgs + [source.removingTrailingSlash, destination],
                operation: operation
            )

        case .move:
            // Same as copy + remove source files after transfer.
            await executeRSync(
                arguments: flagArgs + [source.removingTrailingSlash, destination],
                operation: operation
            )

        case .sync:
            // Trailing slash on BOTH paths: rsync syncs the *contents* of source
            // directly into destination, making them exact mirrors of each other.
            await executeRSync(
                arguments: flagArgs + [source.addingTrailingSlash, destination.addingTrailingSlash],
                operation: operation
            )

        case .compare:
            await executeRSync(
                arguments: flagArgs + [source.removingTrailingSlash, destination],
                operation: operation
            )

        case .delete:
            await executeDelete(path: source.removingTrailingSlash, flags: flagArgs)
        }
    }

    func cancel() {
        currentProcess?.terminate()
        state = .cancelled
        append("⚠️ Operation cancelled by user.")
    }

    // MARK: - Private Helpers

    private func reset() {
        consoleOutput = []
        progress = nil
        totalFiles = 0
        processedFiles = 0
        errors = []
        compareResults = []
        terminationStatus = 0
        currentProcess = nil
    }

    /// Appends a line to console output.
    /// Pass `force: true` for command echoes, status summaries, and errors that
    /// should always appear regardless of the captureConsole toggle.
    private func append(_ line: String, force: Bool = false) {
        guard captureConsole || force else { return }
        consoleOutput.append(line)
    }

    /// Bridges a FileHandle's readability events into an AsyncStream.
    /// The continuation is Sendable so the background handler can yield safely.
    private func makeStream(from handle: FileHandle) -> AsyncStream<String> {
        AsyncStream { continuation in
            handle.readabilityHandler = { h in
                let data = h.availableData
                if data.isEmpty {
                    continuation.finish()
                } else if let text = String(data: data, encoding: .utf8) {
                    continuation.yield(text)
                }
            }
            continuation.onTermination = { _ in
                handle.readabilityHandler = nil
            }
        }
    }

    private func resolvedRsyncPath() -> String {
        let homebrew = "/opt/homebrew/bin/rsync"
        return FileManager.default.fileExists(atPath: homebrew) ? homebrew : "/usr/bin/rsync"
    }

    // MARK: - rsync Execution

    private func executeRSync(arguments: [String], operation: RSyncOperation) async {
        let rsyncPath = resolvedRsyncPath()
        append("$ \(([rsyncPath] + arguments).joined(separator: " "))", force: true)

        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: rsyncPath)
        proc.arguments = arguments

        let outPipe = Pipe()
        let errPipe = Pipe()
        proc.standardOutput = outPipe
        proc.standardError = errPipe
        currentProcess = proc

        do {
            try proc.run()
        } catch {
            state = .failed
            errors.append(error.localizedDescription)
            append("❌ Failed to launch rsync: \(error.localizedDescription)", force: true)
            return
        }

        let outStream = makeStream(from: outPipe.fileHandleForReading)
        let errStream = makeStream(from: errPipe.fileHandleForReading)

        // Consume both streams concurrently on the main actor.
        // Each `await` in the for-loops yields the actor cooperatively.
        await withTaskGroup(of: Void.self) { group in
            group.addTask { @MainActor in
                for await chunk in outStream {
                    self.processOutput(chunk, operation: operation)
                }
            }
            group.addTask { @MainActor in
                for await chunk in errStream {
                    self.processError(chunk)
                }
            }
        }

        // Both pipes have hit EOF, meaning the process has exited.
        // waitUntilExit() returns immediately in this case.
        proc.waitUntilExit()
        terminationStatus = proc.terminationStatus

        guard state == .running else { return }
        progress = 1.0
        state = .completed

        switch terminationStatus {
        case 0:
            append("✅ Operation completed successfully.", force: true)
        case 23, 24:
            append("⚠️ Completed with warnings — some files may not have transferred.", force: true)
        default:
            append("⚠️ Completed with exit code \(terminationStatus).", force: true)
        }
    }

    // MARK: - Delete Execution

    private func executeDelete(path: String, flags: [String]) async {
        let displayArgs = (flags + ["\"\(path)\""]).joined(separator: " ")
        append("$ /bin/rm \(displayArgs)", force: true)

        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/bin/rm")
        proc.arguments = flags + [path]

        let outPipe = Pipe()
        let errPipe = Pipe()
        proc.standardOutput = outPipe
        proc.standardError = errPipe
        currentProcess = proc

        do {
            try proc.run()
        } catch {
            state = .failed
            errors.append(error.localizedDescription)
            append("❌ Failed to delete: \(error.localizedDescription)", force: true)
            return
        }

        let outStream = makeStream(from: outPipe.fileHandleForReading)
        let errStream = makeStream(from: errPipe.fileHandleForReading)

        await withTaskGroup(of: Void.self) { group in
            group.addTask { @MainActor in
                for await chunk in outStream {
                    for line in chunk.rsyncLines { self.append(line) }
                }
            }
            group.addTask { @MainActor in
                for await chunk in errStream {
                    self.processError(chunk)
                }
            }
        }

        proc.waitUntilExit()
        terminationStatus = proc.terminationStatus

        guard state == .running else { return }
        progress = 1.0
        state = .completed
        append(terminationStatus == 0
            ? "✅ Deletion completed successfully."
            : "⚠️ Deletion completed with exit code \(terminationStatus).",
               force: true)
    }

    // MARK: - Output Processing

    private func processOutput(_ chunk: String, operation: RSyncOperation) {
        for line in chunk.rsyncLines {
            if operation == .compare {
                append(line)
                parseCompareItem(line)
            } else {
                parseProgress(from: line)
                append(line)
            }
        }
    }

    private func processError(_ chunk: String) {
        for line in chunk.rsyncLines {
            errors.append(line)
            append("❌ \(line)", force: true)   // errors always surface in the console
        }
    }

    /// Parses the `to-chk=M/T` token from rsync --progress output to update overall progress.
    private func parseProgress(from line: String) {
        guard let range = line.range(of: #"to-chk=(\d+)/(\d+)"#, options: .regularExpression) else { return }
        let parts = line[range]
            .replacingOccurrences(of: "to-chk=", with: "")
            .components(separatedBy: "/")
        guard parts.count == 2,
              let remaining = Int(parts[0]),
              let total = Int(parts[1]),
              total > 0 else { return }
        totalFiles = total
        processedFiles = total - remaining
        progress = Double(processedFiles) / Double(total)
    }

    /// Parses an rsync --itemize-changes line into a CompareResult.
    private func parseCompareItem(_ line: String) {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        let skipPrefixes = ["sending", "total size", "sent ", "rcvd ", "Number of", "speedup", "bytes/sec"]
        guard !skipPrefixes.contains(where: { trimmed.lowercased().hasPrefix($0.lowercased()) }) else { return }

        guard let first = trimmed.first, "><ch.*".contains(first) else { return }

        let parts = trimmed.components(separatedBy: " ").filter { !$0.isEmpty }
        guard parts.count >= 2 else { return }

        let code = parts[0]
        let filePath = parts[1...].joined(separator: " ")

        let changeType: ChangeType
        if code.hasPrefix("*del") {
            changeType = .deleted
        } else if "><c".contains(String(first)) {
            changeType = code.contains("+") ? .newFile : .modified
        } else {
            changeType = .attributeChanged
        }

        compareResults.append(CompareResult(itemCode: code, path: filePath, changeType: changeType))
    }
}

// MARK: - String Helpers

private extension String {
    /// Splits a chunk of rsync output by newlines and carriage returns, dropping empties.
    var rsyncLines: [String] {
        replacingOccurrences(of: "\r", with: "\n")
            .split(separator: "\n", omittingEmptySubsequences: true)
            .map(String.init)
    }

    /// Returns the path without a trailing slash (preserves root "/").
    var removingTrailingSlash: String {
        guard hasSuffix("/"), count > 1 else { return self }
        return String(dropLast())
    }

    /// Returns the path with exactly one trailing slash.
    var addingTrailingSlash: String {
        hasSuffix("/") ? self : self + "/"
    }
}
