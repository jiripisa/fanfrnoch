/// Where the panel puts the controls of a section: rows of cells in a number of columns, as the
/// approved mockup draws them (`.planning/design/concepts/concept-1-keyboard.png`). A cell holds
/// one control. A switch gets a row of its own, as wide as the section, its name beside it; a
/// thin rule may part rows of another kind.
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
        /// A thin line across the section.
        case rule
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
            case .rule:
                rows.append(.rule)
            }
        }
        let planned = Set(plan.rows.flatMap(\.identifiers))
        let rest = section.parameters.filter { !planned.contains($0.identifier) }
        return SectionLayout(columns: plan.columns, rows: parted(rows + flowing(rest, columns: plan.columns).rows))
    }

    /// Knobs in reading order, then each switch in a row of its own.
    private static func flowing(_ parameters: [Parameter], columns: Int) -> SectionLayout {
        let knobs = parameters.filter { !$0.isChoice }
        let rows = stride(from: 0, to: knobs.count, by: columns).map { Row.cells(Array(knobs[$0..<min($0 + columns, knobs.count)])) }
        return SectionLayout(columns: columns, rows: rows + parameters.filter(\.isChoice).map(Row.wide))
    }

    /// The rules that part two rows of controls; one with nothing above or below it goes.
    private static func parted(_ rows: [Row]) -> [Row] {
        var kept: [Row] = []
        for row in rows {
            if row == .rule, kept.last == nil || kept.last == .rule { continue }
            kept.append(row)
        }
        while kept.last == .rule { kept.removeLast() }
        return kept
    }

    private enum PlannedRow {
        case cells([String]), wide(String), rule

        var identifiers: [String] {
            switch self {
            case .cells(let identifiers): identifiers
            case .wide(let identifier): [identifier]
            case .rule: []
            }
        }
    }

    /// The friction drum's sections as the mockup draws them. Hands and Noise are one row,
    /// centred in their cards; Body's Skin row has Track at its end. Master stacks its knobs in
    /// pairs, then the two LFO shapes, then Drum and LFO Start, each part under a rule.
    private static let plans: [String: (columns: Int, rows: [PlannedRow])] = [
        "Stroke": (3, [.cells(["attack", "length", "release"]), .cells(["damp", "velsens", "vary"]), .wide("keyup")]),
        "Hands": (2, [.cells(["alternate", "alttune"])]),
        "Pitch": (4, [.cells(["scoop", "scooptime", "drift", "drop"]), .cells(["wobble", "jump", "jumpratio", "velpitch"])]),
        "Friction": (3, [.cells(["stick", "stickvel", "split"]), .cells(["creak", "creakrate", "creakring"])]),
        "Body": (4, [.cells(["pot", "potq", "potlevel"]), .cells(["skin", "skinq", "skinlevel", "track"])]),
        "Noise": (3, [.cells(["rub", "scrape", "shimmer"])]),
        "Master": (2, [.cells(["volume", "pan"]), .cells(["tune", "octave"]), .cells(["bendup", "benddown"]),
                       .cells(["lfo1rate", "lfo2rate"]), .rule, .wide("lfo1shape"), .wide("lfo2shape"), .rule,
                       .wide("drum"), .wide("lfostart")]),
    ]
}

/// Where the panel puts its sections, as the approved mockup does: cards in two rows on the left
/// (Stroke | Hands | Pitch over Friction | Body | Noise) and Master on the right, the full
/// height of both rows. A section the panel does not know joins the last row.
public struct PanelLayout: Sendable {

    /// The rows of cards on the left, top first.
    public let rows: [[ParameterSection]]
    /// The card on the right; nil without a Master section.
    public let side: ParameterSection?

    private static let plannedRows = [["Stroke", "Hands", "Pitch"], ["Friction", "Body", "Noise"]]
    private static let plannedSide = "Master"

    public static func of(_ sections: [ParameterSection]) -> PanelLayout {
        let byTitle = Dictionary(sections.map { ($0.title, $0) }, uniquingKeysWith: { first, _ in first })
        var rows = plannedRows.map { $0.compactMap { byTitle[$0] } }.filter { !$0.isEmpty }
        let planned = Set(plannedRows.flatMap { $0 } + [plannedSide])
        let rest = sections.filter { !planned.contains($0.title) }
        if !rest.isEmpty {
            if rows.isEmpty { rows.append(rest) } else { rows[rows.count - 1] += rest }
        }
        return PanelLayout(rows: rows, side: byTitle[plannedSide])
    }

    /// The widths of a row's cards. `width` less the gaps between the cards (`spacing`) and each
    /// card's own padding (`inset`) is shared in proportion to the cards' columns, so that a
    /// knob gets about as much room in every card of the row.
    public static func widths(of row: [ParameterSection], in width: Double, spacing: Double, inset: Double) -> [Double] {
        guard !row.isEmpty else { return [] }
        let columns = row.map { Double(SectionLayout.of($0).columns) }
        let room = width - spacing * Double(row.count - 1) - inset * Double(row.count)
        let total = columns.reduce(0, +)
        return columns.map { inset + room * $0 / total }
    }
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
