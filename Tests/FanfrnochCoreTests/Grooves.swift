/// One MIDI message of a score, `time` seconds after its start.
struct GrooveEvent {
    let time: Double
    let status: UInt8
    let data1: UInt8
    let data2: UInt8

    init(_ time: Double, _ status: UInt8, _ data1: UInt8, _ data2: UInt8) {
        self.time = time
        self.status = status
        self.data1 = data1
        self.data2 = data2
    }
}

/// Scores the tests and the listening renders share.
enum Grooves {

    /// The velocity byte of an accent (0...1).
    static func velocity(_ accent: Float) -> UInt8 { UInt8((accent * 127).rounded()) }

    /// The default kit, every pad, 4 bars at 100 BPM, as (time, pad, accent): the two hands of the
    /// low drum (pads 1 and 2, group 1) on the beats, the high drum (pads 3 and 4, group 2) on the
    /// offbeats, the Brummtopf (5 and 6) and the cuíca (7-9, group 4) between them, the zambomba
    /// without and with its jump (10 and 11) in turn, and the pads with Group Off once each.
    static let defaultKitHits: [(time: Double, pad: Int, accent: Float)] = {
        let sixteenth = 60.0 / 100.0 / 4
        var hits: [(time: Double, pad: Int, accent: Float)] = []
        func hit(_ bar: Int, _ step: Int, pad: Int, _ accent: Float) {
            hits.append((0.2 + Double(bar * 16 + step) * sixteenth, pad, accent))
        }
        for bar in 0..<4 {
            for step in [0, 8] { hit(bar, step, pad: 0, 0.95) }
            for step in [4, 12] { hit(bar, step, pad: 1, 0.8) }
            for step in [6, 14] { hit(bar, step, pad: 2, 0.6) }
            hit(bar, 10, pad: 3, 0.5)
            hit(bar, 2, pad: 4, 0.7)
            hit(bar, 11, pad: 5, 0.6)
            for step in [3, 7] { hit(bar, step, pad: 6, 0.5) }
            hit(bar, 15, pad: 7, 0.6)
            if bar == 3 { hit(bar, 0, pad: 8, 0.8) }
            hit(bar, 13, pad: bar % 2 == 0 ? 9 : 10, 0.7)
        }
        hit(0, 0, pad: 11, 0.8)
        hit(1, 0, pad: 12, 0.8)
        hit(1, 8, pad: 13, 0.9)
        hit(2, 4, pad: 14, 0.9)
        hit(3, 8, pad: 15, 0.8)
        return hits.enumerated().sorted { ($0.element.time, $0.offset) < ($1.element.time, $1.offset) }.map(\.element)
    }()

    /// The same as MIDI events: a pad is hit by the note 36 + its index.
    static let defaultKit: [GrooveEvent] = defaultKitHits.map {
        GrooveEvent($0.time, 0x90, UInt8(36 + $0.pad), velocity($0.accent))
    }

    /// The kit's length: the last bar and a 2 s tail.
    static let defaultKitLength = 0.2 + 16 * 60.0 / 100 + 2.0
}
