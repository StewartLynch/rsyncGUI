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

import Foundation

// MARK: - Command Flag Model

/// Represents a single token in an rsync / rm command.
///
/// - Flags that appear in the checkbox UI have `isHidden == false`.
/// - The program name (`rsync`, `/bin/rm`) and positional arguments
///   (`<source>`, `<destination>`) have `isHidden == true` — they are shown
///   in the popover token table but never in the checkbox list.
/// - `isRequired == true` flags are always included; their checkboxes are
///   visible but disabled.
struct CommandFlag: Identifiable {
    let id = UUID()
    /// The string used in the command (e.g. `-a`, `--delete`, `<source>`).
    let token: String
    /// Plain-English explanation shown in the command info popover.
    let explanation: String
    /// Whether this flag is currently active.
    var isEnabled: Bool
    /// Always included; the checkbox is shown but disabled.
    let isRequired: Bool
    /// Not shown in the checkbox row (program name or positional argument).
    let isHidden: Bool

    init(
        token: String,
        explanation: String,
        isEnabled: Bool = true,
        isRequired: Bool = false,
        isHidden: Bool = false
    ) {
        self.token = token
        self.explanation = explanation
        self.isEnabled = isEnabled
        self.isRequired = isRequired
        self.isHidden = isHidden
    }
}

// MARK: -

enum rsyncOperation: String, CaseIterable, Identifiable {
    case copy    = "Copy"
    case move    = "Move"
    case sync    = "Sync"
    case delete  = "Delete"
    case compare = "Compare"

    var id: String { rawValue }

    // MARK: Behaviour flags

    var requiresConfirmation: Bool {
        switch self {
        case .copy, .move, .sync, .delete: return true
        case .compare:                     return false
        }
    }

    var requiresDestination: Bool { self != .delete }

    var destinationIsPeerFolder: Bool { self == .sync }

    // MARK: UI strings

    var confirmationTitle: String { "Confirm \(rawValue)" }

    var confirmationMessage: String {
        switch self {
        case .copy:
            return "Any existing copy of the source at the destination will be completely replaced. Files in the destination folder that are no longer in the source will be deleted."
        case .move:
            return "The source will be moved to the destination. Any existing copy will be completely replaced and the original source files will be permanently removed."
        case .sync:
            return "The destination folder will be made an exact mirror of the source folder. Files in the destination that do not exist in the source will be permanently deleted."
        case .delete:
            return "This will permanently delete the source path and all its contents. This action cannot be undone."
        case .compare:
            return ""
        }
    }

    var destinationLabel: String {
        destinationIsPeerFolder ? "Sync Target:" : "Destination:"
    }

    var destinationHelp: String {
        destinationIsPeerFolder
            ? "The folder whose contents will be made identical to the source."
            : "The parent folder that will receive the source item."
    }

    var buttonLabel: String { "Start \(rawValue)" }

    var systemImage: String {
        switch self {
        case .copy:    return "doc.on.doc.fill"
        case .move:    return "arrow.right.circle.fill"
        case .sync:    return "arrow.left.arrow.right.square.fill"
        case .delete:  return "trash.fill"
        case .compare: return "arrow.triangle.2.circlepath"
        }
    }

    // MARK: - Default Flags

    /// The canonical ordered flag list for this operation.
    /// Hidden tokens (program name + positional args) are included so the
    /// popover can show the complete annotated command.
    var defaultFlags: [CommandFlag] {
        switch self {

        case .copy:
            return [
                .init(token: "rsync",
                      explanation: "The rsync program — a fast, versatile file-copying tool that uses a delta-transfer algorithm to send only the parts of a file that have changed.",
                      isRequired: true, isHidden: true),
                .init(token: "-a",
                      explanation: "Archive mode. Shorthand for -rlptgoD: recursively copies directories and preserves symbolic links, file permissions, modification timestamps, owner, and group.",
                      isRequired: true),
                .init(token: "-v",
                      explanation: "Verbose. Prints the name of each file as it is transferred so you can follow exactly what rsync is doing."),
                .init(token: "--delete",
                      explanation: "Deletes files at the destination that no longer exist in the source, so the destination ends up as an exact match of the source."),
                .init(token: "--progress",
                      explanation: "Displays per-file transfer speed and a running file count in the form to-chk=M/T. rsyncGUI uses this token to drive the progress bar — disabling it switches the bar to indeterminate mode."),
                .init(token: "<source>",
                      explanation: "The file or folder to copy. No trailing slash, so rsync recreates the named item itself inside the destination folder.",
                      isRequired: true, isHidden: true),
                .init(token: "<destination>",
                      explanation: "The parent folder that will receive the copied item. The source folder appears as a sub-folder inside this path.",
                      isRequired: true, isHidden: true),
            ]

        case .move:
            return [
                .init(token: "rsync",
                      explanation: "The rsync program — performs the transfer then handles source-file removal.",
                      isRequired: true, isHidden: true),
                .init(token: "-a",
                      explanation: "Archive mode. Recursively copies directories and preserves symbolic links, permissions, timestamps, owner, and group.",
                      isRequired: true),
                .init(token: "-v",
                      explanation: "Verbose. Prints the name of each file as it is transferred."),
                .init(token: "--delete",
                      explanation: "Removes files at the destination that no longer exist in the source, keeping the destination an exact match."),
                .init(token: "--progress",
                      explanation: "Shows per-file progress and a to-chk=M/T file counter used by the progress bar."),
                .init(token: "--remove-source-files",
                      explanation: "Deletes each source file after it has been successfully transferred. This is what makes the operation a move. Note: rsync leaves the empty source directory structure in place.",
                      isRequired: true),
                .init(token: "<source>",
                      explanation: "The file or folder to move. No trailing slash, so rsync recreates the named folder inside the destination.",
                      isRequired: true, isHidden: true),
                .init(token: "<destination>",
                      explanation: "The parent folder that will receive the moved item.",
                      isRequired: true, isHidden: true),
            ]

        case .sync:
            return [
                .init(token: "rsync",
                      explanation: "The rsync program — used to make two directories identical.",
                      isRequired: true, isHidden: true),
                .init(token: "-a",
                      explanation: "Archive mode. Recursively copies directories and preserves symbolic links, permissions, timestamps, owner, and group.",
                      isRequired: true),
                .init(token: "-v",
                      explanation: "Verbose. Prints the name of each file as it is transferred."),
                .init(token: "--delete",
                      explanation: "Removes files in the destination that do not exist in the source, making the destination a true mirror of the source. Without this flag Sync becomes a one-way copy only."),
                .init(token: "--progress",
                      explanation: "Shows per-file progress and the to-chk=M/T counter used by the progress bar."),
                .init(token: "<source>/",
                      explanation: "Trailing slash tells rsync to sync the contents of the source folder rather than the folder itself. Without this slash, rsync would nest the source folder inside the destination.",
                      isRequired: true, isHidden: true),
                .init(token: "<destination>/",
                      explanation: "Trailing slash on the destination causes rsync to treat both paths as the same logical folder and keep them perfectly in sync.",
                      isRequired: true, isHidden: true),
            ]

        case .delete:
            return [
                .init(token: "/bin/rm",
                      explanation: "The standard Unix remove command. rsync is not used for Delete because it requires a destination; rm directly and permanently removes the specified path.",
                      isRequired: true, isHidden: true),
                .init(token: "-r",
                      explanation: "Recursive. Removes directories and all of their contents, descending into sub-folders no matter how deep.",
                      isRequired: true),
                .init(token: "-f",
                      explanation: "Force. Suppresses confirmation prompts and silently ignores files that do not exist, so the command never stalls waiting for input."),
                .init(token: "-v",
                      explanation: "Verbose. Prints each file name as it is removed so you can see exactly what is being deleted."),
                .init(token: "<source>",
                      explanation: "The file or folder to permanently delete. This action cannot be undone — the item is not moved to the Trash.",
                      isRequired: true, isHidden: true),
            ]

        case .compare:
            return [
                .init(token: "rsync",
                      explanation: "The rsync program — used here purely as a comparison engine; no data is transferred.",
                      isRequired: true, isHidden: true),
                .init(token: "-a",
                      explanation: "Archive mode. Ensures rsync compares directories recursively and considers all metadata (permissions, timestamps, etc.) when deciding whether files differ.",
                      isRequired: true),
                .init(token: "-v",
                      explanation: "Verbose. Includes extra summary lines (file counts, transfer size) in the output."),
                .init(token: "-n",
                      explanation: "Dry-run mode. rsync calculates what would be transferred but makes absolutely no changes to disk. This flag must stay on to keep Compare safe.",
                      isRequired: true),
                .init(token: "--itemize-changes",
                      explanation: "Outputs an 11-character change code for every file that differs (e.g. >f+++++++++ new.txt). rsyncGUI parses these codes to build the colour-coded results table.",
                      isRequired: true),
                .init(token: "<source>",
                      explanation: "The reference folder whose contents are compared against the destination.",
                      isRequired: true, isHidden: true),
                .init(token: "<destination>",
                      explanation: "The folder being compared. Nothing is written here — the comparison is completely read-only.",
                      isRequired: true, isHidden: true),
            ]
        }
    }

    /// A ready-to-use dictionary of default flag configs for all operations.
    static var defaultFlagConfigs: [rsyncOperation: [CommandFlag]] {
        Dictionary(uniqueKeysWithValues: allCases.map { ($0, $0.defaultFlags) })
    }

    // MARK: - Command Display

    /// Builds the annotated command string shown in the popover, using the
    /// current enabled/disabled state of each flag.
    func buildDisplayCommand(from flags: [CommandFlag]) -> String {
        // Program is the first hidden, non-placeholder token
        let program = flags.first { $0.isHidden && !$0.token.hasPrefix("<") }?.token ?? "rsync"
        // Active (non-hidden) flags in declaration order
        let activeFlags = flags.filter { !$0.isHidden && $0.isEnabled }.map(\.token)
        // Positional placeholders always come last
        let args = flags.filter { $0.isHidden && $0.token.hasPrefix("<") }.map(\.token)
        return ([program] + activeFlags + args).joined(separator: " ")
    }

    /// The flag strings (non-hidden, enabled) to pass as Process arguments.
    /// Source and destination are handled separately by rsyncManager.
    func activeArgFlags(from flags: [CommandFlag]) -> [String] {
        flags.filter { !$0.isHidden && $0.isEnabled }.map(\.token)
    }
}
