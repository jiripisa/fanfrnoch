import Testing
@testable import FanfrnochCore

/// What the panel writes on the pads, where it puts them and when it flashes them.
@Suite("Pad panel")
struct PadPanelTests {

    @Test("Pads are numbered from 01, as people count them")
    func numbers() {
        #expect(PadLabel.number(0) == "01")
        #expect(PadLabel.number(4) == "05")
        #expect(PadLabel.number(15) == "16")
        #expect(PadLabel.title(4, name: "Khomus") == "05 · Khomus")
    }

    @Test("A tile shows the pad's pitch and its group, Off without one")
    func pitchAndGroup() {
        #expect(PadLabel.pitchAndGroup(note: 36, group: 1) == "C2  G1")
        #expect(PadLabel.pitchAndGroup(note: 61, group: 16) == "C♯4  G16")
        #expect(PadLabel.pitchAndGroup(note: 43, group: nil) == "G2  Off")
        #expect(PadLabel.group(nil) == "Off")
        #expect(PadLabel.group(3) == "G3")
    }

    @Test("Send to pad gives the last note played, C2 before any, and asks before it replaces")
    func sendToPad() {
        #expect(PadLabel.sendPitch(lastNote: nil) == 36)
        #expect(PadLabel.sendPitch(lastNote: 48) == 48)
        #expect(PadLabel.sendQuestion(pad: 4, name: "Khomus", lastNote: 48)
                == "Replace pad 05 · Khomus with the keyboard's sound at C3?")
        #expect(PadLabel.sendQuestion(pad: 0, name: "Morsing", lastNote: nil)
                == "Replace pad 01 · Morsing with the keyboard's sound at C2?")
    }

    @Test("Pad 1 is top left and the pads run left to right, row by row, as in the mockup")
    func grid() {
        #expect(PadGrid.rows == 4 && PadGrid.columns == 4)
        #expect(PadGrid.pad(row: 0, column: 0) == 0)
        #expect(PadGrid.pad(row: 0, column: 3) == 3)
        #expect(PadGrid.pad(row: 1, column: 0) == 4)
        #expect(PadGrid.pad(row: 3, column: 3) == 15)
        let all = (0..<PadGrid.rows).flatMap { row in (0..<PadGrid.columns).map { PadGrid.pad(row: row, column: $0) } }
        #expect(all == Array(0..<16))
    }

    @Test("A pad flashes when its hit count rose since the last look, and only then")
    func hits() {
        let before = Array(repeating: 3, count: 16)
        var after = before
        after[2] = 4
        after[9] = 6                                // three hits between two looks: one flash
        #expect(PadGrid.hit(between: before, and: after) == [2, 9])
        #expect(PadGrid.hit(between: after, and: after).isEmpty)
        #expect(PadGrid.hit(between: after, and: before).isEmpty)     // a counter that went back (a new engine)
        #expect(PadGrid.hit(between: [], and: after).isEmpty)          // the first look only takes note
        #expect(PadGrid.flash == .milliseconds(150))
    }

    @Test("Octaves for the pitch menu cover every note once, C-1 to G9")
    func octaves() {
        #expect(Notes.octaves.count == 11)
        #expect(Notes.octaves.first == 0...11)
        #expect(Notes.octaves.last == 120...127)
        #expect(Notes.octaves.flatMap { Array($0) } == Array(Notes.range))
    }
}
