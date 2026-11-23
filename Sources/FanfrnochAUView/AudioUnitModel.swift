import AudioToolbox
import FanfrnochCore
import FanfrnochUI
import Observation

/// The panel's model in a host, over the Audio Unit and its engine.
///
/// - The keyboard's set is the unit's parameters (their values are the engine's plain values, a
///   parameter's ID is its index). Knobs set them with `AUParameterSet` and gesture events, so
///   that a host records automation; its programs are the unit's factory presets.
/// - Everything else is no parameter: the pads' sets, notes and groups, the mode, the MIDI
///   controllers and learning, and the keys and pads played on screen go straight to the unit's
///   engine (`kFanfrnochProperty_Engine`). The selected pad and the preset each set came from are the
///   unit's own properties (`kFanfrnochProperty_SelectedPad`, `kFanfrnochProperty_PresetNames`), saved
///   with its state. After such an edit the unit is told (`kFanfrnochProperty_StateChanged`) and the
///   host marks the project edited.
/// - The player's presets and kits are files the app shares with the plug-in (`PresetShelves`). A
///   preset loaded into the keyboard set goes in as the unit's parameters, so that the host hears
///   of every value, and becomes the unit's present preset by name (number -1, as a host's own):
///   the host shows it.
///
/// A host changes parameters and restores projects without telling a view, so the panel asks for
/// the present state every 40 ms: see `refresh`.
///
/// The engine is borrowed from the unit. Before each use the model asks the unit for it again;
/// once the unit no longer gives the same engine (the host disposed of it while the window was
/// still shown), the model is detached: it never touches the unit or the engine again.
@MainActor
@Observable
public final class AudioUnitModel: InstrumentModel {

    @ObservationIgnored private let unit: AudioUnit
    /// The unit's engine, borrowed: the unit owns it. Used only while `isAttached`.
    @ObservationIgnored private let engine: OpaquePointer
    @ObservationIgnored private let synth: Synth
    /// True once the unit was found gone: nothing is asked of it or its engine any more.
    @ObservationIgnored private(set) var isDetached = false
    /// When the host is to hear that the pads or the mode changed: half a second after the last
    /// such edit, so that a drag, which edits many times a second, is told once.
    @ObservationIgnored private var hostNotice = SaveDebounce()
    /// The keys and pads the mouse holds, let go of when the window closes.
    @ObservationIgnored private var held = HeldNotes()
    /// The presets in use as the unit holds them, the keyboard's first, "" for none, as of the last
    /// look or write. A set keeps the unit's name until the window changes that set, even when this
    /// Mac's folder lacks the preset: the project keeps it for a Mac that has it.
    @ObservationIgnored private var unitNames: [String]
    /// The engine's count of what MIDI changed, as of the last look.
    @ObservationIgnored private var seenChanges: UInt32

    /// Every set, as the panel names them: the keyboard's, then the pads'.
    private static let sets = [SoundSet.keyboard] + (0..<PadGrid.count).map(SoundSet.pad)

    // What the panel shows, mirrored from the unit and the engine: the panel sees only what
    // changes here.

    /// Knob positions (0...1) by parameter index, for every set.
    private var positions: [SoundSet: [Float]]
    /// The program each set last loaded.
    private var programs: [SoundSet: Int]
    private var padNotes: [Int]
    private var padGroups: [Int?]
    /// The pads' hit counters as of the last `refresh`.
    private var hits: [Int]
    public private(set) var lastNote: Int?
    private var playMode: PlayMode
    private var pad: Int
    /// The presets and kits in the folders, and the preset each set came from.
    private var shelves: PresetShelves
    /// The MIDI controller of each parameter by index; nil for none.
    private var controllers: [Int?]
    /// The keyboard knob that takes the next controller that moves; nil while none is learning.
    public private(set) var learning: Parameter?
    /// What went wrong with a file the last time, in words for the panel, and when.
    public private(set) var lastError: String? = nil
    public private(set) var lastErrorTime: ContinuousClock.Instant? = nil

    /// A switch between the keyboard and the pads calls off a learn: in pad mode the knobs show a
    /// pad, which has no controllers.
    public var mode: PlayMode {
        get { playMode }
        set {
            guard newValue != playMode, isAttached else { return }
            synth.mode = newValue
            playMode = synth.mode
            learn(nil)
            edited()
        }
    }

    /// The pad the knobs edit in pad mode. The unit keeps it and saves it with the project, so a
    /// window opens on the pad it was closed on. Choosing a pad is no edit of the project: it is
    /// saved whenever the project is, without the host being told.
    public var selectedPad: Int {
        get { pad }
        set {
            guard newValue != pad else { return }
            pad = newValue
            guard isAttached, PadGrid.count > newValue, newValue >= 0 else { return }
            var stored = UInt32(newValue)
            AudioUnitSetProperty(unit, Self.selectedPadProperty, kAudioUnitScope_Global, 0, &stored,
                                 UInt32(MemoryLayout<UInt32>.size))
            mirror(.pad(newValue))
        }
    }

    public var shownSet: SoundSet { playMode == .keyboard ? .keyboard : .pad(selectedPad) }

    /// The model of a unit's window; nil for a unit that does not hand out its engine (not Fanfrnoch's).
    /// `presets` and `kits` are where the player's files are kept: the folders the app reads too.
    public init?(unit: AudioUnit, presets: PresetLibrary = .standard, kits: KitLibrary = .standard) {
        guard let engine = Self.engine(of: unit) else { return nil }
        self.unit = unit
        self.engine = engine
        let synth = Synth(borrowing: engine)
        self.synth = synth
        positions = Dictionary(uniqueKeysWithValues: Self.sets.map { set in
            (set, set == .keyboard ? Self.keyboardPositions(of: unit) : Self.positions(in: set, of: synth))
        })
        programs = Self.programs(of: synth)
        padNotes = Self.padNotes(of: synth)
        padGroups = (0..<PadGrid.count).map(synth.padGroup)
        hits = (0..<PadGrid.count).map(synth.padHits)
        lastNote = synth.lastNote
        playMode = synth.mode
        pad = Self.selectedPad(of: unit) ?? 0
        let names = Self.presetNames(of: unit) ?? Array(repeating: "", count: PresetShelves.count)
        unitNames = names
        shelves = PresetShelves(presets: presets, kits: kits, inUse: names.map(Self.name))
        controllers = Self.controllers(of: synth)
        learning = synth.learning
        seenChanges = synth.changes
        followTheHostsProgram()
    }

    /// Takes over what changed elsewhere since the last look: the host's automation, presets and
    /// restored projects, and on the audio thread the pads hit (also from MIDI) and the last note.
    /// Tells the host of the window's pad edits once they have rested.
    public func refresh() {
        guard isAttached else { return }
        // A restored project brings its own selected pad and presets in use.
        if let stored = Self.selectedPad(of: unit), stored != pad { pad = stored }
        if let names = Self.presetNames(of: unit), names != unitNames {
            for (index, set) in Self.sets.enumerated() where names[index] != unitNames[index] {
                shelves.follow(Self.name(names[index]), in: set)
            }
            unitNames = names
        }
        followTheHostsProgram()
        let keyboard = Self.keyboardPositions(of: unit)
        if keyboard != positions[.keyboard] { positions[.keyboard] = keyboard }
        if case .pad = shownSet { mirror(shownSet) }          // a restored project changes the pads too
        let programs = Self.programs(of: synth)
        if programs != self.programs { self.programs = programs }
        let notes = Self.padNotes(of: synth)
        if notes != padNotes { padNotes = notes }
        let groups = (0..<PadGrid.count).map(synth.padGroup)
        if groups != padGroups { padGroups = groups }
        let hits = (0..<PadGrid.count).map(synth.padHits)
        if hits != self.hits { self.hits = hits }
        let note = synth.lastNote
        if note != lastNote { lastNote = note }
        let mode = synth.mode
        if mode != playMode {
            playMode = mode
            learn(nil)
        }
        // A controller learnt from MIDI is the window's edit, which the project keeps; one a
        // restored project brought is not.
        let changes = synth.changes
        let controllers = Self.controllers(of: synth)
        if controllers != self.controllers {
            self.controllers = controllers
            if changes != seenChanges { edited() }
        }
        seenChanges = changes
        let learning = synth.learning
        if learning != self.learning { self.learning = learning }
        if hostNotice.isDue(at: .now) { tellHost() }
    }

    // MARK: Knobs and programs

    public func program(in set: SoundSet) -> Int {
        programs[set] ?? 0          // a pad outside 0...15, as `Synth` reads it
    }

    /// Into the keyboard as the unit's factory preset, so that the host shows it; into a pad
    /// through the engine.
    public func loadProgram(_ index: Int, into set: SoundSet) {
        guard Programs.names.indices.contains(index), positions[set] != nil, isAttached else { return }
        if set == .keyboard {
            guard setPresentPreset(number: index, name: Programs.names[index]) else { return }
            everyParameterMoved()
        } else {
            synth.loadProgram(index, into: set)
            mirror(set)
            edited()
        }
        changingPresets { shelves.leave(set); return [set] }
    }

    public func position(of parameter: Parameter, in set: SoundSet) -> Double {
        Double(positions[set]?[parameter.index] ?? parameter.normalised(parameter.defaultValue))
    }

    public func setPosition(_ position: Double, of parameter: Parameter, in set: SoundSet) {
        guard positions[set] != nil, isAttached else { return }
        let plain = parameter.plain(Float(min(max(position, 0), 1)))      // integers and choices on their step
        if set == .keyboard {
            var address = address(of: parameter)
            AUParameterSet(nil, nil, &address, plain, 0)      // sets the value and tells the host's listeners
            positions[set]?[parameter.index] = parameter.normalised(plain)
        } else {
            synth.setValue(plain, of: parameter, in: set)
            positions[set]?[parameter.index] = synth.normalisedValue(of: parameter, in: set)
            edited()
        }
    }

    /// To the value of the set's preset in use, otherwise of its program, otherwise the default.
    public func resetToDefault(_ parameter: Parameter, in set: SoundSet) {
        let plain = shelves.resetValue(of: parameter, in: set, program: program(in: set))
        setPosition(Double(parameter.normalised(plain)), of: parameter, in: set)
    }

    /// A host records automation between the two. The pads' knobs are no parameters of the unit:
    /// there is nothing to record.
    public func beginEditing(_ parameter: Parameter, in set: SoundSet) {
        if set == .keyboard, isAttached { notify(.beginParameterChangeGesture, parameter) }
    }

    public func endEditing(_ parameter: Parameter, in set: SoundSet) {
        if set == .keyboard, isAttached { notify(.endParameterChangeGesture, parameter) }
    }

    // MARK: Pads

    public func padNote(_ pad: Int) -> Int {
        padNotes.indices.contains(pad) ? padNotes[pad] : PadGrid.note(ofPad: pad)
    }

    public func setPadNote(_ note: Int, pad: Int) {
        guard padNotes.indices.contains(pad), isAttached else { return }
        synth.setPadNote(note, pad: pad)
        padNotes[pad] = synth.padNote(pad) ?? note
        edited()
    }

    public func padGroup(_ pad: Int) -> Int? {
        padGroups.indices.contains(pad) ? padGroups[pad] : nil
    }

    public func setPadGroup(_ group: Int?, pad: Int) {
        guard padGroups.indices.contains(pad), isAttached else { return }
        synth.setPadGroup(group, pad: pad)
        padGroups[pad] = synth.padGroup(pad)
        edited()
    }

    public func padName(_ pad: Int) -> String {
        PadLabel.name(program: program(in: .pad(pad)), preset: shelves.inUse(in: .pad(pad)))
    }

    public func padHits(_ pad: Int) -> Int {
        hits.indices.contains(pad) ? hits[pad] : 0
    }

    /// The engine copies its keyboard set, which takes the unit's parameters at the next render:
    /// they go to the engine first, so that a knob just turned or a program just chosen is sent
    /// too, whether the host renders or not. The pad comes from the keyboard's preset in use, too.
    public func sendToPad(_ pad: Int) {
        guard padNotes.indices.contains(pad), isAttached else { return }
        for parameter in Parameters.all {
            synth.setValue(Self.value(of: parameter, in: unit), of: parameter, in: .keyboard)
        }
        synth.sendToPad(pad)
        mirror(.pad(pad))
        padNotes[pad] = synth.padNote(pad) ?? padNotes[pad]
        edited()
        changingPresets { shelves.follow(shelves.inUse(in: .keyboard), in: .pad(pad)); return [.pad(pad)] }
    }

    // MARK: Presets

    public var presets: [String] { shelves.presets }

    public func presetInUse(in set: SoundSet) -> String? {
        shelves.inUse(in: set)
    }

    /// Into the keyboard as the unit's parameters, each set as a host sets one, and then named as
    /// the unit's present preset; into a pad through the engine.
    public func loadPreset(_ name: String, into set: SoundSet) throws {
        guard positions[set] != nil, isAttached else { return }
        try changingPresets {
            let state = try reporting { try shelves.load(name, into: set) }
            if set == .keyboard {
                putIntoKeyboard(state, named: shelves.inUse(in: .keyboard) ?? name)
            } else {
                synth.apply(state, to: set)
                mirror(set)
                edited()
            }
            return [set]
        }
    }

    /// Saves a set's sound as the unit and its engine hold it now.
    public func savePreset(as name: String, from set: SoundSet) throws {
        guard positions[set] != nil, isAttached else { return }
        let state = set == .keyboard ? keyboardState() : synth.state(of: set)
        try changingPresets {
            try reporting { try shelves.save(state, as: name, from: set) }
            if set == .keyboard, let stored = shelves.inUse(in: .keyboard) { setPresentPreset(number: -1, name: stored) }
            return [set]
        }
    }

    /// The sounds stay; the sets that came from the preset come from none any more.
    public func deletePreset(_ name: String) throws {
        guard isAttached else { return }
        try changingPresets {
            try reporting { try shelves.delete(name) }
            return []
        }
    }

    /// Reads the folders again (a menu opens): another window or the app may have saved or deleted
    /// a preset or a kit. What the unit names stays as it is: a preset this Mac does not have is
    /// not in use here, but the project keeps it.
    public func lookAtPresets() {
        var looked = shelves                // the model changes only when the folders did
        if looked.look() { shelves = looked }
    }

    // MARK: Kits

    public var kits: [String] { shelves.kits }

    /// Replaces the pads, their notes, groups and sounds, with a kit's, through the engine. The
    /// mode and the keyboard set stay.
    public func loadKit(_ name: String) throws {
        guard isAttached else { return }
        try changingPresets {
            let kit = try reporting { try shelves.loadKit(name) }
            synth.apply(kit)
            padsMoved()
            return (0..<min(kit.pads.count, PadGrid.count)).map(SoundSet.pad)
        }
    }

    /// The engine's own kit into every pad.
    public func loadDefaultKit() {
        guard isAttached else { return }
        changingPresets {
            synth.loadDefaultKit()
            shelves.leavePads()
            padsMoved()
            return (0..<PadGrid.count).map(SoundSet.pad)
        }
    }

    public func saveKit(as name: String) throws {
        guard isAttached else { return }
        let kit = synth.kit
        try reporting { try shelves.saveKit(kit, as: name) }
    }

    public func deleteKit(_ name: String) throws {
        guard isAttached else { return }
        try reporting { try shelves.deleteKit(name) }
    }

    // MARK: MIDI controllers

    public func controller(of parameter: Parameter) -> Int? {
        controllers.indices.contains(parameter.index) ? controllers[parameter.index] : nil
    }

    public func setController(_ controller: Int?, of parameter: Parameter) {
        guard isAttached else { return }
        synth.setController(controller, of: parameter)
        controllersMoved()
    }

    public func resetControllers() {
        guard isAttached else { return }
        synth.resetControllers()
        controllersMoved()
    }

    /// Starts learning for a knob of the keyboard set, or calls it off (nil).
    public func learn(_ parameter: Parameter?) {
        guard isAttached else {
            learning = nil                  // nothing learns in a unit that is gone
            return
        }
        synth.learn(parameter)
        let now = synth.learning
        if now != learning { learning = now }
    }

    /// The window goes away: it lets go of the keys and pads it holds (their mouse-up never
    /// comes), calls off a learn (no knob is left listening) and tells the host of an edit still
    /// waiting.
    public func windowClosed() {
        releaseHeld()
        learn(nil)
        tellHostIfEdited()
    }

    // MARK: Playing on screen

    /// Selects the pad too, so that the knobs show what was just heard.
    public func hitPad(_ pad: Int, velocity: Int) {
        guard padNotes.indices.contains(pad), isAttached else { return }
        selectedPad = pad
        held.padDown(pad)
        synth.noteOn(PadGrid.note(ofPad: pad), velocity: velocity)
    }

    public func releasePad(_ pad: Int) {
        guard padNotes.indices.contains(pad), isAttached else { return }
        held.padUp(pad)
        synth.noteOff(PadGrid.note(ofPad: pad))
    }

    public func keyDown(_ note: Int, velocity: Int) {
        guard isAttached else { return }
        held.keyDown(note)
        synth.noteOn(note, velocity: velocity)
    }

    public func keyUp(_ note: Int) {
        guard isAttached else { return }
        held.keyUp(note)
        synth.noteOff(note)
    }

    /// Lets go of every key and pad the mouse holds: when the window closes, the mouse-up may
    /// never arrive.
    public func releaseHeld() {
        let notes = held.releaseAll()
        guard isAttached else { return }
        for note in notes { synth.noteOff(note) }
    }

    // MARK: Telling the host

    /// The pads, the mode, the selection, the presets in use or the controllers changed: tell the
    /// host once the edits have rested.
    private func edited() {
        hostNotice.edited(at: .now)
    }

    /// Tells the host now if an edit is waiting: when the window closes.
    public func tellHostIfEdited() {
        if hostNotice.isPending, isAttached { tellHost() }
    }

    /// The unit tells the host its saved state changed, and the host marks the project edited.
    private func tellHost() {
        hostNotice.saved()
        var any: UInt32 = 1
        AudioUnitSetProperty(unit, Self.stateChangedProperty, kAudioUnitScope_Global, 0, &any, UInt32(MemoryLayout<UInt32>.size))
    }

    // MARK: Presets in use and controllers

    /// Does what changes the presets in use (`body` returns the sets it put a sound into), then
    /// gives the unit the names: those of the sets `body` names, and of every set whose preset
    /// changed. Nothing is written when `body` throws.
    private func changingPresets(_ body: () throws -> [SoundSet]) rethrows {
        let before = shelves.namesInUse
        let touched = try body()
        let after = shelves.namesInUse
        var names = unitNames
        for (index, set) in Self.sets.enumerated() where before[index] != after[index] || touched.contains(set) {
            names[index] = after[index] ?? ""
        }
        guard names != unitNames, setPresetNames(names) else { return }
        unitNames = names
        edited()
    }

    /// A host that chose one of the unit's factory presets loaded a program into the keyboard set:
    /// its sound no longer comes from a preset of the player's, which the window always names with
    /// the number -1.
    private func followTheHostsProgram() {
        guard !unitNames[0].isEmpty, Self.presentPresetNumber(of: unit) >= 0 else { return }
        changingPresets { shelves.leave(.keyboard); return [.keyboard] }
    }

    /// Puts a preset into the keyboard set as a host would: each value through the parameter, the
    /// host told of every one and then of all at once; then the program it grew from, and its name
    /// as the unit's present preset.
    private func putIntoKeyboard(_ state: SetState, named name: String) {
        let resolved = state.resolved(currentProgram: synth.program(in: .keyboard))
        for parameter in Parameters.all {
            var address = address(of: parameter)
            AUParameterSet(nil, nil, &address, resolved.values[parameter.index], 0)
        }
        synth.recordProgram(resolved.program, in: .keyboard)
        setPresentPreset(number: -1, name: name)
        everyParameterMoved()
    }

    /// The keyboard set as the unit holds it: its parameters, which reach the engine at the next
    /// render, and the engine's program.
    private func keyboardState() -> SetState {
        SetState(program: synth.program(in: .keyboard),
                 values: Dictionary(uniqueKeysWithValues: Parameters.all.map { ($0.identifier, Self.value(of: $0, in: unit)) }))
    }

    /// Takes over every pad after a kit: sounds, programs, notes and groups.
    private func padsMoved() {
        for pad in 0..<PadGrid.count { mirror(.pad(pad)) }
        padNotes = Self.padNotes(of: synth)
        padGroups = (0..<PadGrid.count).map(synth.padGroup)
        edited()
    }

    private func controllersMoved() {
        let now = Self.controllers(of: synth)
        guard now != controllers else { return }
        controllers = now
        edited()
    }

    /// Remembers what went wrong with a file for the panel, and hands the error on.
    private func reporting<Result>(_ body: () throws -> Result) throws -> Result {
        do {
            return try body()
        } catch {
            lastError = error.localizedDescription
            lastErrorTime = .now
            throw error
        }
    }

    private static func controllers(of synth: Synth) -> [Int?] {
        Parameters.all.map(synth.controller(of:))
    }

    /// A name as the unit keeps it: "" is none.
    private static func name(_ stored: String) -> String? {
        stored.isEmpty ? nil : stored
    }

    // MARK: Mirroring

    /// Takes over what the engine now holds for a pad's set.
    private func mirror(_ set: SoundSet) {
        guard set != .keyboard, positions[set] != nil else { return }
        let values = Self.positions(in: set, of: synth)
        if values != positions[set] { positions[set] = values }
        let program = synth.program(in: set)
        if program != programs[set] { programs[set] = program }
    }

    /// Every parameter may have moved (a preset): tell the host's listeners, then read them back.
    private func everyParameterMoved() {
        var all = AudioUnitParameter(mAudioUnit: unit, mParameterID: kAUParameterListener_AnyParameter,
                                     mScope: kAudioUnitScope_Global, mElement: 0)
        AUParameterListenerNotify(nil, nil, &all)
        refresh()
    }

    private static func positions(in set: SoundSet, of synth: Synth) -> [Float] {
        Parameters.all.map { synth.normalisedValue(of: $0, in: set) }
    }

    /// The program of every set. The keyboard's comes from the engine too: after a project is
    /// reopened the unit's present preset has no number, but the engine knows it.
    private static func programs(of synth: Synth) -> [SoundSet: Int] {
        Dictionary(uniqueKeysWithValues: sets.map { ($0, synth.program(in: $0)) })
    }

    private static func padNotes(of synth: Synth) -> [Int] {
        (0..<PadGrid.count).map { synth.padNote($0) ?? PadGrid.note(ofPad: $0) }
    }

    // MARK: The Audio Unit

    /// The unit's own properties for its window. The numbers are those of `kFanfrnochProperty_Engine`,
    /// `_StateChanged`, `_SelectedPad` and `_PresetNames` in FanfrnochAU.h and must stay in step with
    /// them.
    static let engineProperty: AudioUnitPropertyID = 64001
    static let stateChangedProperty: AudioUnitPropertyID = 64002
    static let selectedPadProperty: AudioUnitPropertyID = 64003
    static let presetNamesProperty: AudioUnitPropertyID = 64004

    /// Whether the unit is still there with the engine the model borrowed. Asking a disposed unit
    /// is safe: the Audio Unit API checks the instance and returns an error.
    private var isAttached: Bool {
        if !isDetached, Self.engine(of: unit) != engine { isDetached = true }
        return !isDetached
    }

    private static func engine(of unit: AudioUnit) -> OpaquePointer? {
        var engine: UnsafeMutableRawPointer?
        var size = UInt32(MemoryLayout<UnsafeMutableRawPointer?>.size)
        guard AudioUnitGetProperty(unit, engineProperty, kAudioUnitScope_Global, 0, &engine, &size) == noErr,
              let engine else { return nil }
        return OpaquePointer(engine)
    }

    private func address(of parameter: Parameter) -> AudioUnitParameter {
        AudioUnitParameter(mAudioUnit: unit, mParameterID: AudioUnitParameterID(parameter.index),
                           mScope: kAudioUnitScope_Global, mElement: 0)
    }

    private func notify(_ type: AudioUnitEventType, _ parameter: Parameter) {
        var event = AudioUnitEvent(mEventType: type, mArgument: .init(mParameter: address(of: parameter)))
        AUEventListenerNotify(nil, nil, &event)
    }

    private static func keyboardPositions(of unit: AudioUnit) -> [Float] {
        Parameters.all.map { $0.normalised(value(of: $0, in: unit)) }
    }

    /// A parameter's plain value in the unit.
    private static func value(of parameter: Parameter, in unit: AudioUnit) -> Float {
        var plain: AudioUnitParameterValue = 0
        guard AudioUnitGetParameter(unit, AudioUnitParameterID(parameter.index), kAudioUnitScope_Global, 0, &plain) == noErr else {
            return parameter.defaultValue
        }
        return plain
    }

    /// The pad the unit keeps for its window; nil when it gives none.
    private static func selectedPad(of unit: AudioUnit) -> Int? {
        var pad: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        guard AudioUnitGetProperty(unit, selectedPadProperty, kAudioUnitScope_Global, 0, &pad, &size) == noErr,
              pad < UInt32(PadGrid.count) else { return nil }
        return Int(pad)
    }

    /// The presets in use as the unit keeps them: the keyboard's, then pad 1...16's, "" for none.
    private static func presetNames(of unit: AudioUnit) -> [String]? {
        var names: Unmanaged<CFArray>?
        var size = UInt32(MemoryLayout<Unmanaged<CFArray>?>.size)
        guard AudioUnitGetProperty(unit, presetNamesProperty, kAudioUnitScope_Global, 0, &names, &size) == noErr,
              let names else { return nil }
        let list = names.takeRetainedValue() as? [String]          // the property hands it over retained
        return list?.count == PresetShelves.count ? list : nil
    }

    /// Gives the unit the presets in use; it keeps a copy.
    private func setPresetNames(_ names: [String]) -> Bool {
        let array = names as CFArray
        var value = Unmanaged.passUnretained(array)
        return withExtendedLifetime(array) {
            AudioUnitSetProperty(unit, Self.presetNamesProperty, kAudioUnitScope_Global, 0, &value,
                                 UInt32(MemoryLayout<Unmanaged<CFArray>>.size)) == noErr
        }
    }

    /// The number of the unit's present preset: a factory one's, or -1 for one that is not the
    /// unit's own (a host's, or one of the player's).
    private static func presentPresetNumber(of unit: AudioUnit) -> Int {
        var preset = AUPreset()
        var size = UInt32(MemoryLayout<AUPreset>.size)
        guard AudioUnitGetProperty(unit, kAudioUnitProperty_PresentPreset, kAudioUnitScope_Global, 0, &preset, &size) == noErr else {
            return -1
        }
        preset.presetName?.release()                                   // handed over retained
        return Int(preset.presetNumber)
    }

    /// Chooses a factory preset by its number, or names a preset that is not the unit's own
    /// (number -1). The unit keeps the name, so it has to live through the call.
    @discardableResult
    private func setPresentPreset(number: Int, name: String) -> Bool {
        let held = name as CFString
        return withExtendedLifetime(held) {
            var preset = AUPreset(presetNumber: Int32(number), presetName: Unmanaged.passUnretained(held))
            return AudioUnitSetProperty(unit, kAudioUnitProperty_PresentPreset, kAudioUnitScope_Global, 0,
                                        &preset, UInt32(MemoryLayout<AUPreset>.size)) == noErr
        }
    }
}
