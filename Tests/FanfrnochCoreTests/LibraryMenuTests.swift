import Testing
@testable import FanfrnochCore

/// What the Preset and Kit menus list, what the name popover makes of a name, and how long a
/// file's error stays on screen.
@Suite("Library menus")
struct LibraryMenuTests {

    // MARK: The menus

    @Test("The Preset menu: the presets, the one in use ticked, then Save as… and Delete with every preset")
    func presetMenu() {
        let entries = LibraryMenu.presets(["Bright", "slow growl", "Zambomba 2"], inUse: "slow growl")
        #expect(entries == [
            .file("Bright", ticked: false),
            .file("slow growl", ticked: true),
            .file("Zambomba 2", ticked: false),
            .divider,
            .save("Save as…"),
            .delete("Delete", names: ["Bright", "slow growl", "Zambomba 2"]),
        ])
    }

    @Test("The preset in use is ticked whatever its capitals")
    func tickIgnoresCapitals() {
        #expect(LibraryMenu.presets(["Slow Growl"], inUse: "slow growl").first == .file("Slow Growl", ticked: true))
        #expect(LibraryMenu.presets(["Slow Growl"], inUse: nil).first == .file("Slow Growl", ticked: false))
    }

    @Test("With no presets the menu only saves: no divider, nothing to delete")
    func emptyPresetMenu() {
        #expect(LibraryMenu.presets([], inUse: nil) == [.save("Save as…")])
    }

    @Test("The Kit menu: the kits, then Default kit, Save kit as… and Delete kit")
    func kitMenu() {
        #expect(LibraryMenu.kits(["Live", "Studio"]) == [
            .file("Live", ticked: nil),
            .file("Studio", ticked: nil),
            .divider,
            .standard("Default kit"),
            .save("Save kit as…"),
            .delete("Delete kit", names: ["Live", "Studio"]),
        ])
        #expect(LibraryMenu.kits([]) == [.standard("Default kit"), .save("Save kit as…")])
    }

    @Test("Delete asks first, and says where the file goes")
    func deleteQuestion() {
        #expect(LibraryMenu.deleteQuestion("Bright") == "Delete “Bright”? It goes to the Trash.")
    }

    // MARK: The name popover

    @Test("A name nothing is left of cannot be saved")
    func unusableName() {
        for typed in ["", "   ", "...", "\n\t"] {
            let check = NameCheck(typed, among: ["Bright"])
            #expect(check == .unusable)
            #expect(!check.canSave)
            #expect(check.question == nil)
        }
    }

    @Test("A new name is saved as the file will carry it, without a question")
    func newName() {
        let check = NameCheck("  Growl/low  ", among: ["Bright"])
        #expect(check == .new("Growl-low"))
        #expect(check.canSave)
        #expect(check.question == nil)
    }

    @Test("A name a file has, in any capitals, asks before it replaces that file")
    func replacingName() {
        let check = NameCheck("bright ", among: ["Bright", "Dark"])
        #expect(check == .replaces("Bright"))
        #expect(check.canSave)
        #expect(check.question == "Replace “Bright”?")
    }

    @Test("What is saved is the name as cleaned, in the capitals typed; presets and kits share the rule")
    func savedName() {
        #expect(NameCheck.cleaned("  low/growl ") == "low-growl")
        #expect(NameCheck.cleaned(" . ") == nil)
        for typed in ["  low/growl ", "a:b", ".hidden", String(repeating: "x", count: 70), "\tTab"] {
            #expect(KitLibrary.cleaned(typed) == PresetLibrary.cleaned(typed))
            #expect(NameCheck.cleaned(typed) == PresetLibrary.cleaned(typed))
        }
    }

    @Test("A name longer than a file can carry is cut, then compared")
    func longName() {
        let long = String(repeating: "a", count: 70)
        let kept = String(repeating: "a", count: 60)
        #expect(NameCheck(long, among: []) == .new(kept))
        #expect(NameCheck(long, among: [kept]) == .replaces(kept))
    }

    // MARK: The error line

    @Test("A file's error shows for 4 s after it happened, then goes")
    func errorTiming() {
        let then = ContinuousClock.now
        #expect(ErrorNotice.shownFor == .seconds(4))
        #expect(ErrorNotice.message("Damaged", at: then, now: then) == "Damaged")
        #expect(ErrorNotice.message("Damaged", at: then, now: then + .milliseconds(3_990)) == "Damaged")
        #expect(ErrorNotice.message("Damaged", at: then, now: then + .seconds(4)) == nil)
        #expect(ErrorNotice.message("Damaged", at: then, now: then + .seconds(60)) == nil)
    }

    @Test("No error, or none with a time, shows nothing")
    func noError() {
        let now = ContinuousClock.now
        #expect(ErrorNotice.message(nil, at: now, now: now) == nil)
        #expect(ErrorNotice.message("Damaged", at: nil, now: now) == nil)
    }
}
