import FanfrnochDSP

/// One knob of the instrument. The table comes from the sound engine, so the
/// app and the Audio Unit always agree on it.
public struct Parameter: Identifiable, Sendable, Equatable {

    public enum Kind: Sendable, Equatable {
        case continuous          // a real value: s, Hz, ms, dB, %
        case integer             // whole steps: semitones, an octave
        case choice([String])    // one of a list
    }

    /// Position in the engine's table. Permanent: saved state relies on `identifier`,
    /// hosts rely on the index.
    public let index: Int
    /// Stable name used in saved state ("vowel", "velring").
    public let identifier: String
    /// What the user sees ("Vowel", "VEL>Ring").
    public let name: String
    /// "s", "Hz", "ms", "dB", "%", "st", "ct" or "".
    public let unit: String
    public let kind: Kind
    /// Plain (real) values.
    public let range: ClosedRange<Float>
    public let defaultValue: Float

    public var id: Int { index }

    /// True when zero sits in the middle of the range (a signed amount).
    public var isBipolar: Bool { range.upperBound > 0 && range.lowerBound == -range.upperBound }

    /// Knob position (0...1) for a plain value.
    public func normalised(_ plain: Float) -> Float {
        fanfrnoch_param_to_normalised(Int32(index), plain)
    }

    /// Plain value for a knob position (0...1). Integers and choices snap to their steps.
    public func plain(_ normalised: Float) -> Float {
        fanfrnoch_param_to_plain(Int32(index), normalised)
    }

    /// The value as text without its unit: "4.00", "-24.0", "Alternate", "+1".
    public func text(_ plain: Float) -> String {
        withUnsafeTemporaryAllocation(of: CChar.self, capacity: 64) { buffer in
            String(cString: fanfrnoch_param_display(Int32(index), plain, buffer.baseAddress, Int32(buffer.count)))
        }
    }

    /// The value with its unit, as shown under a knob: "4.00 s", "800 Hz", "Alternate".
    public func label(_ plain: Float) -> String {
        let value = text(plain)
        // A unit belongs to a number, not to a word such as "Alternate" or "Free".
        let isNumber = value.first.map { $0.isNumber || $0 == "-" || $0 == "+" } ?? false
        return unit.isEmpty || !isNumber ? value : "\(value) \(unit)"
    }
}

public enum Parameters {

    /// Every parameter, in engine order.
    public static let all: [Parameter] = (0..<Int(fanfrnoch_num_params())).map { index in
        var info = FanfrnochParamInfo()
        fanfrnoch_param_info(Int32(index), &info)
        let kind: Parameter.Kind
        if Int(info.kind) == Int(FANFRNOCH_KIND_CHOICE) {
            let count = Int(info.numChoices)
            kind = .choice((0..<count).map { String(cString: fanfrnoch_param_choice(Int32(index), Int32($0))) })
        } else if Int(info.kind) == Int(FANFRNOCH_KIND_INT) {
            kind = .integer
        } else {
            kind = .continuous
        }
        return Parameter(index: index,
                         identifier: String(cString: info.identifier),
                         name: String(cString: info.name),
                         unit: String(cString: info.unit),
                         kind: kind,
                         range: info.minValue...info.maxValue,
                         defaultValue: info.defaultValue)
    }

    public static func named(_ identifier: String) -> Parameter? {
        all.first { $0.identifier == identifier }
    }
}

/// A group of controls: Reed, Stroke, Mouth, Breath, Master.
/// The groups and the order of their parameters come from the sound engine,
/// which also gives them to the Audio Unit.
public struct ParameterSection: Identifiable, Sendable {
    public let title: String
    public let parameters: [Parameter]
    public var id: String { title }

    public static let all: [ParameterSection] = (0..<fanfrnoch_num_sections()).map { section in
        ParameterSection(title: String(cString: fanfrnoch_section_name(section)),
                         parameters: (0..<fanfrnoch_section_size(section)).map { position in
                             Parameters.all[Int(fanfrnoch_section_param(section, position))]
                         })
    }
}

/// The built-in programs (factory presets): other jaw harps.
public enum Programs {
    public static let names: [String] = (0..<Int(fanfrnoch_num_programs())).map {
        String(cString: fanfrnoch_program_name(Int32($0)))
    }

    /// The plain value a program gives a parameter.
    /// The parameter's default for a number that is no program.
    public static func value(program: Int, parameter: Parameter) -> Float {
        guard names.indices.contains(program) else { return parameter.defaultValue }
        return fanfrnoch_program_value(Int32(program), Int32(parameter.index))
    }
}
