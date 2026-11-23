/// What the panel's Preset menu (in the header) and Kit menu (beside the pads) list, top to
/// bottom. The panel draws the entries; a click on a file loads it, Save opens the name popover
/// (`NameCheck`), and Delete asks first (`deleteQuestion`).
public enum LibraryMenu {

    public enum Entry: Equatable, Sendable {
        /// A file. Ticked while it is the preset in use of the set the panel shows; nil for a
        /// file that is never ticked (a kit), which the menu shows without a tick column.
        case file(String, ticked: Bool?)
        /// The engine's own sound instead of a file's: "Default kit".
        case standard(String)
        case divider
        /// Opens the name popover: "Save as…".
        case save(String)
        /// A submenu of every file: "Delete".
        case delete(String, names: [String])
    }

    /// The presets, the one in use ticked; then Save as…, and Delete when there is a preset to delete.
    public static func presets(_ names: [String], inUse: String?) -> [Entry] {
        let files = names.map { name in
            Entry.file(name, ticked: inUse.map { PresetLibrary.same($0, name) } ?? false)
        }
        return files + commands(after: files, [.save("Save as…")], delete: "Delete", names: names)
    }

    /// The kits (none is "in use": a kit's pads are edited one by one); then the engine's kit,
    /// Save kit as…, and Delete kit when there is a kit to delete.
    public static func kits(_ names: [String]) -> [Entry] {
        let files = names.map { Entry.file($0, ticked: nil) }
        return files + commands(after: files, [.standard("Default kit"), .save("Save kit as…")],
                                delete: "Delete kit", names: names)
    }

    /// What Delete asks before a file goes.
    public static func deleteQuestion(_ name: String) -> String {
        "Delete “\(name)”? It goes to the Trash."
    }

    private static func commands(after files: [Entry], _ commands: [Entry], delete: String, names: [String]) -> [Entry] {
        (files.isEmpty ? [] : [.divider]) + commands + (names.isEmpty ? [] : [.delete(delete, names: names)])
    }
}

/// What the name popover makes of what has been typed, against the files already there: nothing
/// a file can be called, a new name, or the name of a file that saving would replace.
public enum NameCheck: Equatable, Sendable {
    /// Nothing is left once the name is cleaned: Save is off.
    case unusable
    /// No file has this name: Save saves under it, as cleaned.
    case new(String)
    /// A file has this name, perhaps in other capitals (one file on the disk): Save asks
    /// first. The name as the folder spells it.
    case replaces(String)

    public init(_ typed: String, among names: [String]) {
        guard let cleaned = Self.cleaned(typed) else {
            self = .unusable
            return
        }
        if let existing = names.first(where: { PresetLibrary.same($0, cleaned) }) {
            self = .replaces(existing)
        } else {
            self = .new(cleaned)
        }
    }

    public var canSave: Bool { self != .unusable }

    /// A name as a file will carry it, the one this check judges; nil when nothing is left.
    /// Presets and kits share the rule (`FileLibrary.cleaned` does not depend on what a file
    /// holds).
    public static func cleaned(_ typed: String) -> String? {
        PresetLibrary.cleaned(typed)
    }

    /// What the popover asks before it replaces a file; nil when nothing is replaced.
    public var question: String? {
        if case .replaces(let name) = self { return "Replace “\(name)”?" }
        return nil
    }
}

/// The one-line message under the panel's header when a file could not be saved, loaded or
/// deleted: never an alert, which a plug-in's window mishandles.
public enum ErrorNotice {

    /// How long the message stays.
    public static let shownFor = Duration.seconds(4)

    /// The message to show at `now` for an error that happened at `time`; nil when there is none
    /// or its time is up.
    public static func message(_ error: String?, at time: ContinuousClock.Instant?,
                               now: ContinuousClock.Instant) -> String? {
        guard let error, let time, now - time < shownFor else { return nil }
        return error
    }
}
