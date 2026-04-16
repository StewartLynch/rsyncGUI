# rsyncGUI — Engineering Journal

## The Big Picture

Imagine you've been using rsync in the terminal for years — it's powerful but you always have to remember the flags. rsyncGUI is the "put a face on it" solution: a clean macOS app where you pick Copy/Move/Delete/Compare, drag your source and destination folders in, hit go, and watch the live output scroll by like a proper command-line power user — but without the command line.

Think of it as a cockpit for rsync. All the power, none of the typing.

---

## Architecture Deep Dive

The app is structured around one central idea: **the `rsyncManager` knows everything, the views just show it.**

### The Kitchen Analogy

- **`rsyncManager`** = the kitchen. It runs the actual rsync processes, manages output, tracks progress, collects errors. Nobody touches the stove but the kitchen.
- **`ContentView`** = the dining room. It presents what the kitchen produces. It holds the manager as `@State` and observes it via Swift's `@Observable` macro.
- **`PathInputView`** = the waiter taking your order — accepts paths three ways (type, drag, browse) and reports them back.
- **`CompareResultsView` / `OperationResultsView`** = the receipt. Shows you what happened after the kitchen's done.

### The Concurrency Story

Here's where it gets interesting. `rsync` writes output to stdout and stderr *asynchronously* — it doesn't wait for you. We need to read both streams *concurrently* without blocking the UI.

The solution: **`AsyncStream` as a pipe bridge.**

```
Background thread (readabilityHandler)
    ↓ continuation.yield(text)   ← Sendable, thread-safe
AsyncStream<String>
    ↓ for await chunk in stream  ← runs on @MainActor
rsyncManager processes output, updates @Observable properties
    ↓ SwiftUI observes changes
Views update automatically
```

The project has `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` set, which means everything is implicitly on the main actor. The `AsyncStream` bridge is what makes background callbacks safe — `AsyncStream.Continuation` is `Sendable`, so `yield()` from a background thread is perfectly fine.

---

## The Codebase Map

```
rsyncGUI/
├── rsyncGUIApp.swift           App entry, window size/resizability
├── ContentView.swift            Main UI — operation picker, paths, console, action bar
├── rsyncOperation.swift         Enum: Copy/Move/Delete/Compare + labels/systemImages
├── rsyncManager.swift           @Observable process manager — the brain
├── CompareResult.swift          Model: ChangeType enum + CompareResult struct
├── PathInputView.swift          Reusable path input: text field + drag + NSOpenPanel
├── CompareResultsView.swift     Table sheet for compare diff results
└── OperationResultsView.swift   Sheet for Copy/Move/Delete results + error list
```

---

## Tech Stack & Why

| Tech | Why |
|------|-----|
| **SwiftUI** | macOS 26 target — all modern APIs available, declarative layout wins |
| **`@Observable`** | Cleaner than `ObservableObject` — no `@Published` noise, auto-observes only accessed properties |
| **`AsyncStream`** | Bridges `FileHandle.readabilityHandler` (background) to `async for` loops (main actor) without locks or dispatch queues |
| **`Process`** | Direct `NSTask` wrapper for launching rsync/rm — gives us full pipe control |
| **`withTaskGroup`** | Consumes stdout and stderr concurrently without blocking |
| **No Sandbox** | rsync needs to access ANY file path the user gives it, and we need to exec arbitrary binaries — sandbox would block both |
| **`NSOpenPanel`** | Modal file picker — the right tool for "user picks a file" on macOS |
| **`Table`** | Used in CompareResultsView — perfect for sortable columnar data like diff results |

---

## The Journey

### Day 1 — Building the Foundation

**The async output streaming challenge** was the first real puzzle. The naive approach — reading output synchronously — would block the UI. The solution was `AsyncStream` as a bridge. Turns out `AsyncStream.Continuation` being `Sendable` is the key insight: you can `yield()` from any thread, and the `async for` consumer runs wherever you want.

**The `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` discovery** was a pleasant surprise. This project setting (Xcode 26 default) means you don't need to scatter `@MainActor` everywhere. Everything on main by default — great for a UI-heavy app. The gotcha: `Task.detached {}` and readabilityHandler closures still run off main, so the `AsyncStream` bridge is essential.

**Sandbox vs. rsync** was the first "aha" moment: you simply cannot run rsync as a subprocess from a sandboxed app on arbitrary user-specified paths. The App Sandbox was disabled, which also means this app can't go on the Mac App Store — but for a developer tool, that's fine.

**The `PBXFileSystemSynchronizedRootGroup` discovery**: Xcode 16+ uses a new project format where files in the filesystem are automatically included in the build. No need to add files to the `.pbxproj`! Just create `.swift` files in the right folder.

**rsync itemize-changes parsing** took careful reading of the rsync man page. The format `YXcstpogaz path` needs special handling:
- `>f+++++++++` = new file (all `+` = doesn't exist at dest)
- `*deleting  ` = file only in dest (would be removed)
- `.f..t......` = attribute-only change

**Progress from `--progress`**: rsync's per-file progress output includes `(xfr#N, to-chk=M/T)` — that `M/T` is "M files remaining out of T total". Parsed with regex to show overall progress.

**The Homebrew rsync preference**: macOS ships rsync 2.6.9 (from 2006!). Homebrew users may have 3.x. The app checks `/opt/homebrew/bin/rsync` first so power users get the newer version automatically.

### Day 2 — The Symbol That Never Existed

Small bug, real impact: the move operation icon referenced `tray.and.arrow.right.fill`, which is not a valid symbol in the system set for this target. That produced a runtime symbol lookup error.

Fix applied in `rsyncOperation.systemImage`:
- Replaced `tray.and.arrow.right.fill` with `arrow.right.square.fill`.

Lesson reinforced: SF Symbol names that look plausible are not guaranteed to exist. Treat symbol IDs like API names and validate them against the actual platform set.

---

## Engineer's Wisdom

**1. Concurrency via composition, not mutation.**
The `AsyncStream` bridge doesn't mutate state from the background — it just feeds data into a channel. All state mutation happens at the consumption site (main actor). This is the right mental model for async I/O.

**2. `@Observable` is much nicer than `ObservableObject`.**
With `ObservableObject`, every `@Published` property causes a view re-render even if that property isn't observed. `@Observable` only triggers re-renders when properties you actually *accessed* change. For a class like `rsyncManager` with many properties, this matters.

**3. `withTaskGroup` > `async let` for unknown-count concurrency.**
`async let` needs the count known at compile time. `withTaskGroup` can add tasks dynamically and waits for all of them.

**4. `Table` is underused in macOS apps.**
`CompareResultsView` uses `Table` for the diff results — it gives column resizing, sorting, and proper Mac look for free. More macOS developers should reach for it.

**5. The NSOpenPanel pattern.**
`panel.runModal()` blocks synchronously but runs a modal event loop — it doesn't freeze the app. This is the macOS way. Don't wrap it in `async` machinery; just call it from a button action.

---

## If I Were Starting Over…

1. **Add a preferences panel** for default rsync flags (exclude patterns, bandwidth limits).
2. **Persist recent paths** using `@AppStorage` or `UserDefaults` — drag-and-drop is great but having a history would be better.
3. **Add drag-to-swap** for source/destination paths — swap button would be useful for compare round-trips.
4. **Consider XPC for the process runner** — if App Store distribution ever matters, an XPC helper service can run processes outside the sandbox with specific entitlements.
5. **rsync version detection** — show which rsync is being used in the UI and warn if it's the ancient system version.
