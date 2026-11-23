import FanfrnochDSP

/// When the standalone app writes the sound to its settings: half a second after the last edit,
/// so that a knob drag, which edits many times a second, is written once, after it ends. The
/// plug-in's window tells the host of its pad edits on the same delay.
public struct SaveDebounce: Sendable {

    /// How long after the last edit the sound is written.
    public static let delay = Duration.milliseconds(500)

    /// When the sound is to be written; nil when nothing is waiting.
    private var deadline: ContinuousClock.Instant?

    public init() {}

    /// An edit not yet written.
    public var isPending: Bool { deadline != nil }

    /// Something changed: write it `delay` from now, not before.
    public mutating func edited(at now: ContinuousClock.Instant) {
        deadline = now + Self.delay
    }

    /// Whether the sound is to be written now.
    public func isDue(at now: ContinuousClock.Instant) -> Bool {
        deadline.map { now >= $0 } ?? false
    }

    /// The sound was written.
    public mutating func saved() {
        deadline = nil
    }
}

/// The keys and pads held down with the mouse. When the app loses focus or its window closes,
/// the mouse-up that would end them may never come, so the app lets go of them itself.
public struct HeldNotes: Sendable {

    private var keys: Set<Int> = []
    private var pads: Set<Int> = []

    public init() {}

    public var isEmpty: Bool { keys.isEmpty && pads.isEmpty }

    public mutating func keyDown(_ note: Int) { keys.insert(note) }
    public mutating func keyUp(_ note: Int) { keys.remove(note) }

    /// A pad outside 0...15 plays nothing, so it is never held.
    public mutating func padDown(_ pad: Int) {
        if (0..<PadGrid.count).contains(pad) { pads.insert(pad) }
    }
    public mutating func padUp(_ pad: Int) { pads.remove(pad) }

    /// The notes to end, lowest first, each once: the held keys, and each held pad's note. Nothing
    /// is held afterwards.
    public mutating func releaseAll() -> [Int] {
        let notes = keys.union(pads.map(PadGrid.note(ofPad:))).sorted()
        keys.removeAll()
        pads.removeAll()
        return notes
    }
}

extension PadGrid {

    /// How many pads there are.
    public static var count: Int { rows * columns }

    /// The note that hits a pad in pad mode: 36 for pad 0 … 51 for pad 15.
    public static func note(ofPad pad: Int) -> Int {
        Int(FANFRNOCH_FIRST_PAD_NOTE) + pad
    }

    /// The selected pad as remembered in the settings, kept within 0...15.
    public static func pad(stored: Int) -> Int {
        min(max(stored, 0), count - 1)
    }
}

extension PadLabel {

    /// A pad's name: the program last loaded into it ("Zambomba"), or "Custom" for a sound that came
    /// from no built-in program.
    public static func name(program: Int) -> String {
        Programs.names.indices.contains(program) ? Programs.names[program] : "Custom"
    }

    /// A pad's name: its preset's, if it has one; otherwise its program's; otherwise "Custom".
    public static func name(program: Int, preset: String?) -> String {
        if let preset, !preset.isEmpty { return preset }
        return name(program: program)
    }
}
