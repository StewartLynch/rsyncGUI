# rsyncGUI Agent Notes

## Project Overview
rsyncGUI is a macOS SwiftUI utility that wraps `rsync` operations in a GUI. It supports copy, move, sync, delete, and compare workflows with in-app output and result summaries.

## Key Architecture Decisions
- `RSyncOperation` centralizes operation metadata (labels, symbols, confirmation behavior, and destination semantics).
- `RSyncManager` is the execution layer for filesystem operations and output handling.
- Views are split by concern (`ContentView`, `PathInputView`, result views) to keep UI composition clean and testable.

## Important Conventions
- Prefer modern SwiftUI patterns and clear view composition.
- Keep operation-specific strings/flags in `RSyncOperation` instead of scattering conditionals.
- Use Swift naming conventions: PascalCase for types, camelCase for members.
- Prefer safe optional handling; avoid force unwraps.

## Build / Run
1. Open the project in Xcode.
2. Select scheme `rsyncGUI`.
3. Build and run on macOS.

## Quirks / Gotchas
- SF Symbol availability can vary by OS symbol set; verify symbol names.
- `sync` uses a peer destination model, unlike `copy`/`move` parent-destination behavior.
- Destructive operations require clear confirmation messaging.
