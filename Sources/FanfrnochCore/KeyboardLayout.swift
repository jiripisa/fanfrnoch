/// The panel's keyboard, three octaves from C2 to B4, laid out on a strip `width` by `height`
/// points: where each key lies, and what a click at a point plays.
public struct KeyboardLayout: Sendable {

    /// The notes on the strip: C2...B4.
    public static let notes: ClosedRange<Int> = 36...71

    /// A black key's width as a part of a white key's, and its length as a part of the strip's.
    static let blackWidth = 0.62, blackLength = 0.6

    /// One key: its note and its rectangle on the strip, from the strip's top left corner.
    public struct Key: Equatable, Sendable {
        public let note: Int
        public let x: Double, y: Double, width: Double, height: Double

        func contains(x: Double, y: Double) -> Bool {
            x >= self.x && x < self.x + width && y >= self.y && y < self.y + height
        }
    }

    /// What a click plays: a note, and a velocity from how far down its key the click lands.
    public struct Press: Equatable, Sendable {
        public let note: Int
        public let velocity: Int
    }

    public let width: Double, height: Double
    public let whiteKeys: [Key]
    /// Drawn over the white keys, and found first by a click.
    public let blackKeys: [Key]

    public init(width: Double, height: Double) {
        self.width = width
        self.height = height
        let whiteNotes = Self.notes.filter { !Self.isBlack($0) }
        let keyWidth = width / Double(whiteNotes.count)
        whiteKeys = whiteNotes.enumerated().map { index, note in
            Key(note: note, x: Double(index) * keyWidth, y: 0, width: keyWidth, height: height)
        }
        // A black key sits on the line between the white key below it and the next.
        let blackWidth = keyWidth * Self.blackWidth
        blackKeys = whiteNotes.enumerated().compactMap { index, note in
            guard Self.notes.contains(note + 1), Self.isBlack(note + 1) else { return nil }
            return Key(note: note + 1, x: Double(index + 1) * keyWidth - blackWidth / 2, y: 0,
                       width: blackWidth, height: height * Self.blackLength)
        }
    }

    /// The key under a point and how hard it is hit; nil off the strip.
    public func press(at x: Double, y: Double) -> Press? {
        guard let key = blackKeys.first(where: { $0.contains(x: x, y: y) })
                     ?? whiteKeys.first(where: { $0.contains(x: x, y: y) }) else { return nil }
        return Press(note: key.note, velocity: KeyStrip.velocity(at: y - key.y, height: key.height))
    }

    /// The name written on a key: every C has one ("C2", "C3", "C4"), the rest none.
    public static func label(_ note: Int) -> String? {
        note % 12 == 0 ? Notes.name(note) : nil
    }

    private static func isBlack(_ note: Int) -> Bool {
        [1, 3, 6, 8, 10].contains(note % 12)
    }
}
