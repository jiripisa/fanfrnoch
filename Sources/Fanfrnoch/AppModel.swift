import AppKit
import FanfrnochCore
import FanfrnochUI
import Observation

/// The standalone app's state: the synth, its audio and MIDI connections and
/// the settings the user chose. The panel reads it and calls its methods.
///
/// The sound (the mode, the keyboard's set and the sixteen pads, with the
/// preset each set came from) is kept in the settings as `synth.state`,
/// written half a second after the last edit (`SaveDebounce`) and when the
/// app quits, and put back at launch before audio starts. The MIDI
/// controllers belong to the instrument, not to a sound: they are kept apart
/// (`ControllerMap`), written at each change.
///
/// The player's presets and kits are files the plug-in reads too
/// (`PresetShelves`).
@MainActor
@Observable
final class AppModel: InstrumentModel {

    @ObservationIgnored let synth = Synth()
    @ObservationIgnored private let audio: AudioOutput
    @ObservationIgnored private let midi: MIDIInput
    @ObservationIgnored private let defaults = UserDefaults.standard
    @ObservationIgnored private var debounce = SaveDebounce()
    /// The keys and pads the mouse holds, let go of when the app loses it.
    @ObservationIgnored private var held = HeldNotes()
    @ObservationIgnored private var terminationObserver: (any NSObjectProtocol)?
    /// The synth's count of what MIDI changed, as of the last look (`refresh`).
    @ObservationIgnored private var seenChanges: UInt32

    /// Every set, as the panel names them: the keyboard's, then the pads'.
    private static let sets = [SoundSet.keyboard] + (0..<PadGrid.count).map(SoundSet.pad)

    // What the panel shows, mirrored from the synth: the panel sees only what
    // changes here.

    /// Knob positions (0...1) by parameter index, for every set.
    private var positions: [SoundSet: [Float]]
    /// The program each set last loaded.
    private var programs: [SoundSet: Int]
    private var padNotes: [Int]
    private var padGroups: [Int?]
    /// The pads' hit counters as of the last `refresh`.
    private var hits: [Int]
    private(set) var lastNote: Int?
    /// The presets and kits in the folders, and the preset each set came from.
    private var shelves: PresetShelves
    /// The MIDI controller of each parameter by index; nil for none.
    private var controllers: [Int?]
    /// The keyboard knob that takes the next controller that moves; nil while none is learning.
    private(set) var learning: Parameter?
    /// What went wrong with a file the last time, in words for the panel, and when.
    private(set) var lastError: String? = nil
    private(set) var lastErrorTime: ContinuousClock.Instant? = nil

    /// A switch between the keyboard and the pads calls off a learn: in pad
    /// mode the knobs show a pad, which has no controllers.
    var mode: PlayMode {
        didSet {
            guard mode != oldValue else { return }
            synth.mode = mode
            learn(nil)
            edited()
        }
    }

    var selectedPad: Int {
        didSet { defaults.set(selectedPad, forKey: Keys.selectedPad) }
    }

    var shownSet: SoundSet { mode == .keyboard ? .keyboard : .pad(selectedPad) }

    // MARK: Settings

    private(set) var midiSources: [MIDISource] = []
    private(set) var audioDevices: [AudioDevice] = []
    private(set) var audioProblem: String?
    private(set) var audioUnitStatus = ""

    var midiSource: MIDISourceChoice {
        didSet {
            guard midiSource != oldValue else { return }
            defaults.set(midiSource.storedValue, forKey: Keys.midiSource)
            defaults.set(midiSources.first { midiSource == .source($0.id) }?.name, forKey: Keys.midiSourceName)
            midi.listen(to: midiSource)
        }
    }
    var midiChannel: MIDIChannelFilter {
        didSet { defaults.set(midiChannel.storedValue, forKey: Keys.midiChannel); midi.channelFilter = midiChannel }
    }
    /// nil = the system default output.
    var audioDeviceUID: String? {
        didSet {
            guard audioDeviceUID != oldValue else { return }
            defaults.set(audioDeviceUID, forKey: Keys.audioDevice)
            defaults.set(audioDevices.first { $0.uid == audioDeviceUID }?.name, forKey: Keys.audioDeviceName)
            // Another device has other outputs: begin on its first pair. Changing
            // the pair restarts audio by itself.
            if audioFirstChannel == 0 { restartAudio() } else { audioFirstChannel = 0 }
        }
    }
    /// 0-based left channel of the output pair on the chosen device.
    var audioFirstChannel: Int {
        didSet { defaults.set(audioFirstChannel, forKey: Keys.audioChannel); restartAudio() }
    }

    private enum Keys {
        static let state = "synthState", selectedPad = "selectedPad", controllers = "controllers"
        static let midiSource = "midiSource", midiChannel = "midiChannel"
        static let audioDevice = "audioDevice", audioChannel = "audioFirstChannel"
        /// Names of the chosen devices, to show them while they are not connected.
        static let midiSourceName = "midiSourceName", audioDeviceName = "audioDeviceName"
    }

    /// `presets` and `kits` are where the player's files are kept: the folders
    /// the plug-in reads too.
    init(presets: PresetLibrary = .standard, kits: KitLibrary = .standard) {
        audio = AudioOutput(synth: synth)
        midi = MIDIInput(synth: synth)

        // The sound of the last session; without one, the engine's own: the
        // default kit in the pads and the keyboard's defaults.
        var presetNames: [String?] = []
        if let data = defaults.data(forKey: Keys.state),
           let state = try? JSONDecoder().decode(SynthState.self, from: data) {
            synth.apply(state)
            presetNames = state.presetNames
        }
        if let data = defaults.data(forKey: Keys.controllers),
           let map = try? JSONDecoder().decode(ControllerMap.self, from: data) {
            map.apply(to: synth)
        }
        let synth = synth
        shelves = PresetShelves(presets: presets, kits: kits, inUse: presetNames)
        controllers = Parameters.all.map(synth.controller(of:))
        learning = synth.learning
        seenChanges = synth.changes
        positions = Self.mirroredPositions(of: synth)
        programs = Dictionary(uniqueKeysWithValues: Self.sets.map { ($0, synth.program(in: $0)) })
        padNotes = (0..<PadGrid.count).map { synth.padNote($0) ?? PadGrid.note(ofPad: $0) }
        padGroups = (0..<PadGrid.count).map(synth.padGroup)
        hits = (0..<PadGrid.count).map(synth.padHits)
        lastNote = synth.lastNote

        // These first assignments initialise the properties: their observers do
        // not run, so nothing is saved or restarted yet.
        mode = synth.mode
        selectedPad = PadGrid.pad(stored: defaults.integer(forKey: Keys.selectedPad))
        midiSource = MIDISourceChoice(storedValue: defaults.string(forKey: Keys.midiSource))
        midiChannel = MIDIChannelFilter(storedValue: defaults.integer(forKey: Keys.midiChannel))
        audioDeviceUID = defaults.string(forKey: Keys.audioDevice)
        audioFirstChannel = defaults.integer(forKey: Keys.audioChannel)

        midi.channelFilter = midiChannel
        midi.onSourcesChanged = { [weak self] in self?.refreshDevices() }
        audio.onHardwareChange = { [weak self] devices in
            guard let self else { return }
            audioDevices = devices
            audioProblem = audio.problem
        }
        terminationObserver = NotificationCenter.default.addObserver(forName: NSApplication.willTerminateNotification,
                                                                     object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.saveState() }
        }
        refreshDevices()
        restartAudio()
        refreshAudioUnitStatus()
    }

    private static func mirroredPositions(of synth: Synth) -> [SoundSet: [Float]] {
        Dictionary(uniqueKeysWithValues: sets.map { set in
            (set, Parameters.all.map { synth.normalisedValue(of: $0, in: set) })
        })
    }

    /// Takes over what the synth now holds for a set: after a program loaded or a Send to pad.
    private func mirror(_ set: SoundSet) {
        positions[set] = Parameters.all.map { synth.normalisedValue(of: $0, in: set) }
        programs[set] = synth.program(in: set)
    }

    // MARK: Knobs and programs

    func program(in set: SoundSet) -> Int {
        programs[set] ?? synth.program(in: set)
    }

    /// The set's sound no longer comes from a preset.
    func loadProgram(_ index: Int, into set: SoundSet) {
        guard Programs.names.indices.contains(index) else { return }
        synth.loadProgram(index, into: set)
        mirror(set)
        shelves.leave(set)
        edited()
    }

    func position(of parameter: Parameter, in set: SoundSet) -> Double {
        Double(positions[set]?[parameter.index] ?? synth.normalisedValue(of: parameter, in: set))
    }

    func setPosition(_ position: Double, of parameter: Parameter, in set: SoundSet) {
        guard positions[set] != nil else { return }
        var normalised = Float(min(max(position, 0), 1))
        if parameter.kind != .continuous {
            normalised = parameter.normalised(parameter.plain(normalised))     // on its step
        }
        synth.setNormalisedValue(normalised, of: parameter, in: set)
        positions[set]?[parameter.index] = synth.normalisedValue(of: parameter, in: set)
        edited()
    }

    /// To the value of the set's preset in use, otherwise of its program,
    /// otherwise the default.
    func resetToDefault(_ parameter: Parameter, in set: SoundSet) {
        let plain = shelves.resetValue(of: parameter, in: set, program: program(in: set))
        setPosition(Double(parameter.normalised(plain)), of: parameter, in: set)
    }

    /// A drag on a knob: the app has nobody to tell when it begins; every
    /// turn is an edit, saved once the knob rests.
    func beginEditing(_ parameter: Parameter, in set: SoundSet) {}
    func endEditing(_ parameter: Parameter, in set: SoundSet) {}

    // MARK: Pads

    func padNote(_ pad: Int) -> Int {
        padNotes.indices.contains(pad) ? padNotes[pad] : PadGrid.note(ofPad: pad)
    }

    func setPadNote(_ note: Int, pad: Int) {
        guard padNotes.indices.contains(pad) else { return }
        synth.setPadNote(note, pad: pad)
        padNotes[pad] = synth.padNote(pad) ?? note
        edited()
    }

    func padGroup(_ pad: Int) -> Int? {
        padGroups.indices.contains(pad) ? padGroups[pad] : nil
    }

    func setPadGroup(_ group: Int?, pad: Int) {
        guard padGroups.indices.contains(pad) else { return }
        synth.setPadGroup(group, pad: pad)
        padGroups[pad] = synth.padGroup(pad)
        edited()
    }

    func padName(_ pad: Int) -> String {
        PadLabel.name(program: program(in: .pad(pad)), preset: shelves.inUse(in: .pad(pad)))
    }

    func padHits(_ pad: Int) -> Int {
        hits.indices.contains(pad) ? hits[pad] : 0
    }

    /// The pad comes from the keyboard's preset in use, too.
    func sendToPad(_ pad: Int) {
        guard padNotes.indices.contains(pad) else { return }
        synth.sendToPad(pad)
        mirror(.pad(pad))
        padNotes[pad] = synth.padNote(pad) ?? padNotes[pad]
        shelves.follow(shelves.inUse(in: .keyboard), in: .pad(pad))
        edited()
    }

    // MARK: Presets

    var presets: [String] { shelves.presets }

    func presetInUse(in set: SoundSet) -> String? {
        shelves.inUse(in: set)
    }

    func loadPreset(_ name: String, into set: SoundSet) throws {
        guard positions[set] != nil else { return }
        let state = try reporting { try shelves.load(name, into: set) }
        synth.apply(state, to: set)
        mirror(set)
        edited()
    }

    func savePreset(as name: String, from set: SoundSet) throws {
        guard positions[set] != nil else { return }
        let state = synth.state(of: set)
        try reporting { try shelves.save(state, as: name, from: set) }
        edited()                    // the preset in use is saved with the sound
    }

    /// The sounds stay; the sets that came from the preset come from none any more.
    func deletePreset(_ name: String) throws {
        try reporting { try shelves.delete(name) }
        edited()
    }

    /// Reads the folders again (a menu opens): the plug-in in a host may have
    /// saved or deleted a preset or a kit.
    func lookAtPresets() {
        var looked = shelves                // the model changes only when the folders did
        guard looked.look() else { return }
        let lost = looked.namesInUse != shelves.namesInUse
        shelves = looked
        if lost { edited() }                // a preset in use is gone: remember that
    }

    // MARK: Kits

    var kits: [String] { shelves.kits }

    /// Replaces the pads, their notes, groups and sounds, with a kit's. The
    /// mode and the keyboard set stay.
    func loadKit(_ name: String) throws {
        let kit = try reporting { try shelves.loadKit(name) }
        synth.apply(kit)
        padsMoved()
    }

    /// The engine's own kit into every pad.
    func loadDefaultKit() {
        synth.loadDefaultKit()
        shelves.leavePads()
        padsMoved()
    }

    func saveKit(as name: String) throws {
        let kit = synth.kit
        try reporting { try shelves.saveKit(kit, as: name) }
    }

    func deleteKit(_ name: String) throws {
        try reporting { try shelves.deleteKit(name) }
    }

    /// Takes over every pad after a kit: sounds, programs, notes and groups.
    private func padsMoved() {
        for pad in 0..<PadGrid.count { mirror(.pad(pad)) }
        padNotes = (0..<PadGrid.count).map { synth.padNote($0) ?? PadGrid.note(ofPad: $0) }
        padGroups = (0..<PadGrid.count).map(synth.padGroup)
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

    // MARK: MIDI controllers

    func controller(of parameter: Parameter) -> Int? {
        controllers.indices.contains(parameter.index) ? controllers[parameter.index] : nil
    }

    func setController(_ controller: Int?, of parameter: Parameter) {
        synth.setController(controller, of: parameter)
        controllersMoved()
    }

    func resetControllers() {
        synth.resetControllers()
        controllersMoved()
    }

    /// Starts learning for a knob of the keyboard set, or calls it off (nil).
    func learn(_ parameter: Parameter?) {
        synth.learn(parameter)
        let now = synth.learning
        if now != learning { learning = now }
    }

    /// Takes over the controllers and remembers them for the next launch.
    private func controllersMoved() {
        let now = Parameters.all.map(synth.controller(of:))
        guard now != controllers else { return }
        controllers = now
        if let data = try? JSONEncoder().encode(ControllerMap(capturing: synth)) {
            defaults.set(data, forKey: Keys.controllers)
        }
    }

    // MARK: Playing on screen

    /// Selects the pad too, so that the knobs show what was just heard.
    func hitPad(_ pad: Int, velocity: Int) {
        guard padNotes.indices.contains(pad) else { return }
        selectedPad = pad
        held.padDown(pad)
        synth.noteOn(PadGrid.note(ofPad: pad), velocity: velocity)
    }

    func releasePad(_ pad: Int) {
        guard padNotes.indices.contains(pad) else { return }
        held.padUp(pad)
        synth.noteOff(PadGrid.note(ofPad: pad))
    }

    func keyDown(_ note: Int, velocity: Int) {
        held.keyDown(note)
        synth.noteOn(note, velocity: velocity)
    }

    func keyUp(_ note: Int) {
        held.keyUp(note)
        synth.noteOff(note)
    }

    /// Lets go of every key and pad the mouse holds: when the app loses
    /// focus or its window closes, the mouse-up may never arrive.
    func releaseHeld() {
        for note in held.releaseAll() { synth.noteOff(note) }
    }

    // MARK: Catching up and saving

    /// What the audio thread changed since the last look: pads hit (also from
    /// MIDI), the last note played, and keyboard knobs moved by their
    /// controllers or a controller learnt (the synth counts those, so a look
    /// costs nothing while nothing happens). Writes the sound once it has rested.
    func refresh() {
        let newHits = (0..<PadGrid.count).map(synth.padHits)
        if newHits != hits { hits = newHits }
        let note = synth.lastNote
        if note != lastNote { lastNote = note }
        let changes = synth.changes
        if changes != seenChanges {
            seenChanges = changes
            let keyboard = Parameters.all.map { synth.normalisedValue(of: $0, in: .keyboard) }
            if keyboard != positions[.keyboard] {
                positions[.keyboard] = keyboard
                edited()
            }
            controllersMoved()
            let now = synth.learning
            if now != learning { learning = now }
        }
        if debounce.isDue(at: .now) { saveState() }
    }

    /// The sound changed: write it once it has rested for a moment.
    private func edited() {
        debounce.edited(at: .now)
    }

    /// Writes the sound now if an edit is waiting: when the window closes.
    func saveIfEdited() {
        if debounce.isPending { saveState() }
    }

    /// Remembers the sound for the next launch.
    func saveState() {
        debounce.saved()
        var state = synth.state
        state.presetNames = shelves.namesInUse
        if let data = try? JSONEncoder().encode(state) {
            defaults.set(data, forKey: Keys.state)
        }
    }

    // MARK: Devices

    func refreshDevices() {
        midiSources = MIDIInput.sources()
        audioDevices = AudioOutput.devices()
        midi.listen(to: midiSource)
    }

    /// Output channels of the chosen device; 0 for the system default output
    /// and for a device that is not connected, which play on their first two.
    private var chosenDeviceChannels: Int {
        audioDevices.first { $0.uid == audioDeviceUID }?.outputChannels ?? 0
    }

    /// The channel pairs the chosen device offers, by their 0-based left channel.
    var audioChannelPairs: [Int] {
        OutputChannels.pairs(deviceChannels: chosenDeviceChannels)
    }

    /// The pair the sound goes to: the stored one, or the first when the
    /// device does not offer it.
    var audioChannelPairInUse: Int {
        OutputChannels.pair(audioFirstChannel, deviceChannels: chosenDeviceChannels)
    }

    /// The name of the chosen MIDI source while it is not connected.
    var missingMIDISourceName: String? {
        guard case .source(let id) = midiSource, !midiSources.contains(where: { $0.id == id }) else { return nil }
        return defaults.string(forKey: Keys.midiSourceName) ?? "MIDI device"
    }

    /// The name of the chosen audio device while it is not connected.
    var missingAudioDeviceName: String? {
        guard let audioDeviceUID, !audioDevices.contains(where: { $0.uid == audioDeviceUID }) else { return nil }
        return defaults.string(forKey: Keys.audioDeviceName) ?? "Audio device"
    }

    private func restartAudio() {
        audio.start(deviceUID: audioDeviceUID, firstChannel: audioFirstChannel)
        audioProblem = audio.problem
    }

    // MARK: Audio Unit

    private var bundledAudioUnit: URL {
        Bundle.main.bundleURL.appendingPathComponent("Contents/PlugIns/Fanfrnoch.component")
    }

    private var installedAudioUnit: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Audio/Plug-Ins/Components/Fanfrnoch.component")
    }

    private func version(of component: URL) -> String? {
        let plist = component.appendingPathComponent("Contents/Info.plist")
        return (NSDictionary(contentsOf: plist)?["CFBundleShortVersionString"]) as? String
    }

    var canInstallAudioUnit: Bool { FileManager.default.fileExists(atPath: bundledAudioUnit.path) }

    func refreshAudioUnitStatus() {
        guard canInstallAudioUnit else {
            audioUnitStatus = "This copy of the app does not contain the Audio Unit."
            return
        }
        let bundled = version(of: bundledAudioUnit) ?? "?"
        if let installed = version(of: installedAudioUnit) {
            audioUnitStatus = installed == bundled
                ? "Installed (version \(installed))."
                : "Version \(installed) is installed; this app contains \(bundled)."
        } else {
            audioUnitStatus = "Not installed."
        }
    }

    /// Copies the Audio Unit into ~/Library/Audio/Plug-Ins/Components, replacing
    /// an older copy. Hosts see it after they rescan their plug-ins.
    func installAudioUnit() {
        guard canInstallAudioUnit else { return refreshAudioUnitStatus() }
        let files = FileManager.default
        do {
            try files.createDirectory(at: installedAudioUnit.deletingLastPathComponent(), withIntermediateDirectories: true)
            if files.fileExists(atPath: installedAudioUnit.path) {
                try files.removeItem(at: installedAudioUnit)
            }
            try files.copyItem(at: bundledAudioUnit, to: installedAudioUnit)
            refreshAudioUnitStatus()
        } catch {
            audioUnitStatus = "Installing failed: \(error.localizedDescription)"
        }
    }
}
