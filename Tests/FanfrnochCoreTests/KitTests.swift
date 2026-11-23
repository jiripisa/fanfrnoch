import Foundation
import Testing
@testable import FanfrnochCore

/// A kit: all sixteen pads under one name, in a file.
@Suite("Kits")
struct KitTests {

    private func library() -> KitLibrary {
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent("fanfrnoch-kits-\(UUID().uuidString)").appendingPathComponent("Kits")
        return KitLibrary(folder: folder, fileExtension: KitLibrary.fileExtension, deletesForGood: true)
    }

    private func remove(_ library: KitLibrary) {
        try? FileManager.default.removeItem(at: library.folder.deletingLastPathComponent())
    }

    private func pot() throws -> Parameter { try #require(Parameters.named("pot")) }

    @Test("A kit goes through its file into another synth, pad for pad")
    func roundTrip() throws {
        let library = library()
        defer { remove(library) }
        let source = Synth(sampleRate: 48_000)
        for pad in 0..<16 {
            source.setValue(Float(200 + pad * 80), of: try pot(), in: .pad(pad))
            source.setPadNote(40 + pad, pad: pad)
            source.setPadGroup(pad % 3 == 0 ? nil : pad, pad: pad)
        }
        source.loadProgram(2, into: .pad(5))
        var kit = source.kit
        kit.name = "Mine"
        #expect(kit.pads.count == 16)
        try library.save(kit, as: "Mine")
        #expect(library.names() == ["Mine"])
        #expect(FileManager.default.fileExists(atPath: library.folder.appendingPathComponent("Mine.fanfrnochkit").path))

        let loaded = try library.load("Mine")
        #expect(loaded == kit)
        let target = Synth(sampleRate: 48_000)
        target.apply(loaded)
        #expect(target.state.pads == source.state.pads)
    }

    @Test("Applying a kit leaves the mode and the keyboard set alone")
    func keyboardUntouched() throws {
        let source = Synth(sampleRate: 48_000)
        source.setValue(555, of: try pot(), in: .pad(0))
        source.setPadNote(70, pad: 0)
        let kit = source.kit

        let target = Synth(sampleRate: 48_000)
        target.mode = .keyboard
        target.loadProgram(3)
        target.setValue(900, of: try pot())
        let keyboard = target.state.keyboard
        target.apply(kit)
        #expect(target.mode == .keyboard)
        #expect(target.state.keyboard == keyboard)
        let pot = try pot()
        #expect(target.padNote(0) == 70 && abs(target.value(of: pot, in: .pad(0)) - 555) < 1)

        target.mode = .pads
        target.apply(kit)
        #expect(target.mode == .pads)
    }

    @Test("A kit of fewer than sixteen pads leaves the other pads alone")
    func fewerPads() throws {
        let synth = Synth(sampleRate: 48_000)
        synth.setPadNote(70, pad: 9)
        var kit = synth.kit
        kit.pads = Array(kit.pads.prefix(2))
        kit.pads[1].note = 99
        synth.apply(kit)
        #expect(synth.padNote(1) == 99 && synth.padNote(9) == 70)
    }

    @Test("A kit file with fields missing takes the defaults; unknown fields are ignored; damage is an error")
    func tolerantAndDamaged() throws {
        let library = library()
        defer { remove(library) }
        try library.makeFolder()
        func write(_ text: String, _ name: String) throws {
            try Data(text.utf8).write(to: library.folder.appendingPathComponent("\(name).fanfrnochkit"))
        }
        try write("{}", "Empty")
        try write(#"{"name":"Hi","pads":[{"set":{}},{"note":50,"group":2,"extra":1}],"future":true}"#, "Part")
        try write("nope", "Broken")
        try write(#"{"pads":"many"}"#, "Wrong")

        #expect(try library.load("Empty") == Kit(name: "", pads: []))
        let part = try library.load("Part")
        #expect(part.name == "Hi" && part.pads.count == 2)
        #expect(part.pads[0].note == 36 && part.pads[1].note == 50 && part.pads[1].group == 2)
        #expect(throws: PresetError.unreadable("Broken")) { try library.load("Broken") }
        #expect(throws: PresetError.unreadable("Wrong")) { try library.load("Wrong") }
    }

    @Test("A pad is named by its preset, else its program, else Custom")
    func padNames() {
        #expect(PadLabel.name(program: 0, preset: "Mine") == "Mine")
        #expect(PadLabel.name(program: 0, preset: nil) == Programs.names[0])
        #expect(PadLabel.name(program: 0, preset: "") == Programs.names[0])
        #expect(PadLabel.name(program: -1, preset: nil) == "Custom")
        #expect(PadLabel.name(program: 999, preset: nil) == "Custom")
        #expect(PadLabel.name(program: -1, preset: "Mine") == "Mine")
    }
}
