import Testing
@testable import FanfrnochCore

/// Where the panel puts the controls of each section.
@Suite("Section layout")
struct SectionLayoutTests {

    private static func ids(_ row: SectionLayout.Row) -> [String] {
        switch row {
        case .cells(let parameters): parameters.map(\.identifier)
        case .wide(let parameter): [parameter.identifier]
        }
    }

    @Test("A switch names its choices; a knob has none")
    func choices() {
        #expect(Parameters.named("keyup")!.choices == ["Ignore", "Stop"])
        #expect(Parameters.named("drum")!.isChoice)
        #expect(Parameters.named("release")!.choices.isEmpty)
        #expect(!Parameters.named("release")!.isChoice && !Parameters.named("octave")!.isChoice)
    }

    @Test("Each section has its planned columns")
    func columns() {
        #expect(ParameterSection.all.map { SectionLayout.of($0).columns } == [2, 1, 2, 2, 2, 1, 3])
    }

    @Test("Every control of a section is laid out once, and nothing else")
    func everyControlOnce() {
        for section in ParameterSection.all {
            let laidOut = SectionLayout.of(section).rows.flatMap(Self.ids)
            #expect(laidOut.sorted() == section.parameters.map(\.identifier).sorted(), "\(section.title)")
        }
    }

    @Test("Rows follow the plan; LFO Start gets a row of its own")
    func rows() {
        let rows = ParameterSection.all.map { SectionLayout.of($0).rows.map(Self.ids) }
        #expect(rows[0] == [["attack", "length"], ["release", "damp"], ["velsens", "vary"], ["keyup"]])
        #expect(rows[1] == [["alternate"], ["alttune"]])
        #expect(rows[2] == [["scoop", "scooptime"], ["drift", "drop"], ["wobble", "velpitch"], ["jump", "jumpratio"]])
        #expect(rows[3] == [["stick", "stickvel"], ["split", "creak"], ["creakrate", "creakring"]])
        #expect(rows[4] == [["pot", "skin"], ["potq", "skinq"], ["potlevel", "skinlevel"], ["track"]])
        #expect(rows[5] == [["rub"], ["scrape"], ["shimmer"]])
        #expect(rows[6] == [["volume", "pan", "tune"], ["octave", "bendup", "benddown"], ["drum", "lfo1rate", "lfo1shape"],
                            ["lfo2rate", "lfo2shape"], ["lfostart"]])
        let start = SectionLayout.of(ParameterSection.all[6]).rows.last
        #expect(start == .wide(Parameters.named("lfostart")!))
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
        let friction = ParameterSection.all[3]
        let added = ParameterSection(title: friction.title, parameters: friction.parameters + [Parameters.named("vary")!])
        let laidOut = SectionLayout.of(added).rows.flatMap(Self.ids)
        #expect(laidOut.last == "vary")
        #expect(laidOut.count == friction.parameters.count + 1)
    }
}
