import Foundation

/// Why a preset or a kit could not be saved, loaded or deleted, in words for the window.
public enum PresetError: Error, Equatable, LocalizedError {
    case noName
    case missing(String)
    case unreadable(String)

    public var errorDescription: String? {
        switch self {
        case .noName: "A name is needed."
        case .missing(let name): "There is no “\(name)” in the folder any more."
        case .unreadable(let name): "“\(name)” is not a Fanfrnoch file, or it is damaged."
        }
    }
}

/// One file per saved thing in a folder, named after it and holding it as JSON. Presets and kits
/// are both kept this way. The app and the plug-in in a host read the same folder, which is how
/// they share them; files can be copied to another Mac and renamed in the Finder.
public struct FileLibrary<Content: Codable & Sendable>: Sendable {

    /// The longest name a file can have.
    public static var longestName: Int { 60 }

    public let folder: URL
    public let fileExtension: String
    private let deletesForGood: Bool
    /// How a file takes another name. A test puts a failing one here.
    var rename: @Sendable (URL, URL) throws -> Void = { try FileManager.default.moveItem(at: $0, to: $1) }

    /// `deletesForGood` removes a deleted file instead of moving it to the Trash (for tests,
    /// which have no business in anybody's Trash).
    public init(folder: URL, fileExtension: String, deletesForGood: Bool = false) {
        self.folder = folder
        self.fileExtension = fileExtension
        self.deletesForGood = deletesForGood
    }

    /// `~/Library/Application Support/Fanfrnoch/<subfolder>`: a place every app may use without
    /// asking the system for permission.
    static func standardFolder(_ subfolder: String) -> URL {
        let files = FileManager.default
        let support = files.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? files.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support", isDirectory: true)
        return support.appendingPathComponent("Fanfrnoch/\(subfolder)", isDirectory: true)
    }

    /// The names in the folder, as the Finder sorts them (capitals do not matter). Empty while
    /// the folder is not there.
    public func names() -> [String] {
        let files = (try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil,
                                                                  options: [.skipsHiddenFiles])) ?? []
        return files.filter { $0.pathExtension.lowercased() == fileExtension }
            .map { $0.deletingPathExtension().lastPathComponent }
            .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }

    /// A name as a file can carry it: trimmed, "/" and ":" turned into "-", without a leading dot
    /// (the Finder hides such files), not longer than `longestName`. nil when nothing is left.
    public static func cleaned(_ name: String) -> String? {
        let spaces = CharacterSet.whitespacesAndNewlines
        var cleaned = String(name.unicodeScalars.filter { !CharacterSet.controlCharacters.contains($0) || $0 == "\t" || $0 == "\n" || $0 == "\r" }
            .map(Character.init).map { character -> Character in
            if character == "/" || character == ":" { return "-" }
            return character.isNewline || character == "\t" ? " " : character
        }).trimmingCharacters(in: spaces)
        while cleaned.hasPrefix(".") { cleaned.removeFirst() }
        cleaned = String(cleaned.trimmingCharacters(in: spaces).prefix(longestName)).trimmingCharacters(in: spaces)
        return cleaned.isEmpty ? nil : cleaned
    }

    /// Two names are one file when they differ in capitals only: the disk would make one file of them.
    static func same(_ one: String, _ other: String) -> Bool {
        one.compare(other, options: .caseInsensitive) == .orderedSame
    }

    /// Whether saving under a name would replace one of these.
    public static func name(_ name: String, isAmong names: [String]) -> Bool {
        guard let cleaned = cleaned(name) else { return false }
        return names.contains { same($0, cleaned) }
    }

    /// Saves under a name, replacing the file of that name, and returns the name it was stored under.
    @discardableResult
    public func save(_ content: Content, as name: String) throws -> String {
        guard let name = Self.cleaned(name) else { throw PresetError.noName }
        let files = FileManager.default
        try files.createDirectory(at: folder, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(content)
        guard let old = spelling(of: name), old != name else {
            try data.write(to: file(of: name), options: .atomic)
            return name
        }
        // The same name with other capitals (one file on a case-insensitive disk): the new content
        // goes over the old spelling's file, as any save does, and then the file takes the new
        // capitals. Should the rename fail, the content is saved all the same, under the old ones.
        try data.write(to: file(of: old), options: .atomic)
        try rename(file(of: old), file(of: name))
        return name
    }

    /// What a file holds. Throws when the file is gone and when it is not one of ours (not JSON,
    /// or a field of the wrong type).
    public func load(_ name: String) throws -> Content {
        guard let spelled = spelling(of: name) else { throw PresetError.missing(name) }
        guard let data = try? Data(contentsOf: file(of: spelled)),
              let content = try? JSONDecoder().decode(Content.self, from: data) else {
            throw PresetError.unreadable(spelled)
        }
        return content
    }

    /// Moves the file to the Trash.
    public func delete(_ name: String) throws {
        guard let spelled = spelling(of: name) else { throw PresetError.missing(name) }
        if deletesForGood {
            try FileManager.default.removeItem(at: file(of: spelled))
        } else {
            try FileManager.default.trashItem(at: file(of: spelled), resultingItemURL: nil)
        }
    }

    /// Makes the folder if it is not there yet, for showing it in the Finder.
    public func makeFolder() throws {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    }

    /// A name as the folder spells it.
    func spelling(of name: String) -> String? {
        names().first { Self.same($0, name) }
    }

    private func file(of name: String) -> URL {
        folder.appendingPathComponent(name).appendingPathExtension(fileExtension)
    }
}

/// The player's presets: one knob set each (`SetState`), in `.fanfrnoch` files.
public typealias PresetLibrary = FileLibrary<SetState>

extension FileLibrary where Content == SetState {

    public static var fileExtension: String { "fanfrnoch" }

    /// `~/Library/Application Support/Fanfrnoch/Presets`.
    public static var standard: PresetLibrary {
        PresetLibrary(folder: standardFolder("Presets"), fileExtension: fileExtension)
    }
}

/// What a window keeps of the presets of one set: the names in the folder, the preset in use and
/// its values. A model holds one per set (the keyboard's and each pad's), so the rules are the
/// same everywhere.
public struct PresetShelf: Sendable {

    public let library: PresetLibrary
    /// The presets, in the order the menu shows them.
    public private(set) var names: [String]
    /// The preset the set's sound came from, nil when it came from a built-in program or from
    /// somewhere else.
    public private(set) var inUse: String?
    private var state: SetState?

    /// `inUse` is the preset that was in use when the window was last open; it counts only while
    /// the folder still has it.
    public init(library: PresetLibrary, inUse name: String?) {
        self.library = library
        names = library.names()
        follow(name)
    }

    /// The value the preset in use gives a parameter: what a double click on its knob returns to.
    /// nil when no preset is in use.
    public func value(of parameter: Parameter) -> Float? {
        state?.values[parameter.identifier]
    }

    /// Saves a sound under a name (the file records it as the set's preset) and makes it the
    /// preset in use.
    public mutating func save(_ set: SetState, as name: String) throws {
        var set = set
        set.preset = PresetLibrary.cleaned(name)
        let stored = try library.save(set, as: name)
        names = library.names()
        inUse = stored
        set.preset = stored
        state = set
    }

    /// Hands over a preset's sound, named after the file, and makes it the preset in use. When it
    /// cannot be read, nothing changes.
    public mutating func load(_ name: String) throws -> SetState {
        var set = try library.load(name)
        names = library.names()
        let spelled = names.first { PresetLibrary.same($0, name) } ?? name
        set.preset = spelled
        inUse = spelled
        state = set
        return set
    }

    /// Deletes a preset. The sound is not touched: when it was the preset in use, none is in use
    /// any more.
    public mutating func delete(_ name: String) throws {
        try library.delete(name)
        names = library.names()
        if let inUse, PresetLibrary.same(inUse, name) { leave() }
    }

    /// The sound now comes from somewhere else (a built-in program).
    public mutating func leave() {
        inUse = nil
        state = nil
    }

    /// Reads the folder again: another window may have saved a preset, the Finder may have taken
    /// one away. True when something changed.
    @discardableResult
    public mutating func look() -> Bool {
        let found = library.names()
        var changed = false
        if found != names {
            names = found
            changed = true
        }
        if let inUse, !found.contains(inUse) {
            leave()
            changed = true
        }
        return changed
    }

    /// The preset in use was named from outside (a host's project came back with it): it is in use
    /// when the folder has a readable preset of that name, and no preset is in use otherwise.
    public mutating func follow(_ name: String?) {
        guard let name, let spelled = names.first(where: { PresetLibrary.same($0, name) }),
              let state = try? library.load(spelled) else {
            leave()
            return
        }
        inUse = spelled
        self.state = state
    }
}
