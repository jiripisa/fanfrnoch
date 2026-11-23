import Testing
@testable import FanfrnochCore

/// What the standalone app lets the user choose besides the sound.
@Suite("MIDI channel filter")
struct MIDIChannelFilterTests {

    @Test("Omni takes every channel, a channel only its own")
    func channels() {
        #expect(MIDIChannelFilter.omni.accepts(status: 0x95))
        #expect(MIDIChannelFilter.channel(6).accepts(status: 0x95))
        #expect(!MIDIChannelFilter.channel(1).accepts(status: 0x95))
    }

    @Test("System messages never pass")
    func systemMessages() {
        #expect(!MIDIChannelFilter.omni.accepts(status: 0xF8))
        #expect(!MIDIChannelFilter.omni.accepts(status: 0x40))
    }

    @Test("Stored values map to filters and back")
    func storage() {
        #expect(MIDIChannelFilter(storedValue: 0) == .omni)
        #expect(MIDIChannelFilter(storedValue: 10) == .channel(10))
        #expect(MIDIChannelFilter(storedValue: 99) == .omni)
        #expect(MIDIChannelFilter.channel(3).storedValue == 3)
    }
}

@Suite("MIDI source choice")
struct MIDISourceChoiceTests {

    @Test("Stored values map to choices and back")
    func storage() {
        #expect(MIDISourceChoice(storedValue: nil) == MIDISourceChoice.all)
        #expect(MIDISourceChoice(storedValue: "all") == MIDISourceChoice.all)
        #expect(MIDISourceChoice(storedValue: "none") == MIDISourceChoice.none)
        #expect(MIDISourceChoice(storedValue: "-1234") == MIDISourceChoice.source(-1234))
        #expect(MIDISourceChoice(storedValue: "keyboard") == MIDISourceChoice.all)
        #expect(MIDISourceChoice.source(77).storedValue == "77")
        #expect(MIDISourceChoice.none.storedValue == "none")
        #expect(MIDISourceChoice.all.storedValue == "all")
    }

    @Test("All takes every source, none takes none, a source only itself")
    func sources() {
        #expect(MIDISourceChoice.all.includes(5))
        #expect(!MIDISourceChoice.none.includes(5))
        #expect(MIDISourceChoice.source(5).includes(5))
        #expect(!MIDISourceChoice.source(5).includes(6))
    }
}

@Suite("Output channels")
struct OutputChannelsTests {

    @Test("A device offers its channels in pairs")
    func pairs() {
        #expect(OutputChannels.pairs(deviceChannels: 2) == [0])
        #expect(OutputChannels.pairs(deviceChannels: 4) == [0, 2])
        #expect(OutputChannels.pairs(deviceChannels: 5) == [0, 2])
        #expect(OutputChannels.pairs(deviceChannels: 1) == [])
        #expect(OutputChannels.pairs(deviceChannels: 0) == [])
    }

    @Test("The map sends left and right to the chosen pair and silence elsewhere")
    func map() {
        #expect(OutputChannels.map(firstChannel: 2, deviceChannels: 4) == [-1, -1, 0, 1])
        #expect(OutputChannels.map(firstChannel: 0, deviceChannels: 6) == [0, 1, -1, -1, -1, -1])
        #expect(OutputChannels.map(firstChannel: 2, deviceChannels: 5) == [-1, -1, 0, 1, -1])
    }

    @Test("The pair in use is the chosen one, or the first when the device lacks it")
    func pairInUse() {
        #expect(OutputChannels.pair(2, deviceChannels: 4) == 2)
        #expect(OutputChannels.pair(6, deviceChannels: 4) == 0)
        #expect(OutputChannels.pair(1, deviceChannels: 4) == 0)
        #expect(OutputChannels.pair(0, deviceChannels: 2) == 0)
    }

    @Test("A pair the device does not have falls back to the first")
    func fallback() {
        #expect(OutputChannels.map(firstChannel: 6, deviceChannels: 4) == [0, 1, -1, -1])
        #expect(OutputChannels.map(firstChannel: 1, deviceChannels: 4) == [0, 1, -1, -1])
        #expect(OutputChannels.map(firstChannel: -2, deviceChannels: 4) == [0, 1, -1, -1])
    }
}

@Suite("Output devices")
struct OutputDevicesTests {

    @Test("The process's own default-device aggregate is not offered; real devices are")
    func privateAggregate() {
        #expect(!OutputDevices.isChoosable(uid: "CADefaultDeviceAggregate-4711-0"))
        #expect(!OutputDevices.isChoosable(uid: "CADefaultDeviceAggregate-12-3"))
        #expect(OutputDevices.isChoosable(uid: "BuiltInSpeakerDevice"))
        #expect(OutputDevices.isChoosable(uid: "AppleUSBAudioEngine:Focusrite:Scarlett 2i2:1234:1,2"))
        #expect(OutputDevices.isChoosable(uid: "My CADefaultDeviceAggregate"))     // only as a prefix
    }
}
