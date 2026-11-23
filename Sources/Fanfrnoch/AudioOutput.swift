import AVFoundation
import CoreAudio
import FanfrnochCore

/// An audio device that can play sound.
struct AudioDevice: Identifiable, Hashable {
    let id: AudioDeviceID
    /// Stable across restarts, unlike `id`; this is what the settings remember.
    let uid: String
    let name: String
    let outputChannels: Int
}

/// Plays the synth through an output device: the system default, or one the
/// user picked, on a chosen pair of its channels. It follows the hardware:
/// when the default output changes, the chosen device is unplugged or comes
/// back, or the device changes its format, audio starts again where it belongs.
@MainActor
final class AudioOutput {

    private let synth: Synth
    private var engine: AVAudioEngine?
    private var engineObserver: (any NSObjectProtocol)?

    /// What the last `start` asked for.
    private var deviceUID: String?
    private var firstChannel = 0
    /// The device the last `start` aimed at: the chosen one when it is
    /// connected, the system default otherwise.
    private var target = AudioDeviceID(kAudioObjectUnknown)

    /// Why the sound is not where the settings say, for the settings window;
    /// nil when all is well.
    private(set) var problem: String?

    /// Called with the devices now present after the audio hardware changed;
    /// audio may have started again.
    var onHardwareChange: (@MainActor ([AudioDevice]) -> Void)?

    init(synth: Synth) {
        self.synth = synth
        watchHardware()
    }

    /// (Re)starts audio. `deviceUID` nil means the system default output;
    /// `firstChannel` is the 0-based left channel of the pair to use on the
    /// chosen device. When that device is not connected, the sound goes to the
    /// system default until it is.
    func start(deviceUID: String?, firstChannel: Int) {
        start(deviceUID: deviceUID, firstChannel: firstChannel, devices: Self.devices())
    }

    private func start(deviceUID: String?, firstChannel: Int, devices: [AudioDevice]) {
        self.deviceUID = deviceUID
        self.firstChannel = firstChannel
        stop()
        problem = nil

        // A new engine every time: it plays on the system default output, while
        // an engine that was once pointed at a device stays there.
        let engine = AVAudioEngine()
        let output = engine.outputNode
        let chosen = deviceUID.flatMap { uid in devices.first { $0.uid == uid } }
        target = chosen?.id ?? Self.defaultDevice()
        var onChosenDevice = false
        if let chosen {
            var id = chosen.id
            var status = kAudioUnitErr_Uninitialized
            if let unit = output.audioUnit {
                status = AudioUnitSetProperty(unit, kAudioOutputUnitProperty_CurrentDevice, kAudioUnitScope_Global, 0,
                                              &id, UInt32(MemoryLayout<AudioDeviceID>.size))
            }
            onChosenDevice = status == noErr
            if !onChosenDevice { problem = "Could not switch to \(chosen.name) (error \(status)); using the system default output." }
        } else if deviceUID != nil {
            problem = "The chosen device is not connected; using the system default output."
        }

        let deviceFormat = output.outputFormat(forBus: 0)
        guard deviceFormat.sampleRate > 0, deviceFormat.channelCount > 0,
              let format = AVAudioFormat(standardFormatWithSampleRate: deviceFormat.sampleRate, channels: 2) else {
            problem = "The audio output has no usable format."
            return
        }
        synth.prepare(sampleRate: format.sampleRate)       // safe: no engine is running

        let source = Self.makeSource(synth: synth, format: format)
        engine.attach(source)
        engine.connect(source, to: engine.mainMixerNode, format: format)
        if onChosenDevice {
            applyChannelMap(to: output, firstChannel: firstChannel, deviceChannels: Int(deviceFormat.channelCount))
        }

        // The engine stops itself when its device changes format or goes away.
        engineObserver = NotificationCenter.default.addObserver(forName: .AVAudioEngineConfigurationChange,
                                                                object: engine, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.hardwareChanged() }
        }
        self.engine = engine
        do {
            try engine.start()
            #if DEBUG
            let name = devices.first { $0.id == target }?.name ?? "device \(target)"
            print("Audio: \(name) at \(Int(format.sampleRate)) Hz\(onChosenDevice ? ", channels \(firstChannel + 1)–\(firstChannel + 2)" : "")")
            #endif
        } catch {
            problem = "Audio did not start: \(error.localizedDescription)"
        }
    }

    private func stop() {
        if let engineObserver {
            NotificationCenter.default.removeObserver(engineObserver)
        }
        engineObserver = nil
        engine?.stop()
        engine = nil
    }

    /// The render block runs on the audio thread, so it is built outside the main actor.
    private nonisolated static func makeSource(synth: Synth, format: AVAudioFormat) -> AVAudioSourceNode {
        AVAudioSourceNode(format: format) { _, _, frameCount, bufferList -> OSStatus in
            let buffers = UnsafeMutableAudioBufferListPointer(bufferList)
            guard let left = buffers[0].mData?.assumingMemoryBound(to: Float.self) else { return noErr }
            let right = buffers.count > 1 ? buffers[1].mData?.assumingMemoryBound(to: Float.self) : nil
            synth.render(left: left, right: right, frames: Int(frameCount))
            return noErr
        }
    }

    /// Routes the stereo signal to the chosen pair of a multi-channel device.
    private func applyChannelMap(to output: AVAudioOutputNode, firstChannel: Int, deviceChannels: Int) {
        guard deviceChannels > 2, let unit = output.audioUnit else { return }
        var map = OutputChannels.map(firstChannel: firstChannel, deviceChannels: deviceChannels)
        let status = AudioUnitSetProperty(unit, kAudioOutputUnitProperty_ChannelMap, kAudioUnitScope_Output, 0,
                                          &map, UInt32(MemoryLayout<Int32>.size * map.count))
        if status != noErr { problem = "Could not choose the output channels (error \(status)); using the first two." }
    }

    // MARK: Following the hardware

    /// CoreAudio says when devices come and go and when the default output
    /// changes. The listeners stay for the life of the app, like this object.
    private func watchHardware() {
        for selector in [kAudioHardwarePropertyDevices, kAudioHardwarePropertyDefaultOutputDevice] {
            var address = AudioObjectPropertyAddress(mSelector: selector, mScope: kAudioObjectPropertyScopeGlobal,
                                                     mElement: kAudioObjectPropertyElementMain)
            AudioObjectAddPropertyListenerBlock(AudioObjectID(kAudioObjectSystemObject), &address, .main) { [weak self] _, _ in
                MainActor.assumeIsolated { self?.hardwareChanged() }
            }
        }
    }

    /// Starts again when the change concerns the device in use, and only then:
    /// a restart silences every voice.
    private func hardwareChanged() {
        let devices = Self.devices()
        let chosen = deviceUID.flatMap { uid in devices.first { $0.uid == uid }?.id }
        if engine?.isRunning != true || (chosen ?? Self.defaultDevice()) != target {
            start(deviceUID: deviceUID, firstChannel: firstChannel, devices: devices)
        }
        onHardwareChange?(devices)
    }

    private static func defaultDevice() -> AudioDeviceID {
        var address = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDefaultOutputDevice,
                                                 mScope: kAudioObjectPropertyScopeGlobal,
                                                 mElement: kAudioObjectPropertyElementMain)
        var id = AudioDeviceID(kAudioObjectUnknown)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &id)
        return id
    }

    // MARK: Device list

    /// Every device with at least one output channel, but the process's own private aggregate.
    static func devices() -> [AudioDevice] {
        var address = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDevices,
                                                 mScope: kAudioObjectPropertyScopeGlobal,
                                                 mElement: kAudioObjectPropertyElementMain)
        var size: UInt32 = 0
        let system = AudioObjectID(kAudioObjectSystemObject)
        guard AudioObjectGetPropertyDataSize(system, &address, 0, nil, &size) == noErr else { return [] }
        var ids = [AudioDeviceID](repeating: 0, count: Int(size) / MemoryLayout<AudioDeviceID>.size)
        guard AudioObjectGetPropertyData(system, &address, 0, nil, &size, &ids) == noErr else { return [] }
        return ids.compactMap { id in
            let channels = outputChannelCount(of: id)
            guard channels > 0,
                  let name = string(of: id, selector: kAudioObjectPropertyName),
                  let uid = string(of: id, selector: kAudioDevicePropertyDeviceUID),
                  OutputDevices.isChoosable(uid: uid) else { return nil }
            return AudioDevice(id: id, uid: uid, name: name, outputChannels: channels)
        }
    }

    private static func string(of device: AudioDeviceID, selector: AudioObjectPropertySelector) -> String? {
        var address = AudioObjectPropertyAddress(mSelector: selector, mScope: kAudioObjectPropertyScopeGlobal,
                                                 mElement: kAudioObjectPropertyElementMain)
        var value: Unmanaged<CFString>?
        var size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        guard AudioObjectGetPropertyData(device, &address, 0, nil, &size, &value) == noErr, let value else { return nil }
        return value.takeRetainedValue() as String
    }

    private static func outputChannelCount(of device: AudioDeviceID) -> Int {
        var address = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyStreamConfiguration,
                                                 mScope: kAudioDevicePropertyScopeOutput,
                                                 mElement: kAudioObjectPropertyElementMain)
        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(device, &address, 0, nil, &size) == noErr, size > 0 else { return 0 }
        let storage = UnsafeMutableRawPointer.allocate(byteCount: Int(size), alignment: MemoryLayout<AudioBufferList>.alignment)
        defer { storage.deallocate() }
        guard AudioObjectGetPropertyData(device, &address, 0, nil, &size, storage) == noErr else { return 0 }
        let list = UnsafeMutableAudioBufferListPointer(storage.assumingMemoryBound(to: AudioBufferList.self))
        return list.reduce(0) { $0 + Int($1.mNumberChannels) }
    }
}
