# RSyncMaster

## Project Overview
A macOS SwiftUI app that provides a GUI frontend for rsync. Supports Copy, Move, Delete, and Compare operations with drag-and-drop path input, live console output, progress tracking, and results views.

## Architecture

- **`RSyncManager`** — `@Observable` class (implicitly `@MainActor`). Owns all process lifecycle: launches rsync/rm via `Process`, bridges `FileHandle.readabilityHandler` → `AsyncStream<String>`, updates state/progress/output.
- **`ContentView`** — Main window. Holds `RSyncManager` as `@State`. Coordinates all UI state.
- **`PathInputView`** — Reusable component supporting typed input, NSOpenPanel browse, and drag-and-drop of file URLs.
- **`CompareResultsView`** — Table view with filter chips showing diff results from `--itemize-changes`.
- **`OperationResultsView`** — Sheet for Copy/Move/Delete completion + error list.

## Key Conventions

- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` is set — all code is implicitly `@MainActor`
- `AsyncStream` bridges background `FileHandle` callbacks to the main actor safely
- `withTaskGroup` is used to consume stdout + stderr concurrently
- App Sandbox is **disabled** (`ENABLE_APP_SANDBOX = NO`) — required for subprocess execution and arbitrary file access
- macOS 26 deployment target

## rsync Notes

- Prefers Homebrew rsync at `/opt/homebrew/bin/rsync` if present (newer than system 2.6.9)
- Progress parsed from `to-chk=M/T` token in `--progress` output
- Compare uses `-avn --itemize-changes`; results parsed via itemize format (`YXcstpogaz path`)
- Delete uses `/bin/rm -rfv`

## Build & Run

Open `RSyncMaster.xcodeproj` in Xcode 16+ and run. No external dependencies.

## Entitlements

App Sandbox is off. The app uses Hardened Runtime. No additional entitlements needed for local use. **Cannot be submitted to the Mac App Store** in this configuration.
