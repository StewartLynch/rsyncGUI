# RSyncMaster

A native macOS SwiftUI application that puts a clean, powerful GUI on top of **rsync** — no Terminal required.

---

## Features

| Operation | What it does |
|-----------|-------------|
| **Copy** | Copies a file or folder to a destination. The named folder is recreated inside the destination. Stale files already at the destination are removed so the copy is an exact match. |
| **Move** | Same as Copy, but the original source is permanently removed after a successful transfer. |
| **Sync** | Makes two identically-named folders exact mirrors of each other. Files in the destination that no longer exist in the source are deleted. |
| **Delete** | Permanently deletes the source file or folder. |
| **Compare** | Performs a dry-run diff between source and destination and presents the differences in a filterable, colour-coded table — nothing is written to disk. |

### Additional highlights

- **Drag & drop** paths directly onto the Source / Destination fields, or type them, or use the **Browse (…)** button to open a file-picker panel.
- **Live console output** shows the exact rsync / rm command being run and every line it produces.
- **Console toggle** — turn off live output for large transfers where scrolling overhead would slow things down; the progress bar continues to update regardless.
- **Progress bar** with file counter derived from rsync's `to-chk=M/T` token.
- **Cancel button** terminates the running process at any time.
- **Confirmation dialogs** on Copy, Move, Sync, and Delete so you never accidentally nuke something.
- **Results sheet** after Copy / Move / Sync / Delete showing success or a list of errors.
- **Compare results view** with filter chips (New / Modified / Deleted / Changed) and colour-coded badges, backed by rsync's `--itemize-changes` format.
- Automatically prefers the **Homebrew rsync** at `/opt/homebrew/bin/rsync` (version 3.x) over the ancient system rsync (2.6.9) when available.

---

## Requirements

- **macOS 26** (Tahoe) or later
- **Xcode 16** or later
- **rsync** — the system copy works, but for best results install a modern version via [Homebrew](https://brew.sh):
  ```
  brew install rsync
  ```

---

## Building & Running

1. Clone or download the repository.
2. Open **`RSyncMaster.xcodeproj`** in Xcode 16+.
3. Select the **RSyncMaster** scheme and your Mac as the run destination.
4. Press **⌘R** to build and run.

No Swift packages or external dependencies are required — the project builds out of the box.

---

## How to Use

### Selecting an Operation
Use the segmented picker at the top of the window to choose **Copy**, **Move**, **Sync**, **Delete**, or **Compare**.

### Entering Paths
- **Type** a path directly into the Source or Destination field.
- **Drag** a file or folder from Finder and drop it onto either field.
- Click the **…** button to open a standard macOS Open Panel.

> **Note:** The Source accepts both files and folders for Copy / Move / Delete / Compare. Sync requires folders. The Destination always requires a folder. For Delete, no Destination is needed.

### Running an Operation
Click **Start [Operation]**. For Copy, Move, Sync, and Delete a confirmation dialog appears first — read it carefully, then confirm.

### Monitoring Progress
- The **progress bar** tracks how many files have been processed.
- The **console pane** shows rsync's live output. Toggle it off with the **Show Console** switch if you prefer a cleaner view during large transfers; errors and status messages always appear regardless.

### Cancelling
Click **Cancel** at any time to terminate the running process immediately.

### Reviewing Results
- After **Copy / Move / Sync / Delete** a results sheet appears confirming success or listing any errors.
- After **Compare** a dedicated results view opens with a filterable table of differences:
  - 🟢 **New** — file exists in source but not in destination
  - 🟠 **Modified** — file content has changed
  - 🔴 **Deleted** — file exists in destination but not in source
  - 🔵 **Changed** — metadata / attributes differ (permissions, timestamps, etc.)

---

## rsync Command Reference

| Operation | Command issued |
|-----------|---------------|
| Copy | `rsync -av --delete --progress <source> <destination>` |
| Move | `rsync -av --delete --progress --remove-source-files <source> <destination>` |
| Sync | `rsync -av --delete --progress <source>/ <destination>/` |
| Compare | `rsync -avn --itemize-changes <source> <destination>` |
| Delete | `/bin/rm -rfv <source>` |

> The trailing-slash convention is handled automatically — you don't need to worry about it.

---

## Architecture

```
RSyncMasterApp.swift      App entry point (WindowGroup → ContentView)
ContentView.swift         Main window — layout and UI state coordination
PathInputView.swift       Reusable path input field (type / browse / drag-drop)
RSyncManager.swift        @Observable class — all process lifecycle, progress parsing,
                          AsyncStream bridging, output processing
RSyncOperation.swift      Enum of the five operations with associated labels,
                          confirmations, and SF Symbol names
CompareResult.swift       Model: ChangeType enum + CompareResult struct
CompareResultsView.swift  Filterable table for diff results
OperationResultsView.swift  Sheet showing completion status and errors
```

**Key design choices:**

- `RSyncManager` is `@Observable` and implicitly `@MainActor` (via `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`).
- `FileHandle.readabilityHandler` callbacks are bridged to the main actor through `AsyncStream`, keeping UI updates safe with no manual `DispatchQueue.main` calls.
- `withTaskGroup` drains stdout and stderr concurrently, preventing either pipe from blocking the process.

---

## Entitlements & Sandbox

The **App Sandbox is disabled** (`ENABLE_APP_SANDBOX = NO`). This is intentional — sandboxed apps cannot spawn arbitrary subprocesses (`rsync`, `rm`) or access paths outside a narrow security scope without constant permission prompts.

The app uses the **Hardened Runtime**. No additional entitlements are required for personal / local use.

> ⚠️ Because the sandbox is off, **this app cannot be submitted to the Mac App Store**.
> For personal productivity and power-user workflows it works perfectly as a locally signed or ad-hoc distributed app.

---

## Author

**Stewart Lynch** — CreaTECH Solutions

- 🐘 Mastodon: [@StewartLynch@iosdev.space](https://iosdev.space/@StewartLynch)
- 🧵 Threads: [@stewartlynch](https://www.threads.net/@stewartlynch)
- 🦋 Bluesky: [@stewartlynch.bsky.social](https://bsky.app/profile/stewartlynch.bsky.social)
- 🐦 X / Twitter: [@StewartLynch](https://x.com/StewartLynch)
- 💼 LinkedIn: [in/StewartLynch](https://linkedin.com/in/StewartLynch)
- 📺 YouTube: [@StewartLynch](https://youTube.com/@StewartLynch)
- ☕ Ko-fi: [ko-fi.com/StewartLynch](https://ko-fi.com/StewartLynch)
- 📧 Email: slynch@createchsol.com

---

## License

Copyright © 2026 CreaTECH Solutions (Stewart Lynch). All rights reserved.
