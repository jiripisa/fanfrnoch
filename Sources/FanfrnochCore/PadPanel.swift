/// What the panel writes on and about a pad. Pads count from 0 in the code and from 01 on screen.
public enum PadLabel {

    /// "05" for pad 4.
    public static func number(_ pad: Int) -> String {
        let number = pad + 1
        return number < 10 ? "0\(number)" : "\(number)"
    }

    /// "05 · Khomus": the pad's number and name, as the inspector and Send to pad name it.
    public static func title(_ pad: Int, name: String) -> String {
        "\(number(pad)) · \(name)"
    }

    /// A mute group as a pad tile shows it: "G3", or "Off".
    public static func group(_ group: Int?) -> String {
        group.map { "G\($0)" } ?? "Off"
    }

    /// The second line of a pad tile: "C2  G1", the pad's pitch and its group.
    public static func pitchAndGroup(note: Int, group: Int?) -> String {
        "\(Notes.name(note))  \(Self.group(group))"
    }

    /// The pitch Send to pad gives a pad: the last note played, C2 (36) before any, as the
    /// engine does.
    public static func sendPitch(lastNote: Int?) -> Int {
        lastNote ?? 36
    }

    /// What Send to pad asks before it replaces a pad's sound.
    public static func sendQuestion(pad: Int, name: String, lastNote: Int?) -> String {
        "Replace pad \(title(pad, name: name)) with the keyboard's sound at \(Notes.name(sendPitch(lastNote: lastNote)))?"
    }
}

/// The sixteen pads on screen: where each sits and when one lights up.
public enum PadGrid {

    public static let rows = 4, columns = 4

    /// The pad at a place in the grid. Pad 1 is top left and the pads run left to right, row by
    /// row, as in the approved mockup (not from the bottom, as on an MPC).
    public static func pad(row: Int, column: Int) -> Int {
        row * columns + column
    }

    /// How long a pad stays lit after a hit.
    public static let flash = Duration.milliseconds(150)

    /// The pads hit between two looks at their hit counters (`old` and `new`, by pad): those
    /// whose count rose. A first look (no `old`) and a counter that went back (a new engine)
    /// light nothing; several hits between two looks light the pad once.
    public static func hit(between old: [Int], and new: [Int]) -> [Int] {
        zip(old, new).enumerated().compactMap { pad, counts in counts.1 > counts.0 ? pad : nil }
    }
}
