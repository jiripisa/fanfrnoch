import Testing
@testable import FanfrnochCore

/// Where the panel puts the controls of each section, and where it puts the sections.
@Suite("Section layout")
struct SectionLayoutTests {

    private static func ids(_ row: SectionLayout.Row) -> [String] {
        switch row {
        case .cells(let parameters): parameters.map(\.identifier)
        case .wide(let parameter): [parameter.identifier]
        case .rule: []
        }
    }

    private static func section(_ title: String) -> ParameterSection {
        ParameterSection.all.first { $0.title == title }!
    }

    @Test("A switch names its choices; a knob has none")
    func choices() {
        #expect(Parameters.named("keyup")!.choices == ["Ignore", "Stop"])
        #expect(Parameters.named("drum")!.isChoice)
        #expect(Parameters.named("release")!.choices.isEmpty)
        #expect(!Parameters.named("release")!.isChoice && !Parameters.named("octave")!.isChoice)
    }

    @Test("Each section has the columns of the mockup")
    func columns() {
        #expect(ParameterSection.all.map { SectionLayout.of($0).columns } == [3, 2, 4, 3, 4, 3, 2])
    }

    @Test("Every control of a section is laid out once, and nothing else")
    func everyControlOnce() {
        for section in ParameterSection.all {
            let laidOut = SectionLayout.of(section).rows.flatMap(Self.ids)
            #expect(laidOut.sorted() == section.parameters.map(\.identifier).sorted(), "\(section.title)")
        }
    }

    @Test("Rows follow the mockup; the switches of Stroke and Master get rows of their own")
    func rows() {
        let rows = ParameterSection.all.map { SectionLayout.of($0).rows.map(Self.ids) }
        #expect(rows[0] == [["attack", "length", "release"], ["damp", "velsens", "vary"], ["keyup"]])
        #expect(rows[1] == [["alternate", "alttune"]])
        #expect(rows[2] == [["scoop", "scooptime", "drift", "drop"], ["wobble", "jump", "jumpratio", "velpitch"]])
        #expect(rows[3] == [["stick", "stickvel", "split"], ["creak", "creakrate", "creakring"]])
        #expect(rows[4] == [["pot", "potq", "potlevel"], ["skin", "skinq", "skinlevel", "track"]])
        #expect(rows[5] == [["rub", "scrape", "shimmer"]])
        #expect(rows[6] == [["volume", "pan"], ["tune", "octave"], ["bendup", "benddown"], ["lfo1rate", "lfo2rate"],
                            [], ["lfo1shape"], ["lfo2shape"], [], ["drum"], ["lfostart"]])
        #expect(SectionLayout.of(Self.section("Stroke")).rows.last == .wide(Parameters.named("keyup")!))
        #expect(SectionLayout.of(Self.section("Master")).rows.last == .wide(Parameters.named("lfostart")!))
    }

    @Test("Master's rules part the knobs from the LFO shapes, and the shapes from Drum and LFO Start")
    func rules() {
        let master = SectionLayout.of(Self.section("Master")).rows
        #expect(master.indices.filter { master[$0] == .rule } == [4, 7])
        for title in ["Stroke", "Hands", "Pitch", "Friction", "Body", "Noise"] {
            #expect(!SectionLayout.of(Self.section(title)).rows.contains(.rule), "\(title)")
        }
    }

    @Test("No row holds more cells than its section has columns")
    func rowsFit() {
        for section in ParameterSection.all {
            let layout = SectionLayout.of(section)
            for row in layout.rows {
                if case .cells(let parameters) = row { #expect(parameters.count <= layout.columns, "\(section.title)") }
            }
        }
    }

    @Test("A section the panel does not know flows in reading order, its switches in rows of their own")
    func unknownSection() {
        let parameters = ["release", "drum", "attack", "length", "keyup"].compactMap(Parameters.named)
        let layout = SectionLayout.of(ParameterSection(title: "Elsewhere", parameters: parameters))
        #expect(layout.columns == 3)
        #expect(layout.rows.map(Self.ids) == [["release", "attack", "length"], ["drum"], ["keyup"]])
    }

    @Test("A control the engine adds to a known section is not lost")
    func addedControl() {
        let friction = Self.section("Friction")
        let added = ParameterSection(title: friction.title, parameters: friction.parameters + [Parameters.named("vary")!])
        let laidOut = SectionLayout.of(added).rows.flatMap(Self.ids)
        #expect(laidOut.last == "vary")
        #expect(laidOut.count == friction.parameters.count + 1)
    }

    @Test("A planned rule with nothing below it is left out")
    func ruleWithoutSwitches() {
        let master = Self.section("Master")
        let knobsOnly = ParameterSection(title: master.title, parameters: master.parameters.filter { !$0.isChoice })
        #expect(!SectionLayout.of(knobsOnly).rows.contains(.rule))
    }

    // MARK: The cards on the panel

    @Test("Two rows of cards as in the mockup, and Master the full height on the right")
    func panelRows() {
        let panel = PanelLayout.of(ParameterSection.all)
        #expect(panel.rows.map { $0.map(\.title) } == [["Stroke", "Hands", "Pitch"], ["Friction", "Body", "Noise"]])
        #expect(panel.side?.title == "Master")
    }

    @Test("Every section is on the panel once; one it does not know joins the last row")
    func panelHoldsEverySection() {
        let extra = ParameterSection(title: "Elsewhere", parameters: [Parameters.named("vary")!])
        let panel = PanelLayout.of(ParameterSection.all + [extra])
        let titles = panel.rows.flatMap { $0.map(\.title) } + [panel.side?.title].compactMap { $0 }
        #expect(titles.sorted() == (ParameterSection.all.map(\.title) + ["Elsewhere"]).sorted())
        #expect(panel.rows.last?.last?.title == "Elsewhere")
    }

    @Test("Without Master there is no card on the right, and a row of missing sections is dropped")
    func panelWithout() {
        let panel = PanelLayout.of(ParameterSection.all.filter { !["Master", "Friction", "Body", "Noise"].contains($0.title) })
        #expect(panel.side == nil)
        #expect(panel.rows.map { $0.map(\.title) } == [["Stroke", "Hands", "Pitch"]])
    }

    @Test("A row's cards share its width in proportion to their columns, after the gaps and their insets")
    func widths() {
        let row = PanelLayout.of(ParameterSection.all).rows[0]          // 3, 2 and 4 columns
        let widths = PanelLayout.widths(of: row, in: 920, spacing: 10, inset: 20)
        // 920 − 2 gaps of 10 − 3 insets of 20 = 840 for 9 columns: 280, 186.7, 373.3, plus the inset.
        #expect(widths.count == 3)
        #expect(abs(widths[0] - 300) < 1e-9)
        #expect(abs(widths[1] - (20 + 840 * 2 / 9)) < 1e-9)
        #expect(abs(widths[2] - (20 + 840 * 4 / 9)) < 1e-9)
        #expect(abs(widths.reduce(0, +) + 20 - 920) < 1e-9)
        #expect(PanelLayout.widths(of: [], in: 920, spacing: 10, inset: 20).isEmpty)
    }
}
