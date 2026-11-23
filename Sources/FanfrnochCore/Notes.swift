/// MIDI note names as the app shows them: C2 is note 36 (the first pad), so C-1 is 0, C4 is 60
/// and G9 is 127.
public enum Notes {

    /// Every MIDI note.
    public static let range: ClosedRange<Int> = 0...127

    /// Every note by octave, C to B: C-1...B-1 first, C9...G9 last. The pitch menus' submenus.
    public static let octaves: [ClosedRange<Int>] = stride(from: range.lowerBound, through: range.upperBound, by: 12).map {
        $0...min($0 + 11, range.upperBound)
    }

    private static let names = ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"]

    /// "C2" for 36, "C♯4" for 61. A note outside `range` counts as the nearest valid one.
    public static func name(_ note: Int) -> String {
        let note = min(max(note, range.lowerBound), range.upperBound)
        return "\(names[note % 12])\(note / 12 - 1)"
    }
}
