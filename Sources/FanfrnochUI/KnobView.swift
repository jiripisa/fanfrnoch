import AppKit
import SwiftUI
import FanfrnochCore

/// What the knobs of the panel edit at the moment.
public enum KnobEditing: Equatable, Sendable {
    /// Their values.
    case value
    /// How far an LFO (0 for the first) moves them.
    case amount(lfo: Int)
    /// How far the velocity of a hit moves them.
    case velocity
    /// Their MIDI controllers: a click makes a control take the next
    /// controller that moves (the header's MIDI button).
    case controller

    /// The amount a knob sets while this is on; nil for its value, for a knob
    /// this source cannot move, and for the controllers.
    func amount(of parameter: Parameter) -> Parameter? {
        switch self {
        case .value, .controller: nil
        case .amount(let lfo): LFOs.amount(of: parameter, lfo: lfo)
        case .velocity: Velocity.amount(of: parameter)
        }
    }

    /// Whether a control of a set is out of play: an LFO's or the velocity's
    /// button is on and the control has no amount for it, or MIDI's is on and
    /// the control can have no controller (a pad's).
    func stepsBack(_ parameter: Parameter, in set: SoundSet) -> Bool {
        switch self {
        case .value: false
        case .controller: !Controllers.canLearn(parameter, in: set)
        case .amount, .velocity: amount(of: parameter) == nil
        }
    }

    /// The colour of the source whose amounts are being set; cream for the
    /// controllers.
    @MainActor var colour: Color {
        switch self {
        case .value, .controller: Artwork.cream
        case .amount(let lfo): Artwork.lfo(lfo)
        case .velocity: Artwork.vel
        }
    }
}

/// One parameter as a knob: its name, a value arc around the cap, the value
/// below. Drag up and down to turn it (Shift for fine steps), double-click to
/// go back to the value of its preset or program. VoiceOver turns it a step
/// at a time.
///
/// A knob an LFO or the velocity moves shows a thin arc in that source's
/// colour: the part of its travel the LFO sweeps, or the way a softer hit
/// moves it. While a source's button in the header is on, the knob sets that
/// source's amount instead of its own value: the same drag and double click,
/// the amount below. Knobs the source cannot move step back meanwhile.
///
/// While the MIDI button is on, the knob shows its MIDI controller below
/// (`ControllerHandling`): a click makes it listen for the next controller
/// that moves. A pad's knobs have none and step back.
public struct KnobView: View {

    private let parameter: Parameter
    private let set: SoundSet
    private let model: any InstrumentModel
    private let editing: KnobEditing

    /// The drag under way, as one edit; nil between drags.
    @State private var edit: KnobEdit?
    /// True while the mouse drags the knob; SwiftUI puts it back when a drag
    /// stops in any way, also one cancelled without `onEnded`.
    @GestureState private var dragging = false

    /// The room a knob takes in a section's grid.
    public static var width: CGFloat { 74 }

    private static let sweep = 270.0          // degrees of travel
    private static let cap: CGFloat = 33      // the cap's artwork; its disc is about 80 % of it
    private static let dial: CGFloat = 44     // the value arc's outer edge

    public init(parameter: Parameter, set: SoundSet, model: any InstrumentModel, editing: KnobEditing = .value) {
        self.parameter = parameter
        self.set = set
        self.model = model
        self.editing = editing
    }

    /// The amount this knob is setting right now, if a source's button is on
    /// and that source can move the knob.
    private var amount: Parameter? { editing.amount(of: parameter) }

    /// What a drag and a double click act on: the amount while one is being set, else the knob.
    private var edited: Parameter { amount ?? parameter }

    /// Whether the knob is waiting for a controller to move.
    private var listening: Bool { editing == .controller && model.learning == parameter }

    public var body: some View {
        let position = model.position(of: parameter, in: set)
        VStack(spacing: 0) {
            Text(parameter.name)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Artwork.cream)
                .lineLimit(1)
                .fixedSize()
            ZStack {
                arc(from: 0, to: 1)
                    .stroke(Color.white.opacity(0.14), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .padding(1.5)
                arc(from: parameter.isBipolar ? min(0.5, position) : 0, to: parameter.isBipolar ? max(0.5, position) : position)
                    .stroke(Artwork.terracotta.opacity(amount == nil && editing != .controller ? 1 : 0.4),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .padding(1.5)
                modulationArcs(position: position)
                cap
                    .frame(width: Self.cap, height: Self.cap)
                // The pointer: a cream line on the graphite cap, turning with the value.
                Capsule()
                    .fill(Artwork.cream.opacity(0.9))
                    .frame(width: 2.5, height: 7)
                    .offset(y: -8.5)
                    .rotationEffect(.degrees(-Self.sweep / 2 + Self.sweep * position))
            }
            .frame(width: Self.dial, height: Self.dial)
            .overlay {
                // Listening for a controller: a dashed ring round the knob.
                if listening {
                    Circle().stroke(Artwork.terracotta, style: StrokeStyle(lineWidth: 1.5, dash: [4, 3])).padding(-1)
                }
            }
            .contentShape(Circle())
            .modifier(Handling(editing: editing, parameter: parameter, model: model, drag: drag,
                               reset: { KnobEdit.reset(edited, in: set, model: model) }))
            // However a drag stops (cancelled, the knob stepping back, the view going away),
            // the edit it began ends, in the set it began in.
            .onChange(of: dragging) { _, isDragging in
                if !isDragging { finishEdit() }
            }
            .onDisappear(perform: finishEdit)
            Text(valueText)
                .font(.system(size: 12).monospacedDigit())
                .foregroundStyle(listening ? Artwork.terracotta : amount == nil ? Artwork.parchment : editing.colour)
                .lineLimit(1)
                .minimumScaleFactor(0.8)            // "move a control" in a knob's width
        }
        .frame(width: Self.width)
        .opacity(editing.stepsBack(parameter, in: set) ? 0.3 : 1)
        .allowsHitTesting(!editing.stepsBack(parameter, in: set))
        .accessibilityElement()
        .accessibilityLabel(amount?.name ?? parameter.name)
        .accessibilityValue(valueText)
        .modifier(Accessibility(editing: editing, parameter: parameter, model: model,
                                inPlay: !editing.stepsBack(parameter, in: set)) { up in
            KnobEdit.adjust(edited, in: set, isAmount: amount != nil, up: up, model: model)
        })
    }

    /// Below the knob: its value, the amount being set, or its controller.
    private var valueText: String {
        if editing == .controller {
            return Controllers.caption(of: parameter, in: set, controller: model.controller(of: parameter),
                                       learning: model.learning)
        }
        if let amount { return LFOs.label(amount: model.value(of: amount, in: set)) }
        return model.label(of: parameter, in: set)
    }

    /// What the mouse does on the knob: a drag and a double click while it is
    /// a knob or an amount; while it shows its controller, the controller's
    /// click, double click and menu, when a drag would turn a knob nobody is
    /// looking at.
    private struct Handling<Drag: Gesture>: ViewModifier {
        let editing: KnobEditing
        let parameter: Parameter
        let model: any InstrumentModel
        let drag: Drag
        let reset: () -> Void

        func body(content: Content) -> some View {
            if editing == .controller {
                content.modifier(ControllerHandling(parameter: parameter, model: model))
            } else {
                content.gesture(drag).onTapGesture(count: 2, perform: reset)
            }
        }
    }

    /// What VoiceOver does with the knob: turns it a step up or down, or,
    /// while it shows its controller, makes it listen for one. Nothing while
    /// it steps back, as for the mouse.
    private struct Accessibility: ViewModifier {
        let editing: KnobEditing
        let parameter: Parameter
        let model: any InstrumentModel
        let inPlay: Bool
        let adjust: (_ up: Bool) -> Void

        func body(content: Content) -> some View {
            if !inPlay {
                content
            } else if editing == .controller {
                content.modifier(ControllerHandling.Accessibility(parameter: parameter, model: model))
            } else {
                content.accessibilityAdjustableAction { direction in
                    switch direction {
                    case .increment: adjust(true)
                    case .decrement: adjust(false)
                    @unknown default: break
                    }
                }
            }
        }
    }

    /// What the LFOs sweep and where a softer hit takes the knob: an arc each,
    /// inside the value arc, each source on a ring of its own.
    @ViewBuilder
    private func modulationArcs(position: Double) -> some View {
        ForEach(0..<LFOs.count, id: \.self) { lfo in
            if let moved = LFOs.amount(of: parameter, lfo: lfo), model.value(of: moved, in: set) != 0 {
                let range = LFOs.arc(position: position, amount: Double(model.value(of: moved, in: set)))
                modulationArc(range, colour: Artwork.lfo(lfo), ring: lfo, lit: editing == .amount(lfo: lfo))
            }
        }
        if let moved = Velocity.amount(of: parameter), model.value(of: moved, in: set) != 0 {
            let range = Velocity.arc(position: position, amount: Double(model.value(of: moved, in: set)))
            modulationArc(range, colour: Artwork.vel, ring: LFOs.count, lit: editing == .velocity)
        }
    }

    /// One source's arc on its ring: 0 just inside the value arc, then inwards.
    private func modulationArc(_ range: ClosedRange<Double>, colour: Color, ring: Int, lit: Bool) -> some View {
        arc(from: range.lowerBound, to: range.upperBound)
            .stroke(colour, style: StrokeStyle(lineWidth: lit ? 2 : 1.5, lineCap: .round))
            .padding(4.5 + 2 * CGFloat(ring))
    }

    @ViewBuilder
    private var cap: some View {
        if let image = Artwork.knob {
            Image(nsImage: image).resizable().interpolation(.high)
        } else {
            Circle().fill(Artwork.indigo).padding(Self.cap * 0.1)
        }
    }

    /// Part of the 270-degree ring, `from` and `to` being knob positions (0...1).
    private func arc(from: Double, to: Double) -> some Shape {
        // trim() runs clockwise from 3 o'clock; the ring starts at 7:30.
        Circle()
            .trim(from: from * Self.sweep / 360, to: max(from, to) * Self.sweep / 360)
            .rotation(.degrees(135))
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 1)
            .updating($dragging) { _, isDragging, _ in isDragging = true }
            .onChanged { value in
                if edit == nil {
                    edit = KnobEdit.begin(edited, in: set, isAmount: amount != nil, model: model)
                }
                edit?.move(to: value.translation.height, fine: NSEvent.modifierFlags.contains(.shift), model: model)
            }
            .onEnded { _ in finishEdit() }
    }

    private func finishEdit() {
        edit?.end(model: model)
        edit = nil
    }
}

/// What the mouse does on a control (a knob or a switch) while the panel
/// shows the controllers: a click makes it listen for the next controller that
/// moves, and a second click calls that off; a double click gives it back the
/// controller it came with; the secondary click's menu takes its controller
/// away or gives the standard one back, or gives every control its own.
struct ControllerHandling: ViewModifier {
    let parameter: Parameter
    let model: any InstrumentModel

    func body(content: Content) -> some View {
        content
            .onTapGesture(count: 2) { Self.backToStandard(parameter, model: model) }
            .onTapGesture { listenOrStop(parameter, model: model) }
            .contextMenu {
                Button("No controller") { model.setController(nil, of: parameter) }
                if let standard = Controllers.standard(for: parameter) {
                    Button("Back to \(Controllers.label(standard))") { model.setController(standard, of: parameter) }
                }
                Divider()
                Self.resetButton(model: model)
            }
    }

    /// A double click: the control gets back the controller it came with, and
    /// stops listening if it was.
    static func backToStandard(_ parameter: Parameter, model: any InstrumentModel) {
        if model.learning == parameter { model.learn(nil) }
        model.setController(Controllers.standard(for: parameter), of: parameter)
    }

    /// Every control back to the controller it came with: in the controls'
    /// menu and the MIDI button's.
    static func resetButton(model: any InstrumentModel) -> some View {
        Button("Every control back to its standard controller") { model.resetControllers() }
    }

    /// VoiceOver's press does what the click does; nothing for a control that
    /// steps back (a pad's).
    struct Accessibility: ViewModifier {
        let parameter: Parameter
        let model: any InstrumentModel
        var inPlay = true

        func body(content: Content) -> some View {
            if inPlay {
                content
                    .accessibilityHint("Listens for the next MIDI control that moves")
                    .accessibilityAction { listenOrStop(parameter, model: model) }
            } else {
                content
            }
        }
    }
}

/// A click in MIDI mode: the control listens, or stops listening if it was.
@MainActor
private func listenOrStop(_ parameter: Parameter, model: any InstrumentModel) {
    model.learn(model.learning == parameter ? nil : parameter)
}
