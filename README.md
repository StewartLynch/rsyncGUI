# rsyncGUI

A native macOS GUI front-end for `rsync` (and `rm`), built entirely with SwiftUI and Swift Concurrency. rsyncGUI makes common file operations — copying, moving, syncing, deleting, and comparing files or folders — accessible through a clean, self-documenting interface without ever opening a Terminal window.

---

## Download

Download the latest signed installer DMG from the [GitHub Releases page](https://github.com/StewartLynch/rsyncGUI/releases/latest).

Look for the release asset named **`rsyncGUI.Install.dmg`**.

---

## Features

### Five Operations

| Operation | What it does | Underlying command |
|-----------|-------------|-------------------|
| **Copy** | Copies a file or folder to a destination, recreating the named item inside the target folder. Removes stale files already present at the destination. | `rsync -av --delete --progress` |
| **Move** | Like Copy, but permanently removes source files after a successful transfer. | `rsync -av --delete --progress --remove-source-files` |
| **Sync** | Makes two same-named folders identical. Uses trailing slashes so rsync merges the *contents* of both paths rather than nesting one inside the other. | `rsync -av --delete --progress <src>/ <dst>/` |
| **Delete** | Permanently deletes the source path and all its contents. Uses `/bin/rm` because rsync requires a destination. | `/bin/rm -rfv` |
| **Compare** | Dry-run comparison — no files are transferred. Produces a detailed, colour-coded results table. | `rsync -avn --itemize-changes` |

### Configurable Flags

Below the operation picker, every optional and required flag for the current operation is displayed as a row of checkboxes. Required flags (e.g. `-a`, `-n`, `--itemize-changes`, `--remove-source-files`) are visible but locked — their checkboxes are disabled to prevent breaking the operation. Optional flags (e.g. `-v`, `--delete`, `--progress`) can be toggled freely before you start. Flag configuration is per-operation and held for the session.

### Live Command Reference Popover

Press the **ⓘ** button beside the operation picker to open an inline popover showing:

- The **exact command** that will run, updated in real time as you check or uncheck flags in the UI.
- An annotated **Flags & Arguments** table explaining every token — the program name, each flag, and each positional argument — in plain English. Disabled flags are dimmed and struck through so you can see at a glance exactly what has been removed from the active command.

### Path Input

Each path field supports two input methods:

- **Drag & drop** a file or folder from Finder onto the field. Dropping replaces the entire current path rather than appending text into the field.
- **Browse** using an `NSOpenPanel` file picker (the folder icon button).

The **Source** field accepts both files and folders (except for Sync, which requires a folder). The **Destination / Sync Target** field always requires a real folder. Finder packages such as `.app` bundles are treated as files and are rejected for folder-only targets. When Delete is selected, only the Source field is shown.

The **Start** button stays disabled until the current paths are valid for the selected operation, and a **Reset** button clears the paths, console output, progress, and any current results state.

A warning banner appears automatically when Sync is selected and the two folder names differ — a common sign of a mistaken path that would overwrite the wrong location.

### Console Output

A scrollable, auto-scrolling monospace console shows the live output of the running command. Lines are colour-coded:

| Colour | Meaning |
|--------|---------|
| Accent | The command that was executed (`$` prefix) |
| Green  | Success messages (`✅`) |
| Orange | Warnings (`⚠️`) |
| Red    | Errors (`❌`) |

Console output can be toggled off with the **Output On/Off** button. Progress tracking and error collection always continue in the background regardless of this setting.

### Progress Tracking

A `ProgressView` bar sits above the console and updates in real time by parsing rsync's `to-chk=M/T` token. A file counter (`processed / total`) is shown alongside a percentage. When `--progress` is disabled via the flag checkboxes, the bar switches to indeterminate (spinner) mode automatically.

### Confirmation Dialogs

Copy, Move, Sync, and Delete all require confirmation before the operation starts. Each dialog describes exactly what will happen — including the irreversible consequences for Move, Sync, and Delete — so there are no surprises.

### Results Views

**Copy / Move / Sync / Delete** — a sheet reports success, warnings, or failure details based on the command's exit status and any collected stderr output.

**Compare** — a rich results sheet with:
- A header showing the total number of differences found (or a "No Differences Found" badge if the folders are identical).
- Scrollable filter chips: **All**, **New**, **Modified**, **Deleted**, **Changed** — each labelled with its count.
- A searchable `Table` with a colour-coded change badge, a selectable monospaced file path, and the raw rsync itemize code.

---

## Requirements

- **macOS 26** or later
- **Xcode 16** or later
- No Swift Package dependencies — the project builds out of the box

**Recommended:** [Homebrew rsync](https://formulae.brew.sh/formula/rsync) installed at `/opt/homebrew/bin/rsync`. rsyncGUI automatically prefers it over the system-bundled rsync 2.6.9. If Homebrew rsync is not found, rsyncGUI falls back to `/usr/bin/rsync` silently.

```
brew install rsync
```

---

## Building & Running

1. Clone or download the repository.
2. Open **`rsyncGUI.xcodeproj`** in Xcode 16+.
3. Select the **rsyncGUI** scheme and your Mac as the destination.
4. Press **⌘R** to build and run.

---

## How to Use

### 1 — Choose an Operation

Use the segmented picker at the top of the window to select **Copy**, **Move**, **Sync**, **Delete**, or **Compare**.

### 2 — Configure Flags (optional)

The **Options** row beneath the picker shows checkboxes for every flag belonging to the selected operation. The defaults are sensible for most tasks; uncheck any optional flag you don't need. Hover over a checkbox to read a tooltip explaining what that flag does. Press **ⓘ** to open the live command popover and see the exact command that will be built from your current choices.

### 3 — Enter Paths

- **Drag** a file or folder from Finder and drop it on either field; the drop replaces the whole path.
- Click the folder button to browse with an Open Panel.

> For **Sync**, both fields must be folder paths and should have matching names. rsyncGUI warns you if they differ.
> For **Destination / Sync Target**, Finder packages such as `.app` bundles do not count as folders.
> For **Delete**, only the Source field is shown.

### 4 — Start

Click **Start [Operation]** once the paths validate. A confirmation dialog appears for Copy, Move, Sync, and Delete. Read it, then confirm to proceed. Use **Reset** to clear the current paths and run state.

### 5 — Monitor Progress

- The **progress bar** tracks files processed vs total.
- The **console** shows rsync's live output. Toggle it off with **Output Off** for large transfers where scrolling overhead would slow things down; errors and status messages always surface regardless.
- Click **Cancel** (or press **⌘.**) to terminate the process immediately.

### 6 — Review Results

- After **Copy / Move / Sync / Delete** a results sheet shows success, warnings, or errors.
- After **Compare** a dedicated view opens. Use the filter chips to isolate **New**, **Modified**, **Deleted**, or **Changed** files, or use the search field to find a specific path.

---

## Architecture

```
rsyncGUI/
├── rsyncGUIApp.swift             App entry point (WindowGroup → ContentView)
├── ContentView.swift             Main window — layout and UI state coordination
│                                 Holds the per-operation CommandFlag dictionary
├── PathInputView.swift           Reusable path input (browse / drag-drop)
├── rsyncOperation.swift          Enum of all 5 operations
│                                   · defaultFlags       — ordered CommandFlag array
│                                   · buildDisplayCommand — assembles the live command string
│                                   · activeArgFlags     — args to pass to Process
│                                   · defaultFlagConfigs — dictionary initialiser
├── CommandInfoView.swift         ⓘ Popover — live command box + annotated flag table
├── rsyncManager.swift            @Observable process manager
│                                   · Launches rsync / rm via Process
│                                   · Bridges FileHandle → AsyncStream<String>
│                                   · Consumes stdout + stderr concurrently (withTaskGroup)
│                                   · Parses progress (to-chk=M/T) and itemize codes
├── CompareResult.swift           CompareResult struct + ChangeType enum
├── CompareResultsView.swift      Filterable, searchable comparison results sheet
└── OperationResultsView.swift    Copy / Move / Sync / Delete completion sheet
```

### Key Design Decisions

**`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`** — the entire app runs on the main actor by default, eliminating a large class of data-race bugs without any explicit `@MainActor` annotations.

**`AsyncStream` bridging** — `FileHandle.readabilityHandler` fires on a background thread. Wrapping it in `AsyncStream<String>` lets the output be consumed with `for await` on the main actor — no `DispatchQueue.main.async` calls anywhere.

**`withTaskGroup`** — stdout and stderr are drained concurrently in a single task group, so a stalled stderr pipe never prevents stdout from updating the progress bar, and vice versa.

**Per-operation `CommandFlag` arrays** — flags are value-type `struct` instances stored in a `[rsyncOperation: [CommandFlag]]` dictionary in `ContentView`. Each operation's flag state is completely independent. `buildDisplayCommand(from:)` assembles the display string from the live array so the popover always matches what will actually run.

---

## Entitlements & Sandbox

The **App Sandbox is disabled** (`ENABLE_APP_SANDBOX = NO`). This is intentional:

1. rsyncGUI launches external processes (`rsync`, `/bin/rm`) via `Process`.
2. It must read and write arbitrary file-system paths chosen by the user.

The app uses the **Hardened Runtime** and requires no additional entitlements for local use.

> ⚠️ Because the sandbox is off, **rsyncGUI cannot be submitted to the Mac App Store** in this configuration. It works perfectly as a locally signed or directly run app for personal productivity.

---

## Author

**Stewart Lynch** · CreaTECH Solutions

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
