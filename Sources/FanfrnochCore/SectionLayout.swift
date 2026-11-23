/// Where the panel puts the controls of a section: rows of cells in a number of columns, as in
/// the approved mockup (`.planning/design/concepts/concept-2-keyboard.png`). A cell holds one
/// control. A switch whose choices do not fit in a cell gets a row of its own, as wide as the
/// section, below the knobs.
///
/// The sections and their controls come from the engine (`ParameterSection`); this only places
/// them. A control the engine adds later, or a section the panel does not know, still shows:
/// knobs in reading order, switches in rows of their own.
public struct SectionLayout: Sendable, Equatable {

    public enum Row: Sendable, Equatable {
        /// Controls side by side, one a column from the left.
        case cells([Parameter])
        /// One control across the section.
        case wide(Parameter)
    }

    public let columns: Int
    public let rows: [Row]

    public static func of(_ section: ParameterSection) -> SectionLayout {
        guard let plan = plans[section.title] else { return flowing(section.parameters, columns: 3) }
        let byIdentifier = Dictionary(uniqueKeysWithValues: section.parameters.map { ($0.identifier, $0) })
        var rows: [Row] = []
        for row in plan.rows {
            switch row {
            case .cells(let identifiers):
                let cells = identifiers.compactMap { byIdentifier[$0] }
                if !cells.isEmpty { rows.append(.cells(cells)) }
            case .wide(let identifier):
                if let parameter = byIdentifier[identifier] { rows.append(.wide(parameter)) }
            }
        }
        let planned = Set(plan.rows.flatMap(\.identifiers))
        let rest = section.parameters.filter { !planned.contains($0.identifier) }
        return SectionLayout(columns: plan.columns, rows: rows + flowing(rest, columns: plan.columns).rows)
    }

    /// Knobs in reading order, then each switch in a row of its own.
    private static func flowing(_ parameters: [Parameter], columns: Int) -> SectionLayout {
        let knobs = parameters.filter { !$0.isChoice }
        let rows = stride(from: 0, to: knobs.count, by: columns).map { Row.cells(Array(knobs[$0..<min($0 + columns, knobs.count)])) }
        return SectionLayout(columns: columns, rows: rows + parameters.filter(\.isChoice).map(Row.wide))
    }

    private enum PlannedRow {
        case cells([String]), wide(String)

        var identifiers: [String] {
            switch self {
            case .cells(let identifiers): identifiers
            case .wide(let identifier): [identifier]
            }
        }
    }

    /// The mockup's sections. Curve's choices ("There and Back") and LFO Start, for which the
    /// mockup has no cell, get rows of their own.
    private static let plans: [String: (columns: Int, rows: [PlannedRow])] = [
        "Reed": (2, [.cells(["ring", "edge"]), .cells(["offset", "body"]), .cells(["buzz", "clang"])]),
        "Stroke": (2, [.cells(["velsens", "stroke"]), .cells(["damp", "keyup"]), .cells(["vary"])]),
        "Mouth": (3, [.cells(["vowel", "sweep", "sweeptime"]), .cells(["reso", "throat", "throattune"]),
                      .cells(["open", "close"]), .wide("curve")]),
        "Breath": (2, [.cells(["breath", "puff"]), .cells(["pufftime", "air"])]),
        "Master": (3, [.cells(["volume", "pan", "tune"]), .cells(["octave", "bendvowel", "lfo1rate"]),
                       .cells(["lfo1shape", "lfo2rate", "lfo2shape"]), .wide("lfostart")]),
    ]
}

public extension Parameter {
    /// True for a switch: one of a list of choices.
    var isChoice: Bool {
        if case .choice = kind { return true }
        return false
    }

    /// The names of a switch's choices; empty for a knob.
    var choices: [String] {
        if case .choice(let names) = kind { return names }
        return []
    }
}
