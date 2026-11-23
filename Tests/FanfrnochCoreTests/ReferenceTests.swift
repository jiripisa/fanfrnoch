import Testing
import FanfrnochReference

@Suite("Reference") struct ReferenceTests {
    @Test("The prototype renders its default phrase, and renders it the same twice")
    func defaultPhrase() {
        let score = PrototypeScores.phrase(note: 36)
        let params = [PrototypeScores.referenceParams([:])]
        let a = PrototypeScores.referenceRender(score, params: params) { _ in 0 }
        let b = PrototypeScores.referenceRender(score, params: params) { _ in 0 }
        #expect(a == b)
        #expect(a.count == Int((PrototypeScores.phraseLength * 96_000).rounded(.down)))
        #expect((a.map(abs).max() ?? 0) > 0.01)
    }
    @Test("Percent knobs become the prototype's fractions")
    func percentConversion() {
        let p = PrototypeScores.referenceParams(["buzz": 70, "breath": -30, "body": -10, "stroke": 0])
        #expect(p.buzz == 0.7 && p.breath == -0.3 && p.bodyDb == -10 && p.stroke == 0)
    }
}
