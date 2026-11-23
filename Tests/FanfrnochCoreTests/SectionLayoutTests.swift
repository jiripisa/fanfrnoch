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
        #expect(Parameters.named("curve")!.choices == ["Glide", "Line", "There and Back", "Step"])
        #expect(Parameters.named("curve")!.isChoice)
        #expect(Parameters.named("ring")!.choices.isEmpty)
        #expect(!Parameters.named("ring")!.isChoice && !Parameters.named("octave")!.isChoice)
    }

    @Test("Each section has the columns of the approved mockup")
    func columns() {
        #expect(ParameterSection.all.map { SectionLayout.of($0).columns } == [2, 2, 3, 2, 3])
    }

    @Test("Every control of a section is laid out once, and nothing else")
    func everyControlOnce() {
        for section in ParameterSection.all {
            let laidOut = SectionLayout.of(section).rows.flatMap(Self.ids)
            #expect(laidOut.sorted() == section.parameters.map(\.identifier).sorted(), "\(section.title)")
        }
    }

    @Test("Rows follow the mockup; switches too wide for a cell get a row of their own")
    func rows() {
        let rows = ParameterSection.all.map { SectionLayout.of($0).rows.map(Self.ids) }
        #expect(rows[0] == [["ring", "edge"], ["offset", "body"], ["buzz", "clang"]])
        #expect(rows[1] == [["velsens", "stroke"], ["damp", "keyup"], ["vary"]])
        #expect(rows[2] == [["vowel", "sweep", "sweeptime"], ["reso", "throat", "throattune"], ["open", "close"], ["curve"]])
        #expect(rows[3] == [["breath", "puff"], ["pufftime", "air"]])
        #expect(rows[4] == [["volume", "pan", "tune"], ["octave", "bendvowel", "lfo1rate"],
                            ["lfo1shape", "lfo2rate", "lfo2shape"], ["lfostart"]])
        let curve = SectionLayout.of(ParameterSection.all[2]).rows.last
        #expect(curve == .wide(Parameters.named("curve")!))
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
        let parameters = ["ring", "stroke", "edge", "offset", "keyup"].compactMap(Parameters.named)
        let layout = SectionLayout.of(ParameterSection(title: "Elsewhere", parameters: parameters))
        #expect(layout.columns == 3)
        #expect(layout.rows.map(Self.ids) == [["ring", "edge", "offset"], ["stroke"], ["keyup"]])
    }

    @Test("A control the engine adds to a known section is not lost")
    func addedControl() {
        let reed = ParameterSection.all[0]
        let added = ParameterSection(title: reed.title, parameters: reed.parameters + [Parameters.named("vary")!])
        let laidOut = SectionLayout.of(added).rows.flatMap(Self.ids)
        #expect(laidOut.last == "vary")
        #expect(laidOut.count == reed.parameters.count + 1)
    }
}
