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
}
