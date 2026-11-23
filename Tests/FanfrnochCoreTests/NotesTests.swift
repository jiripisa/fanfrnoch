import Testing
@testable import FanfrnochCore

/// Note names as the app shows them: C2 is note 36.
@Suite("Notes")
struct NotesTests {

    @Test("Names follow the octave numbering where C2 is note 36")
    func names() {
        #expect(Notes.name(36) == "C2")
        #expect(Notes.name(60) == "C4")
        #expect(Notes.name(61) == "C♯4")
        #expect(Notes.name(0) == "C-1")
        #expect(Notes.name(127) == "G9")
    }

    @Test("Every note has a name of its own; one outside the range is the nearest")
    func range() {
        #expect(Set(Notes.range.map(Notes.name)).count == 128)
        #expect(Notes.name(-5) == "C-1")
        #expect(Notes.name(200) == "G9")
    }
}
