import FanfrnochDSP
import Testing
@testable import FanfrnochCore

/// What the standalone app decides without its window: when it writes the sound to its settings,
/// which notes it lets go of when it loses the mouse, and how it names and plays the pads.
@Suite("Saving after edits")
struct SaveDebounceTests {

    private let start = ContinuousClock.now

    @Test("Nothing is due before an edit")
    func idle() {
        let debounce = SaveDebounce()
        #expect(!debounce.isPending)
        #expect(!debounce.isDue(at: start + .seconds(10)))
    }

    @Test("An edit is saved half a second after it, not before")
    func halfASecond() {
        var debounce = SaveDebounce()
        debounce.edited(at: start)
        #expect(debounce.isPending)
        #expect(!debounce.isDue(at: start + .milliseconds(499)))
        #expect(debounce.isDue(at: start + .milliseconds(500)))
        #expect(SaveDebounce.delay == .milliseconds(500))
    }

    @Test("Every edit puts the save off again: a knob drag is one save, after it ends")
    func dragIsOneSave() {
        var debounce = SaveDebounce()
        for step in 0..<10 { debounce.edited(at: start + .milliseconds(100 * step)) }
        #expect(!debounce.isDue(at: start + .milliseconds(1_300)))
        #expect(debounce.isDue(at: start + .milliseconds(1_400)))
    }

    @Test("After a save nothing is due until the next edit")
    func saved() {
        var debounce = SaveDebounce()
        debounce.edited(at: start)
        debounce.saved()
        #expect(!debounce.isPending)
        #expect(!debounce.isDue(at: start + .seconds(1)))
        debounce.edited(at: start + .seconds(2))
        #expect(debounce.isDue(at: start + .milliseconds(2_500)))
    }
}

@Suite("Notes held on screen")
struct HeldNotesTests {

    @Test("Keys and pads held are let go together; pads as their notes, 36 + pad")
    func releaseAll() {
        var held = HeldNotes()
        held.keyDown(60)
        held.keyDown(64)
        held.padDown(3)
        #expect(held.releaseAll() == [39, 60, 64])
        #expect(held.isEmpty)
        #expect(held.releaseAll().isEmpty)
    }

    @Test("What was let go by the mouse is not let go again")
    func letGo() {
        var held = HeldNotes()
        held.keyDown(60)
        held.keyUp(60)
        held.padDown(0)
        held.padUp(0)
        #expect(held.isEmpty)
        #expect(held.releaseAll().isEmpty)
    }

    @Test("A key and a pad on the same note end with one note-off")
    func sameNote() {
        var held = HeldNotes()
        held.keyDown(36)
        held.padDown(0)
        #expect(held.releaseAll() == [36])
    }

    @Test("A pad outside 0...15 is never held")
    func badPad() {
        var held = HeldNotes()
        held.padDown(16)
        held.padDown(-1)
        #expect(held.isEmpty)
    }
}

@Suite("Pads in the app")
struct AppPadTests {

    @Test("A pad plays note 36 + pad, the engine's first pad note")
    func notes() {
        #expect(PadGrid.note(ofPad: 0) == Int(FANFRNOCH_FIRST_PAD_NOTE))
        #expect(PadGrid.note(ofPad: 15) == 51)
    }

    @Test("A stored selected pad comes back within 0...15")
    func storedPad() {
        #expect(PadGrid.pad(stored: 7) == 7)
        #expect(PadGrid.pad(stored: -3) == 0)
        #expect(PadGrid.pad(stored: 40) == 15)
    }

    @Test("A pad is named after the program last loaded into it")
    func names() {
        #expect(PadLabel.name(program: 0) == Programs.names[0])
        #expect(PadLabel.name(program: Programs.names.count - 1) == Programs.names.last)
        #expect(PadLabel.name(program: -1) == "Custom")
        #expect(PadLabel.name(program: Programs.names.count) == "Custom")
    }

    @Test("Send to pad's pitch on screen is the one the engine gives the pad")
    func sendPitchAgrees() {
        let synth = Synth()
        synth.sendToPad(2)                              // no note played yet
        #expect(synth.padNote(2) == PadLabel.sendPitch(lastNote: synth.lastNote))

        synth.noteOn(55)
        var out = [Float](repeating: 0, count: 256)
        out.withUnsafeMutableBufferPointer { synth.render(left: $0.baseAddress!, right: nil, frames: 256) }
        #expect(synth.lastNote == 55)
        synth.sendToPad(3)
        #expect(synth.padNote(3) == PadLabel.sendPitch(lastNote: synth.lastNote))
    }
}
