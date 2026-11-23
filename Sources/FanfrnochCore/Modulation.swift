import FanfrnochDSP

/// The LFOs and the amounts by which they move the knobs. An amount is a
/// parameter like any other (stored with the sound, set by programs, open to a
/// host), shown on the knob it belongs to, not as a knob of its own.
public enum LFOs {

    /// How many LFOs the instrument has.
    public static let count = Int(fanfrnoch_num_lfos())

    /// The parameter that says how far LFO `lfo` (0 for the first) moves
    /// `parameter`, in percent of the knob's travel; nil for a knob an LFO
    /// cannot move.
    public static func amount(of parameter: Parameter, lfo: Int) -> Parameter? {
        let index = Int(fanfrnoch_lfo_amount(Int32(lfo), Int32(parameter.index)))
        return Parameters.all.indices.contains(index) ? Parameters.all[index] : nil
    }

    /// The part of a knob's travel (0...1) an LFO sweeps: `amount` percent
    /// either way from where the knob stands, and no further than its ends.
    public static func arc(position: Double, amount: Double) -> ClosedRange<Double> {
        let reach = abs(amount) / 100
        return max(0, position - reach)...min(1, position + reach)
    }

    /// An amount as the panel shows it: with its sign.
    public static func label(amount: Float) -> String {
        let whole = Int(amount.rounded())
        return whole > 0 ? "+\(whole) %" : whole < 0 ? "−\(-whole) %" : "0 %"
    }

    /// An amount within one percent of nothing is nothing, so that an LFO can
    /// be taken off a knob by hand.
    public static func snapped(amount: Float) -> Float {
        abs(amount) < 1 ? 0 : amount
    }
}

/// The velocity of a hit and the amounts by which it moves the knobs: a
/// parameter for each knob it can move, like an LFO's.
public enum Velocity {

    /// The parameter that says how far the velocity moves `parameter`, in
    /// percent of the knob's travel; nil for a knob it cannot move.
    public static func amount(of parameter: Parameter) -> Parameter? {
        let index = Int(fanfrnoch_vel_amount(Int32(parameter.index)))
        return Parameters.all.indices.contains(index) ? Parameters.all[index] : nil
    }

    /// The part of a knob's travel (0...1) the velocity reaches: the knob is where the hardest
    /// hit stands, and the softest moves it `amount` percent away, down for a positive amount,
    /// up for a negative one, no further than its ends. Volume scales its gain instead, so its
    /// arc only shows the direction and the size of the amount.
    public static func arc(position: Double, amount: Double) -> ClosedRange<Double> {
        let softest = position - amount / 100
        return max(0, min(position, softest))...min(1, max(position, softest))
    }
}
