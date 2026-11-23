import Testing
@testable import FanfrnochCore

/// How a press on a key or pad becomes a hit.
@Suite("Key strip")
struct KeyStripTests {

    @Test("A press is soft at the top of a key and the hardest hit at its bottom")
    func topToBottom() {
        #expect(KeyStrip.velocity(depth: 0) == 40)
        #expect(KeyStrip.velocity(depth: 1) == 127)
        #expect(KeyStrip.velocity(at: 0, height: 80) == 40)
        #expect(KeyStrip.velocity(at: 80, height: 80) == 127)
    }

    @Test("Further down is firmer, all the way")
    func deeperIsFirmer() {
        let velocities = (0...100).map { KeyStrip.velocity(at: Double($0), height: 100) }
        #expect(velocities == velocities.sorted())
        #expect(Set(velocities).count > 60)             // no flat stretch, no jump
        #expect(zip(velocities, velocities.dropFirst()).allSatisfy { $1 - $0 <= 2 })
    }

    @Test("A press dragged off the key counts as the key's nearest edge")
    func outsideTheKey() {
        #expect(KeyStrip.velocity(depth: -0.4) == 40)
        #expect(KeyStrip.velocity(depth: 1.7) == 127)
        #expect(KeyStrip.velocity(at: -10, height: 80) == 40)
        #expect(KeyStrip.velocity(at: 500, height: 80) == 127)
    }

    @Test("A key with no height is a soft hit, and a velocity is never 0")
    func degenerate() {
        #expect(KeyStrip.velocity(at: 5, height: 0) == 40)
        #expect(KeyStrip.velocity(at: .nan, height: 80) == 40)
        #expect((-5...105).allSatisfy { (1...127).contains(KeyStrip.velocity(at: Double($0), height: 100)) })
    }
}
