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

// MARK: - Command Info Model

struct CommandToken: Identifiable {
    let id = UUID()
    /// The token as it appears in the command (e.g. `-a`, `--delete`, `<source>`).
    let token: String
    /// Plain-English explanation of what this token does.
    let explanation: String
}

struct CommandInfo {
    /// The full command string shown verbatim (with `<source>` / `<destination>` placeholders).
    let command: String
    /// Ordered list of tokens and their explanations.
    let tokens: [CommandToken]
}

// MARK: -

enum RSyncOperation: String, CaseIterable, Identifiable {
    case copy    = "Copy"
    case move    = "Move"
    case sync    = "Sync"
    case delete  = "Delete"
    case compare = "Compare"

    var id: String { rawValue }

    // MARK: Behaviour flags

    /// Operations that show a confirmation dialog before running.
    var requiresConfirmation: Bool {
        switch self {
        case .copy, .move, .sync, .delete: return true
        case .compare:                     return false
        }
    }

    /// Operations that need a destination path field.
    var requiresDestination: Bool { self != .delete }

    /// For Sync the destination IS the peer folder (not a parent).
    /// For Copy / Move the destination is the parent that will contain the source folder.
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
        case .move:    return "arrow.right.square.fill"
        case .sync:    return "arrow.left.arrow.right.square.fill"
        case .delete:  return "trash.fill"
        case .compare: return "arrow.triangle.2.circlepath"
        }
    }

    // MARK: - Command Info

    var commandInfo: CommandInfo {
        switch self {

        case .copy:
            return CommandInfo(
                command: "rsync -av --delete --progress \\\n    <source> <destination>",
                tokens: [
                    .init(token: "rsync",
                          explanation: "The rsync program — a fast, versatile file-copying tool that uses a delta-transfer algorithm to send only the parts of a file that have changed."),
                    .init(token: "-a",
                          explanation: "Archive mode. Shorthand for -rlptgoD: recursively copies directories and preserves symbolic links, file permissions, modification timestamps, owner, and group."),
                    .init(token: "-v",
                          explanation: "Verbose. Prints the name of each file as it is transferred so you can follow exactly what rsync is doing."),
                    .init(token: "--delete",
                          explanation: "Deletes files at the destination that no longer exist in the source, so the destination ends up as an exact match of the source."),
                    .init(token: "--progress",
                          explanation: "Displays per-file transfer speed and a running file count in the form to-chk=M/T (M files remaining of T total). RSyncMaster uses this to drive the progress bar."),
                    .init(token: "<source>",
                          explanation: "The file or folder to copy. No trailing slash is added, so rsync recreates the named item itself inside the destination folder."),
                    .init(token: "<destination>",
                          explanation: "The parent folder that will receive the copied item. The source folder will appear as a sub-folder inside this path."),
                ]
            )

        case .move:
            return CommandInfo(
                command: "rsync -av --delete --progress \\\n    --remove-source-files \\\n    <source> <destination>",
                tokens: [
                    .init(token: "rsync",
                          explanation: "The rsync program — performs the transfer then handles source-file removal."),
                    .init(token: "-a",
                          explanation: "Archive mode. Recursively copies directories and preserves symbolic links, permissions, timestamps, owner, and group."),
                    .init(token: "-v",
                          explanation: "Verbose. Prints the name of each file as it is transferred."),
                    .init(token: "--delete",
                          explanation: "Removes files at the destination that no longer exist in the source, keeping the destination an exact match."),
                    .init(token: "--progress",
                          explanation: "Shows per-file progress and a to-chk=M/T file counter used by the progress bar."),
                    .init(token: "--remove-source-files",
                          explanation: "Deletes each source file after it has been successfully transferred. Note: rsync does not remove the source directory structure itself — only the files inside it."),
                    .init(token: "<source>",
                          explanation: "The file or folder to move. No trailing slash, so rsync recreates the named folder inside the destination."),
                    .init(token: "<destination>",
                          explanation: "The parent folder that will receive the moved item."),
                ]
            )

        case .sync:
            return CommandInfo(
                command: "rsync -av --delete --progress \\\n    <source>/ <destination>/",
                tokens: [
                    .init(token: "rsync",
                          explanation: "The rsync program — makes two directories identical."),
                    .init(token: "-a",
                          explanation: "Archive mode. Recursively copies directories and preserves symbolic links, permissions, timestamps, owner, and group."),
                    .init(token: "-v",
                          explanation: "Verbose. Prints the name of each file as it is transferred."),
                    .init(token: "--delete",
                          explanation: "Removes files in the destination that do not exist in the source, making the destination a true mirror of the source."),
                    .init(token: "--progress",
                          explanation: "Shows per-file progress and the to-chk=M/T counter used by the progress bar."),
                    .init(token: "<source>/",
                          explanation: "Trailing slash tells rsync to sync the contents of the source folder rather than the folder itself. Without this slash, rsync would nest the source folder inside the destination instead of merging them."),
                    .init(token: "<destination>/",
                          explanation: "Trailing slash on the destination, combined with the trailing slash on the source, causes rsync to treat both paths as the same logical folder and keep them perfectly in sync."),
                ]
            )

        case .delete:
            return CommandInfo(
                command: "/bin/rm -rfv <source>",
                tokens: [
                    .init(token: "/bin/rm",
                          explanation: "The standard Unix remove command. rsync is not used here because it requires both a source and a destination; rm directly and permanently removes the specified path."),
                    .init(token: "-r",
                          explanation: "Recursive. Removes directories and all of their contents, descending into sub-folders no matter how deep."),
                    .init(token: "-f",
                          explanation: "Force. Suppresses any confirmation prompts and silently ignores files that do not exist, so the command never stalls waiting for input."),
                    .init(token: "-v",
                          explanation: "Verbose. Prints each file name as it is removed so you can see exactly what is being deleted."),
                    .init(token: "<source>",
                          explanation: "The file or folder to permanently delete. This action cannot be undone — the item is not moved to the Trash."),
                ]
            )

        case .compare:
            return CommandInfo(
                command: "rsync -avn --itemize-changes \\\n    <source> <destination>",
                tokens: [
                    .init(token: "rsync",
                          explanation: "The rsync program — used here purely as a comparison engine, not to transfer any data."),
                    .init(token: "-a",
                          explanation: "Archive mode. Ensures rsync compares directories recursively and considers all metadata (permissions, timestamps, etc.) when deciding whether files differ."),
                    .init(token: "-v",
                          explanation: "Verbose. Includes extra summary lines (file counts, transfer size) in the output."),
                    .init(token: "-n",
                          explanation: "Dry-run mode. rsync calculates what would be transferred but makes absolutely no changes to disk. Safe to run as many times as you like."),
                    .init(token: "--itemize-changes",
                          explanation: "Outputs an 11-character change code for every file that differs — for example >f+++++++++ new.txt. RSyncMaster parses these codes to build the colour-coded New / Modified / Deleted / Changed results table."),
                    .init(token: "<source>",
                          explanation: "The reference folder whose contents are compared against the destination."),
                    .init(token: "<destination>",
                          explanation: "The folder being compared. Nothing is written here — the comparison is read-only."),
                ]
            )
        }
    }
}
