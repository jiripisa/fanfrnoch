import FanfrnochCore

/// One drag on a knob as one edit: it begins the edit when the drag starts and
/// ends it in the same set, so that a host records exactly one gesture.
///
/// The knob follows the drag's movement from where it stands, not the whole
/// drag from where it began: 200 points of travel turn it end to end, a tenth
/// as far while Shift is held, and Shift pressed or let go halfway does not
/// make the knob jump.
@MainActor
struct KnobEdit {

    /// Points of vertical travel that turn a knob end to end.
    static let travel = 200.0

    /// What is edited and in which set: fixed when the drag starts, whatever
    /// the panel shows meanwhile.
    let parameter: Parameter
    let set: SoundSet

    /// An amount (an LFO's or the velocity's): close to nothing is nothing.
    private let isAmount: Bool
    /// Where the drag has taken the knob, before an amount snaps.
    private var position: Double
    private var translation = 0.0

    /// Starts editing `parameter` in `set` from where its knob stands.
    static func begin(_ parameter: Parameter, in set: SoundSet, isAmount: Bool, model: any InstrumentModel) -> KnobEdit {
        model.beginEditing(parameter, in: set)
        return KnobEdit(parameter: parameter, set: set, isAmount: isAmount,
                        position: model.position(of: parameter, in: set))
    }

    /// The drag has moved `translation` points down since it began.
    mutating func move(to translation: Double, fine: Bool, model: any InstrumentModel) {
        let step = (translation - self.translation) / Self.travel * (fine ? 0.1 : 1)
        self.translation = translation
        position = min(max(position - step, 0), 1)
        var turned = position
        if isAmount {
            // An amount close to nothing is nothing, so that a source can be taken off a knob.
            turned = Double(parameter.normalised(LFOs.snapped(amount: parameter.plain(Float(position)))))
        }
        model.setPosition(turned, of: parameter, in: set)
    }

    /// The drag is over, however it stopped.
    func end(model: any InstrumentModel) {
        model.endEditing(parameter, in: set)
    }

    /// A double click: the program's value back, as an edit of its own.
    static func reset(_ parameter: Parameter, in set: SoundSet, model: any InstrumentModel) {
        model.beginEditing(parameter, in: set)
        model.resetToDefault(parameter, in: set)
        model.endEditing(parameter, in: set)
    }

    /// Of a knob's travel, what one step of VoiceOver's adjust turns it.
    static let adjustStep = 0.05

    /// VoiceOver turns the knob a step up or down, as an edit of its own: a
    /// twentieth of its travel, or one whole step of a knob that has steps.
    static func adjust(_ parameter: Parameter, in set: SoundSet, isAmount: Bool, up: Bool, model: any InstrumentModel) {
        let position = model.position(of: parameter, in: set)
        var turned: Double
        if parameter.kind == .continuous {
            turned = min(max(position + (up ? adjustStep : -adjustStep), 0), 1)
            if isAmount {
                turned = Double(parameter.normalised(LFOs.snapped(amount: parameter.plain(Float(turned)))))
            }
        } else {
            let plain = parameter.plain(Float(position)) + (up ? 1 : -1)
            turned = Double(parameter.normalised(min(max(plain, parameter.range.lowerBound), parameter.range.upperBound)))
        }
        model.beginEditing(parameter, in: set)
        model.setPosition(turned, of: parameter, in: set)
        model.endEditing(parameter, in: set)
    }
}
