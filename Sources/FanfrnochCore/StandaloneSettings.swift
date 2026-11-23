/// What the standalone app lets the user choose besides the sound: where MIDI
/// comes from and the output channels. A host gives the Audio Unit all of this itself.

/// Which MIDI sources the standalone app listens to.
public enum MIDISourceChoice: Hashable, Sendable {
    case all
    case none
    /// One source, by CoreMIDI's unique ID (stable across restarts).
    case source(Int32)

    /// Stored form: "all", "none" or the unique ID.
    public init(storedValue: String?) {
        switch storedValue {
        case "none": self = .none
        case let value?: self = Int32(value).map(MIDISourceChoice.source) ?? .all
        case nil: self = .all
        }
    }

    public var storedValue: String {
        switch self {
        case .all: "all"
        case .none: "none"
        case .source(let id): String(id)
        }
    }

    /// Whether the source with this unique ID is listened to.
    public func includes(_ id: Int32) -> Bool {
        switch self {
        case .all: true
        case .none: false
        case .source(let chosen): chosen == id
        }
    }
}

/// Which MIDI channels the standalone app listens to.
public enum MIDIChannelFilter: Hashable, Sendable {
    case omni
    case channel(Int)     // 1...16

    /// Stored form: 0 = omni, 1...16 = that channel.
    public init(storedValue: Int) {
        self = (1...16).contains(storedValue) ? .channel(storedValue) : .omni
    }

    public var storedValue: Int {
        switch self {
        case .omni: 0
        case .channel(let channel): channel
        }
    }

    /// Whether a message with this status byte should reach the instrument.
    /// System messages (0xF0 and above) never do.
    public func accepts(status: UInt8) -> Bool {
        guard status >= 0x80, status < 0xF0 else { return false }
        switch self {
        case .omni: return true
        case .channel(let channel): return Int(status & 0x0F) + 1 == channel
        }
    }
}

/// The pair of channels of a multi-channel output device that carries the
/// instrument. Channels are 0-based here and 1-based on screen.
public enum OutputChannels {

    /// The left channel of every pair a device with `deviceChannels` outputs
    /// offers: 0, 2, 4… A last odd channel is not part of a pair.
    public static func pairs(deviceChannels: Int) -> [Int] {
        Array(stride(from: 0, to: deviceChannels - 1, by: 2))
    }

    /// The pair in use on a device: the chosen one, or the first when the
    /// device does not have it.
    public static func pair(_ firstChannel: Int, deviceChannels: Int) -> Int {
        pairs(deviceChannels: deviceChannels).contains(firstChannel) ? firstChannel : 0
    }

    /// The channel map for the pair starting at `firstChannel`: for every device
    /// channel the source channel that feeds it (0 = left, 1 = right), or -1 for
    /// silence. A pair the device does not have falls back to the first one.
    public static func map(firstChannel: Int, deviceChannels: Int) -> [Int32] {
        var map = [Int32](repeating: -1, count: max(deviceChannels, 0))
        let first = pair(firstChannel, deviceChannels: deviceChannels)
        for (source, channel) in [first, first + 1].enumerated() where map.indices.contains(channel) {
            map[channel] = Int32(source)
        }
        return map
    }
}

/// Which output devices the standalone app offers.
public enum OutputDevices {

    /// Whether a device with this UID is one to choose. Core Audio gives the process a private
    /// aggregate of its own for the default output (`CADefaultDeviceAggregate-<pid>-<n>`); that
    /// is no device a musician picks.
    public static func isChoosable(uid: String) -> Bool {
        !uid.hasPrefix("CADefaultDeviceAggregate")
    }
}
