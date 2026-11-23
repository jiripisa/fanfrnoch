import Testing
import FanfrnochReference

@Suite("Reference") struct ReferenceTests {
    @Test("The prototype renders its default pulls, and renders them the same twice")
    func defaultPulls() {
        let render = PrototypeScores.render(named: "01a_fanfrnoch_default_pulls")
        let events = PrototypeScores.events(render, rate: 48_000)
        let frames = PrototypeScores.frames(render, rate: 48_000)
        let params = [PrototypeScores.referenceParams([:])]
        let a = PrototypeScores.referenceRender(events, frames: frames, params: params, drumCount: 1, rate: 48_000, oversampled: false)
        let b = PrototypeScores.referenceRender(events, frames: frames, params: params, drumCount: 1, rate: 48_000, oversampled: false)
        #expect(a == b)
        #expect(a.count == Int(render.seconds * 48_000))
        #expect((a.map(abs).max() ?? 0) > 0.01)
    }

    @Test("Percent knobs become the prototype's fractions, and a level at its bottom its off")
    func conversion() {
        let p = PrototypeScores.referenceParams(["vary": 50, "split": 70, "rub": -40, "potlevel": 6, "keyup": 1])
        #expect(p.vary == 0.5 && p.split == 0.7 && p.rub == -200 && p.potlevel == 6 && p.keyupStop == 1)
    }

    @Test("The spike's defaults")
    func defaults() {
        var p = FanfrnochRefParams()
        fanfrnoch_ref_default_params(&p)
        #expect(p.attack == 42 && p.length == 230 && p.release == 0.30 && p.stick == 0.88 && p.rub == -10)
        #expect(p.potlevel == -200 && p.skinlevel == -200 && p.skin == 306 && p.shimmer == 0.7)
    }
}
