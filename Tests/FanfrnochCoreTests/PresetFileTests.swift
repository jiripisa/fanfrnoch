import Foundation
import Testing
@testable import FanfrnochCore

/// A preset or kit file written by another version, or damaged: read as far as it can be, never a crash.
@Suite("Preset files")
struct PresetFileTests {

    private func library() -> PresetLibrary { PresetLibraryTests.library() }

    private func write(_ text: String, as name: String, in library: PresetLibrary, extension ext: String = "fanfrnoch") throws {
        try FileManager.default.createDirectory(at: library.folder, withIntermediateDirectories: true)
        try Data(text.utf8).write(to: library.folder.appendingPathComponent("\(name).\(ext)"))
    }

    private func remove(_ library: PresetLibrary) {
        try? FileManager.default.removeItem(at: library.folder.deletingLastPathComponent())
    }

    @Test("A file with fields missing takes the defaults, and a field of a later version is ignored")
    func tolerant() throws {
        let library = library()
        defer { remove(library) }
        try write(#"{"values":{"pot":50}}"#, as: "No program", in: library)
        try write(#"{"program":3}"#, as: "No values", in: library)
        try write("{}", as: "Empty", in: library)
        try write(#"{"program":2,"values":{"pot":50,"from-the-future":1},"preset":"Old name","midi":[1,2],"colour":"aurora"}"#,
                  as: "Future", in: library)

        #expect(try library.load("No program") == SetState(program: 0, values: ["pot": 50]))
        #expect(try library.load("No values") == SetState(program: 3, values: [:]))
        #expect(try library.load("Empty") == SetState(program: 0, values: [:]))
        let future = try library.load("Future")
        #expect(future.program == 2 && future.values["pot"] == 50 && future.preset == "Old name")
    }

    @Test("A file that is not JSON, or has a field of the wrong type, is an error, not a crash")
    func damaged() throws {
        let library = library()
        defer { remove(library) }
        try write("not a preset", as: "Broken", in: library)
        try write("", as: "Blank", in: library)
        try write(#"{"program":"two"}"#, as: "Wrong type", in: library)
        try write(#"{"values":{"pot":"loud"}}"#, as: "Wrong value", in: library)
        try write("[1,2,3]", as: "Array", in: library)
        for name in ["Broken", "Blank", "Wrong type", "Wrong value", "Array"] {
            #expect(throws: PresetError.unreadable(name)) { try library.load(name) }
        }
        #expect(library.names().count == 5)
    }

    @Test("Errors read as sentences for the menu")
    func messages() {
        #expect(PresetError.noName.errorDescription == "A name is needed.")
        #expect(PresetError.missing("X").errorDescription?.contains("“X”") == true)
        #expect(PresetError.unreadable("X").errorDescription?.contains("damaged") == true)
    }

    @Test("A program number out of range, from a file, is ignored: the set keeps its program and the missing knobs take its values")
    func badProgram() throws {
        for bad in [3_000_000_000, -1, 999] {
            let synth = Synth(sampleRate: 48_000)
            synth.loadProgram(2)
            let release = try #require(Parameters.named("release"))
            synth.setValue(1.5, of: release)
            let set = try JSONDecoder().decode(SetState.self, from: Data(#"{"program":\#(bad),"values":{"pot":600}}"#.utf8))
            synth.apply(set, to: .keyboard)
            #expect(synth.program() == 2, "program \(bad)")
            #expect(abs(synth.value(of: release) - Programs.value(program: 2, parameter: release)) < 1e-4, "program \(bad)")
            #expect(abs(synth.value(of: try #require(Parameters.named("pot"))) - 600) < 1)

            let kit = try JSONDecoder().decode(Kit.self, from: Data(#"{"pads":[{"set":{"program":\#(bad)}}]}"#.utf8))
            synth.apply(kit)
            #expect(synth.program(in: .pad(0)) >= 0)
        }
        #expect(Programs.value(program: 3_000_000_000, parameter: try #require(Parameters.named("release"))) == (try #require(Parameters.named("release"))).defaultValue)
        Synth(sampleRate: 48_000).loadProgram(3_000_000_000)
    }

    @Test("A pad's group outside 1...16 means Off and a note outside 0...127 is ignored, whoever asks")
    func badPad() throws {
        let synth = Synth(sampleRate: 48_000)
        synth.setPadNote(60, pad: 1)
        synth.setPadGroup(4, pad: 1)
        for group in [9_999_999_999, -3, 17, 0] {
            synth.setPadGroup(group, pad: 1)
            #expect(synth.padGroup(1) == nil, "group \(group)")
        }
        for note in [9_999_999_999, -1, 128] {
            synth.setPadNote(note, pad: 1)
            #expect(synth.padNote(1) == 60, "note \(note)")
        }
        let kit = try JSONDecoder().decode(Kit.self, from: Data(#"{"pads":[{"group":9999999999,"note":9999999999},{"group":-5,"note":-2}]}"#.utf8))
        synth.setPadNote(50, pad: 0)
        synth.apply(kit)
        #expect(synth.padGroup(0) == nil && synth.padGroup(1) == nil)
        #expect(synth.padNote(0) == 50)
    }

    @Test("Control characters are stripped from a name")
    func controlCharacters() {
        #expect(PresetLibrary.cleaned("a\u{0}b\u{7}c") == "abc")
        #expect(PresetLibrary.cleaned("\u{0}") == nil)
    }
}
