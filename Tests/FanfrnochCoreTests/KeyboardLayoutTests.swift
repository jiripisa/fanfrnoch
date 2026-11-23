import Testing
@testable import FanfrnochCore

/// The on-screen keyboard's keys and what a click on them plays.
@Suite("Keyboard layout")
struct KeyboardLayoutTests {

    /// 21 white keys of 50 points, 120 points tall.
    private let layout = KeyboardLayout(width: 1050, height: 120)

    @Test("Three octaves, C2 to B4: 21 white keys and 15 black ones")
    func keys() {
        #expect(KeyboardLayout.notes == 36...71)
        #expect(layout.whiteKeys.count == 21)
        #expect(layout.blackKeys.count == 15)
        #expect(layout.whiteKeys.first?.note == 36)
        #expect(layout.whiteKeys.last?.note == 71)
        #expect(Set(layout.whiteKeys.map(\.note) + layout.blackKeys.map(\.note)) == Set(36...71))
        #expect(layout.blackKeys.map(\.note) == [37, 39, 42, 44, 46, 49, 51, 54, 56, 58, 61, 63, 66, 68, 70])
    }

    @Test("White keys share the width; a black key sits on the line between its neighbours")
    func geometry() {
        let c2 = layout.whiteKeys[0], d2 = layout.whiteKeys[1]
        #expect(c2.x == 0 && c2.width == 50 && c2.height == 120)
        #expect(d2.x == 50)
        let cSharp = layout.blackKeys[0]
        #expect(cSharp.width == 31 && cSharp.height == 72)
        #expect(cSharp.x + cSharp.width / 2 == 50)
        #expect(layout.whiteKeys.last.map { $0.x + $0.width } == 1050)
    }

    @Test("Only the Cs are labelled: C2, C3, C4")
    func labels() {
        #expect(KeyboardLayout.notes.compactMap(KeyboardLayout.label) == ["C2", "C3", "C4"])
        #expect(KeyboardLayout.label(36) == "C2")
        #expect(KeyboardLayout.label(37) == nil)
    }

    @Test("A click plays the key under it, a black key over the white one")
    func press() {
        #expect(layout.press(at: 10, y: 100)?.note == 36)       // C2, below the black keys
        #expect(layout.press(at: 45, y: 100)?.note == 36)
        #expect(layout.press(at: 45, y: 30)?.note == 37)        // C♯2, on top
        #expect(layout.press(at: 60, y: 30)?.note == 37)
        #expect(layout.press(at: 60, y: 100)?.note == 38)       // D2 below it
        #expect(layout.press(at: 1049, y: 119)?.note == 71)     // B4
        #expect(layout.press(at: 50 * 3 - 1, y: 10)?.note == 40) // E2: no black key between E and F
    }

    @Test("A click off the strip plays nothing")
    func outside() {
        #expect(layout.press(at: -1, y: 50) == nil)
        #expect(layout.press(at: 1050, y: 50) == nil)
        #expect(layout.press(at: 500, y: -1) == nil)
        #expect(layout.press(at: 500, y: 120) == nil)
        #expect(KeyboardLayout(width: 0, height: 0).press(at: 0, y: 0) == nil)
    }

    @Test("The velocity follows how far down the key the click lands")
    func velocity() {
        #expect(layout.press(at: 10, y: 0)?.velocity == KeyStrip.softest)
        #expect(layout.press(at: 10, y: 119.999)?.velocity == KeyStrip.velocity(at: 119.999, height: 120))
        // A black key is shorter: halfway down it is halfway down its own length.
        #expect(layout.press(at: 50, y: 36)?.velocity == KeyStrip.velocity(depth: 0.5))
        #expect(layout.press(at: 10, y: 60)?.velocity == KeyStrip.velocity(depth: 0.5))
    }
}
