import Foundation
import Testing
@testable import FanfrnochCore

/// The player's presets: one file per preset in a folder, and what a window keeps of them.
@Suite("Preset library")
struct PresetLibraryTests {

    /// A library in a folder of its own that is not there yet. Deleting removes for good here:
    /// the tests have no business in anybody's Trash (or in ~/Library/Application Support/Fanfrnoch).
    static func library(folder: URL? = nil) -> PresetLibrary {
        let folder = folder ?? FileManager.default.temporaryDirectory
            .appendingPathComponent("fanfrnoch-presets-\(UUID().uuidString)").appendingPathComponent("Presets")
        return PresetLibrary(folder: folder, fileExtension: PresetLibrary.fileExtension, deletesForGood: true)
    }

    private func remove(_ library: PresetLibrary) {
        try? FileManager.default.removeItem(at: library.folder.deletingLastPathComponent())
    }

    private func pot() throws -> Parameter { try #require(Parameters.named("pot")) }

    private func sound() throws -> SetState {
        let synth = Synth(sampleRate: 48_000)
        synth.loadProgram(2)
        synth.setValue(777, of: try pot())
        return synth.state.keyboard
    }

    @Test("A folder that is not there yet lists nothing, and the first save makes it")
    func folderIsMade() throws {
        let library = Self.library()
        defer { remove(library) }
        #expect(library.names().isEmpty)
        try library.save(try sound(), as: "First")
        #expect(library.names() == ["First"])
        #expect(FileManager.default.fileExists(atPath: library.folder.appendingPathComponent("First.fanfrnoch").path))
    }

    @Test("The standard libraries live in Fanfrnoch's folder under Application Support, with their extensions")
    func standardPlaces() {
        #expect(PresetLibrary.standard.folder.path.hasSuffix("Application Support/Fanfrnoch/Presets"))
        #expect(PresetLibrary.standard.fileExtension == "fanfrnoch")
        #expect(KitLibrary.standard.folder.path.hasSuffix("Application Support/Fanfrnoch/Kits"))
        #expect(KitLibrary.standard.fileExtension == "fanfrnochkit")
    }

    @Test("A preset goes through its file and comes back the same")
    func roundTrip() throws {
        let library = Self.library()
        defer { remove(library) }
        let set = try sound()
        try library.save(set, as: "Mine")
        #expect(try library.load("Mine") == set)
        #expect(try library.load("mine") == set)
    }

    @Test("Presets are listed as the Finder sorts names, capitals aside; other files are left out")
    func listing() throws {
        let library = Self.library()
        defer { remove(library) }
        let set = try sound()
        for name in ["b 10", "b 2", "Ábel", "a", "B 1"] { try library.save(set, as: name) }
        try Data("notes".utf8).write(to: library.folder.appendingPathComponent("read me.txt"))
        try Data("{}".utf8).write(to: library.folder.appendingPathComponent("Kit.fanfrnochkit"))
        #expect(library.names() == ["a", "Ábel", "B 1", "b 2", "b 10"])
    }

    @Test("A name becomes a file's name: trimmed, without separators or a leading dot, at most 60 characters")
    func names() throws {
        #expect(PresetLibrary.cleaned("  Můj dron \n") == "Můj dron")
        #expect(PresetLibrary.cleaned("in/out: 2") == "in-out- 2")
        #expect(PresetLibrary.cleaned("..hidden") == "hidden")
        #expect(PresetLibrary.cleaned("   ") == nil)
        #expect(PresetLibrary.cleaned(".") == nil)
        #expect(PresetLibrary.cleaned(String(repeating: "x", count: 200))?.count == 60)
        #expect(PresetLibrary.longestName == 60)

        let library = Self.library()
        defer { remove(library) }
        #expect(throws: PresetError.noName) { try library.save(try sound(), as: "  ") }
        #expect(try library.save(try sound(), as: " in/out ") == "in-out")
        #expect(try library.save(try sound(), as: String(repeating: "y", count: 80)).count == 60)
    }

    @Test("Saving under a name that exists replaces that file, however it is capitalised")
    func collision() throws {
        let library = Self.library()
        defer { remove(library) }
        try library.save(SetState(program: 0, values: [:]), as: "Growl")
        try library.save(try sound(), as: "growl")
        #expect(library.names() == ["growl"])
        #expect(try library.load("GROWL").values["pot"] == 777)
        #expect(PresetLibrary.name("gRoWl ", isAmong: library.names()))
        #expect(!PresetLibrary.name("growls", isAmong: library.names()))
    }

    @Test("A save in other capitals whose rename fails keeps the new sound under the old capitals, and says why")
    func collisionWhoseRenameFails() throws {
        var library = Self.library()
        defer { remove(library) }
        try library.save(SetState(program: 0, values: [:]), as: "Growl")
        let sound = try sound()
        library.rename = { _, _ in throw CocoaError(.fileWriteNoPermission) }
        #expect(throws: CocoaError(.fileWriteNoPermission)) { try library.save(sound, as: "growl") }
        #expect(library.names() == ["Growl"])
        #expect(try library.load("Growl").values["pot"] == 777)
        #expect(try FileManager.default.contentsOfDirectory(atPath: library.folder.path) == ["Growl.fanfrnoch"])   // nothing left aside
    }

    @Test("Deleting takes the preset out of the folder; one that is not there cannot be deleted or read")
    func deleting() throws {
        let library = Self.library()
        defer { remove(library) }
        try library.save(try sound(), as: "Gone")
        try library.delete("Gone")
        #expect(library.names().isEmpty)
        #expect(throws: PresetError.missing("Gone")) { try library.delete("Gone") }
        #expect(throws: PresetError.missing("Gone")) { try library.load("Gone") }
    }

    @Test("Two libraries on one folder see each other's saves and deletes")
    func sharedFolder() throws {
        let one = Self.library()
        defer { remove(one) }
        let other = Self.library(folder: one.folder)
        try one.save(try sound(), as: "From one")
        #expect(other.names() == ["From one"])
        try other.save(try sound(), as: "From other")
        #expect(one.names() == ["From one", "From other"])
        try other.delete("From one")
        #expect(one.names() == ["From other"])
        #expect(throws: PresetError.missing("From one")) { try one.load("From one") }
    }

    @Test("Presets and kits may share a folder: each library sees only its own extension")
    func extensionsApart() throws {
        let presets = Self.library()
        defer { remove(presets) }
        let kits = KitLibrary(folder: presets.folder, fileExtension: "fanfrnochkit", deletesForGood: true)
        try presets.save(try sound(), as: "P")
        try kits.save(Kit(name: "K", pads: []), as: "K")
        #expect(presets.names() == ["P"] && kits.names() == ["K"])
    }

    // MARK: What a window keeps

    @Test("A shelf starts with the folder's presets and the one it was told was in use, if it is still there")
    func shelfStarts() throws {
        let library = Self.library()
        defer { remove(library) }
        try library.save(try sound(), as: "Mine")
        let kept = PresetShelf(library: library, inUse: "Mine")
        #expect(kept.names == ["Mine"] && kept.inUse == "Mine")
        #expect(kept.value(of: try pot()) == 777)
        let lost = PresetShelf(library: library, inUse: "Thrown away")
        #expect(lost.inUse == nil)
        #expect(lost.value(of: try pot()) == nil)
        #expect(PresetShelf(library: library, inUse: nil).inUse == nil)
    }

    @Test("Saving makes the preset the one in use, under the name it was stored as, and the file records it")
    func shelfSaves() throws {
        let library = Self.library()
        defer { remove(library) }
        var shelf = PresetShelf(library: library, inUse: nil)
        try shelf.save(try sound(), as: " Mine ")
        #expect(shelf.names == ["Mine"] && shelf.inUse == "Mine")
        #expect(shelf.value(of: try pot()) == 777)
        #expect(try library.load("Mine").preset == "Mine")
        var attempt = shelf
        let set = try sound()
        #expect(throws: PresetError.noName) { try attempt.save(set, as: " ") }
        #expect(shelf.inUse == "Mine")
    }

    @Test("Loading hands over the sound named after its file and makes it the one in use; a failure changes nothing")
    func shelfLoads() throws {
        let library = Self.library()
        defer { remove(library) }
        try library.save(try sound(), as: "Mine")
        var shelf = PresetShelf(library: library, inUse: nil)
        let loaded = try shelf.load("mine")
        #expect(loaded.preset == "Mine" && shelf.inUse == "Mine")
        var attempt = shelf
        #expect(throws: PresetError.missing("Nope")) { try attempt.load("Nope") }
        #expect(shelf.inUse == "Mine")
    }

    @Test("A preset in use counts only while its file exists; its value is the double click's target")
    func shelfFollowsTheFolder() throws {
        let library = Self.library()
        defer { remove(library) }
        var shelf = PresetShelf(library: library, inUse: nil)
        try shelf.save(try sound(), as: "Mine")
        let other = Self.library(folder: library.folder)
        try other.save(try sound(), as: "Another window's")
        let pot = try pot()
        let sawNew = shelf.look()
        #expect(sawNew && shelf.names == ["Another window's", "Mine"])
        let sawNothing = shelf.look()
        #expect(!sawNothing)

        try other.delete("Mine")
        let sawDelete = shelf.look()
        #expect(sawDelete)
        #expect(shelf.inUse == nil && shelf.value(of: pot) == nil)

        try shelf.save(try sound(), as: "Again")
        try shelf.delete("again")
        #expect(shelf.inUse == nil && !shelf.names.contains("Again"))
        shelf.follow("Another window's")
        #expect(shelf.inUse == "Another window's")
        shelf.leave()
        #expect(shelf.inUse == nil)
    }
}
