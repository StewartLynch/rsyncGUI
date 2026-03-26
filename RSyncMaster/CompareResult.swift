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

enum ChangeType: Equatable {
    case newFile
    case deleted
    case modified
    case attributeChanged

    var label: String {
        switch self {
        case .newFile:         return "New"
        case .deleted:         return "Deleted"
        case .modified:        return "Modified"
        case .attributeChanged: return "Changed"
        }
    }

    var systemImage: String {
        switch self {
        case .newFile:         return "plus.circle.fill"
        case .deleted:         return "minus.circle.fill"
        case .modified:        return "pencil.circle.fill"
        case .attributeChanged: return "gear.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .newFile:         return .green
        case .deleted:         return .red
        case .modified:        return .orange
        case .attributeChanged: return .blue
        }
    }
}

struct CompareResult: Identifiable {
    let id = UUID()
    let itemCode: String
    let path: String
    let changeType: ChangeType
}
