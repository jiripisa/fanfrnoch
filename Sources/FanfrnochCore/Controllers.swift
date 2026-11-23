import FanfrnochDSP

/// MIDI controllers on the keyboard set's knobs. Every knob comes with a controller (a control
/// change number) and can be taught another; a control change then puts the knob where its value
/// says. The amounts have none, and the pads' sets are never moved.
public enum Controllers {

    /// The controller a parameter comes with; nil for one that has none (the amounts).
    public static func standard(for parameter: Parameter) -> Int? {
        let controller = Int(fanfrnoch_standard_controller(Int32(parameter.index)))
        return controller >= 0 ? controller : nil
    }

    /// Whether a controller cannot be given to a knob: MIDI's own (bank select, data entry,
    /// channel mode …), the mod wheel, and any number outside 0...127.
    public static func isReserved(_ controller: Int) -> Bool {
        fanfrnoch_controller_reserved(Int32(clamping: controller)) != 0
    }

    /// A controller as the panel shows it on a knob.
    public static func label(_ controller: Int?) -> String {
        controller.map { "CC \($0)" } ?? "—"
    }

    /// Whether a control of a set can have a controller: the keyboard set's knobs and switches.
    /// A pad's set and the amounts have none.
    public static func canLearn(_ parameter: Parameter, in set: SoundSet) -> Bool {
        set == .keyboard && standard(for: parameter) != nil
    }

    /// What a control shows under its name while the panel shows the controllers: its
    /// controller, "move a control" while it listens for one, and a dash for none or for a
    /// control that can have none.
    public static func caption(of parameter: Parameter, in set: SoundSet, controller: Int?,
                               learning: Parameter?) -> String {
        guard canLearn(parameter, in: set) else { return label(nil) }
        return learning == parameter ? "move a control" : label(controller)
    }

    /// The parameters that can have a controller: the knobs, in table order.
    static let knobs: [Parameter] = Parameters.all.filter { standard(for: $0) != nil }
}

public extension Synth {

    /// The controller that moves a knob of the keyboard set, nil for none.
    func controller(of parameter: Parameter) -> Int? {
        let controller = Int(fanfrnoch_get_controller(engine, Int32(parameter.index)))
        return controller >= 0 ? controller : nil
    }

    /// Gives a knob a controller, or takes it away (nil). A controller serves one knob: whoever
    /// had it before has none. A reserved controller is not taken, and an amount takes none.
    func setController(_ controller: Int?, of parameter: Parameter) {
        fanfrnoch_set_controller(engine, Int32(parameter.index), Int32(clamping: controller ?? -1))
    }

    /// Every knob back to the controller it came with.
    func resetControllers() {
        fanfrnoch_reset_controllers(engine)
    }

    /// The knob that takes the next controller that moves; nil while nobody is learning.
    var learning: Parameter? {
        let index = Int(fanfrnoch_learning(engine))
        return Parameters.all.indices.contains(index) ? Parameters.all[index] : nil
    }

    /// Starts learning for a knob, or calls it off (nil, or an amount).
    func learn(_ parameter: Parameter?) {
        fanfrnoch_learn(engine, Int32(parameter?.index ?? -1))
    }

    /// Counts what MIDI changed without anyone turning a knob: a knob moved by its controller, a
    /// controller learnt. A window that sees a new number reads the knobs and the controllers
    /// again.
    var changes: UInt32 { UInt32(fanfrnoch_changes(engine)) }
}

/// Which controller moves which knob, in a form that can be stored: by the knob's identifier, -1
/// for a knob that has none. It belongs to the instrument, not to a sound: programs, presets and
/// kits leave it alone.
public struct ControllerMap: Codable, Equatable, Sendable {

    public var controllers: [String: Int]

    public init(controllers: [String: Int]) {
        self.controllers = controllers
    }

    /// A field the data lacks gets its default (no controllers: every knob keeps its standard
    /// one); a field this version does not know is ignored.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        controllers = try container.decodeIfPresent([String: Int].self, forKey: .controllers) ?? [:]
    }

    /// The controllers of a synth's knobs as they stand.
    public init(capturing synth: Synth) {
        controllers = Dictionary(uniqueKeysWithValues: Controllers.knobs.map {
            ($0.identifier, synth.controller(of: $0) ?? -1)
        })
    }

    /// Puts this map into a synth. A knob the map does not mention keeps the controller it comes
    /// with, and a name this version does not know is ignored.
    public func apply(to synth: Synth) {
        synth.resetControllers()
        // Those without a controller first: giving a controller takes it from whoever has it.
        for knob in Controllers.knobs where (controllers[knob.identifier] ?? 0) < 0 {
            synth.setController(nil, of: knob)
        }
        for knob in Controllers.knobs {
            if let controller = controllers[knob.identifier], controller >= 0 {
                synth.setController(controller, of: knob)
            }
        }
    }
}
