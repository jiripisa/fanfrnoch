import Foundation

/// What a window keeps of the player's files for every set it can show: a `PresetShelf` for the
/// keyboard's set and one for each pad's, so that each set knows the preset it came from, and the
/// names of the kits. The app's model and the plug-in window's both hold one, so the rules are
/// the same in both; the model puts the sounds into the synth or the unit and remembers the names
/// (`namesInUse`) where it keeps its state.
public struct PresetShelves: Sendable {

    public let kitLibrary: KitLibrary
    /// The keyboard's shelf first, then pad 0...15's.
    private var shelves: [PresetShelf]
    /// The kits, in the order the menu shows them.
    public private(set) var kits: [String]

    /// How many sets there are: the keyboard's and the sixteen pads'.
    public static var count: Int { 1 + PadGrid.count }

    /// `names` are the presets in use as last remembered, the keyboard's first; each counts only
    /// while the folder has it. Fewer names leave the other sets with none.
    public init(presets: PresetLibrary, kits: KitLibrary, inUse names: [String?] = []) {
        kitLibrary = kits
        shelves = (0..<Self.count).map { set in
            PresetShelf(library: presets, inUse: names.indices.contains(set) ? names[set] : nil)
        }
        self.kits = kits.names()
    }

    public var presetLibrary: PresetLibrary { shelves[0].library }

    /// The presets, in the order the menu shows them.
    public var presets: [String] { shelves[0].names }

    /// The preset a set's sound came from; nil for none, and for a pad outside 0...15.
    public func inUse(in set: SoundSet) -> String? {
        Self.position(of: set).flatMap { shelves[$0].inUse }
    }

    /// The preset of every set, the keyboard's first: what a model remembers.
    public var namesInUse: [String?] { shelves.map(\.inUse) }

    /// What a double click returns a knob to: the value of the set's preset in use, otherwise the
    /// value of the set's program, otherwise (no program) the knob's default.
    public func resetValue(of parameter: Parameter, in set: SoundSet, program: Int) -> Float {
        if let position = Self.position(of: set), let plain = shelves[position].value(of: parameter) { return plain }
        return Programs.value(program: program, parameter: parameter)
    }

    // MARK: Presets

    /// Hands over a preset's sound for a set, named after its file, and makes it the set's preset
    /// in use. When the file cannot be read, nothing changes.
    public mutating func load(_ name: String, into set: SoundSet) throws -> SetState {
        guard let position = Self.position(of: set) else { throw PresetError.missing(name) }
        let state = try shelves[position].load(name)
        lookAgain(besides: position)
        return state
    }

    /// Saves a set's sound under a name and makes it the set's preset in use. Another set using a
    /// preset of that name now goes back to the new file's values.
    public mutating func save(_ state: SetState, as name: String, from set: SoundSet) throws {
        guard let position = Self.position(of: set) else { throw PresetError.noName }
        try shelves[position].save(state, as: name)
        lookAgain(besides: position, savedOver: shelves[position].inUse)
    }

    /// Deletes a preset. The sounds are not touched; every set that used it has none any more.
    public mutating func delete(_ name: String) throws {
        try shelves[0].delete(name)
        lookAgain(besides: 0)
    }

    /// A set's sound now comes from somewhere else (a built-in program).
    public mutating func leave(_ set: SoundSet) {
        if let position = Self.position(of: set) { shelves[position].leave() }
    }

    /// A set's preset in use was named from outside (a host's project): it is in use while the
    /// folder has a readable preset of that name.
    public mutating func follow(_ name: String?, in set: SoundSet) {
        if let position = Self.position(of: set) { shelves[position].follow(name) }
    }

    /// Reads both folders again: another window may have saved a preset or a kit, the Finder may
    /// have taken one away. A preset in use that is gone is in use no more. True when something
    /// changed.
    @discardableResult
    public mutating func look() -> Bool {
        var changed = false
        for position in shelves.indices where shelves[position].look() { changed = true }
        let found = kitLibrary.names()
        if found != kits {
            kits = found
            changed = true
        }
        return changed
    }

    /// After one set saved, loaded or deleted: the others see the folder as it is now, and a set
    /// whose preset was just saved over takes the new values.
    private mutating func lookAgain(besides changed: Int, savedOver saved: String? = nil) {
        for position in shelves.indices where position != changed {
            let before = shelves[position].inUse
            shelves[position].look()
            // Saved over in other capitals, the file has the new spelling: follow it there too.
            if let saved, let before, PresetLibrary.same(before, saved) { shelves[position].follow(saved) }
        }
    }

    // MARK: Kits

    /// Hands over a kit, and gives each of its pads the preset recorded with it, while the folder
    /// has that preset. Pads the kit does not have keep theirs.
    public mutating func loadKit(_ name: String) throws -> Kit {
        let kit = try kitLibrary.load(name)
        kits = kitLibrary.names()
        for (pad, saved) in kit.pads.prefix(PadGrid.count).enumerated() {
            shelves[1 + pad].look()
            shelves[1 + pad].follow(saved.set.preset)
        }
        return kit
    }

    /// The pads took the engine's own kit: none of them comes from a preset.
    public mutating func leavePads() {
        for position in shelves.indices.dropFirst() { shelves[position].leave() }
    }

    /// Saves the pads as a kit under a name, each with its preset in use.
    public mutating func saveKit(_ kit: Kit, as name: String) throws {
        guard let cleaned = KitLibrary.cleaned(name) else { throw PresetError.noName }
        var kit = kit
        kit.name = cleaned
        for pad in kit.pads.indices.prefix(PadGrid.count) { kit.pads[pad].set.preset = shelves[1 + pad].inUse }
        try kitLibrary.save(kit, as: cleaned)
        kits = kitLibrary.names()
    }

    /// Deletes a kit. The pads are not touched.
    public mutating func deleteKit(_ name: String) throws {
        try kitLibrary.delete(name)
        kits = kitLibrary.names()
    }

    /// A set's place among the shelves: 0 for the keyboard, 1...16 for a pad; nil for a pad
    /// outside 0...15.
    private static func position(of set: SoundSet) -> Int? {
        switch set {
        case .keyboard: 0
        case .pad(let pad): (0..<PadGrid.count).contains(pad) ? 1 + pad : nil
        }
    }
}
