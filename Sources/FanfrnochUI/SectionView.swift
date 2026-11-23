import SwiftUI
import FanfrnochCore

/// One group of controls (Stroke, Hands, Pitch, Friction, Body, Noise, Master) on a glass
/// panel: its title, then its knobs and switches where `SectionLayout` puts
/// them.
struct SectionView: View {

    let section: ParameterSection
    let set: SoundSet
    let model: any InstrumentModel
    let editing: KnobEditing

    var body: some View {
        let layout = SectionLayout.of(section)
        VStack(alignment: .leading, spacing: 6) {
            Text(section.title)
                .font(.system(size: 22, weight: .semibold, design: .serif))
                .foregroundStyle(Artwork.silver)
                .padding(.leading, 4)
            Rectangle()
                .fill(Artwork.silver.opacity(0.18))
                .frame(height: 1)
            Grid(horizontalSpacing: 2, verticalSpacing: 4) {
                ForEach(layout.rows.indices, id: \.self) { index in
                    switch layout.rows[index] {
                    case .cells(let parameters):
                        GridRow {
                            ForEach(parameters) { control($0) }
                        }
                    case .wide(let parameter):
                        control(parameter)
                            .gridCellColumns(layout.columns)
                            .padding(.top, 2)
                    }
                }
            }
        }
        .padding(8)
        // Room to spare goes to every group alike; each is as tall as the tallest.
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .glassEffect(.regular.tint(Artwork.midnight.opacity(0.35)), in: .rect(cornerRadius: 16))
    }

    @ViewBuilder
    private func control(_ parameter: Parameter) -> some View {
        if parameter.isChoice {
            ChoiceView(parameter: parameter, set: set, model: model, editing: editing)
        } else {
            KnobView(parameter: parameter, set: set, model: model, editing: editing)
        }
    }
}

/// A switch: its name above a glass segmented control with every choice
/// (Stroke, Key Up, Curve, LFO Start), or a glass menu where the choices are
/// many (the LFO shapes). Velocity and the LFOs move no switch, so it steps
/// back while their amounts are being set.
///
/// While the MIDI button is on, its controller stands in the control's place,
/// under its name, and it learns as a knob does (`ControllerHandling`).
struct ChoiceView: View {

    let parameter: Parameter
    let set: SoundSet
    let model: any InstrumentModel
    let editing: KnobEditing

    /// More choices than this make a menu.
    private static let segmentsAtMost = 4

    private var showsController: Bool { editing == .controller }

    var body: some View {
        VStack(spacing: 4) {
            Text(parameter.name)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Artwork.bone)
                .lineLimit(1)
                .fixedSize()
            control
                // Kept in the layout under the controller, so that nothing moves.
                .opacity(showsController ? 0 : 1)
                .allowsHitTesting(!showsController)
                .accessibilityHidden(showsController)
                .overlay {
                    if showsController { controller }
                }
        }
        .opacity(editing.stepsBack(parameter, in: set) ? 0.3 : 1)
        .allowsHitTesting(!editing.stepsBack(parameter, in: set))
    }

    @ViewBuilder
    private var control: some View {
        let choices = parameter.choices
        let chosen = Int(model.value(of: parameter, in: set).rounded())
        if choices.count > Self.segmentsAtMost {
            Menu {
                ForEach(choices.indices, id: \.self) { index in
                    Toggle(choices[index], isOn: Binding(get: { index == chosen }, set: { _ in choose(index) }))
                }
            } label: {
                Text(choices.indices.contains(chosen) ? choices[chosen] : "—")
                    .font(.system(size: 12))
            }
            .menuStyle(.button)
            .buttonStyle(.glass)
            .frame(width: KnobView.width - 4)
            .accessibilityLabel(parameter.name)
        } else {
            GlassSegments(label: parameter.name, titles: choices, selected: chosen, action: choose)
        }
    }

    /// The switch's controller, in a capsule the size of the switch; dashed while it listens.
    private var controller: some View {
        let listening = model.learning == parameter
        let caption = Controllers.caption(of: parameter, in: set, controller: model.controller(of: parameter),
                                          learning: model.learning)
        return Text(caption)
            .font(.system(size: 12).monospacedDigit())
            .foregroundStyle(listening ? Artwork.aurora : Artwork.silver)
            .lineLimit(1)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Artwork.midnight.opacity(0.4), in: Capsule())
            .overlay {
                if listening {
                    Capsule().stroke(Artwork.aurora, style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                }
            }
            .contentShape(Capsule())
            .modifier(ControllerHandling(parameter: parameter, model: model))
            .accessibilityElement()
            .accessibilityLabel(parameter.name)
            .accessibilityValue(caption)
            .modifier(ControllerHandling.Accessibility(parameter: parameter, model: model,
                                                       inPlay: !editing.stepsBack(parameter, in: set)))
    }

    /// One click is one edit: a host records it as a gesture of its own.
    private func choose(_ index: Int) {
        model.beginEditing(parameter, in: set)
        model.setPosition(Double(parameter.normalised(Float(index))), of: parameter, in: set)
        model.endEditing(parameter, in: set)
    }
}

/// Choices side by side in a glass capsule; the chosen one lit in aurora.
/// Drawn here rather than left to the system's segmented picker, so that it
/// shows what is chosen in a window that is not in front (a plug-in's, in a
/// host).
struct GlassSegments: View {

    /// What the choice is, for VoiceOver ("Stroke", "Mode").
    let label: String
    let titles: [String]
    let selected: Int
    var fontSize: CGFloat = 12
    let action: (Int) -> Void

    var body: some View {
        HStack(spacing: 2) {
            ForEach(titles.indices, id: \.self) { index in
                let on = index == selected
                Button { action(index) } label: {
                    Text(titles[index])
                        .font(.system(size: fontSize, weight: on ? .semibold : .regular))
                        .lineLimit(1)
                        .fixedSize()
                        .foregroundStyle(on ? Artwork.midnight : Artwork.silver)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(on ? Artwork.aurora : Color.clear, in: Capsule())
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .padding(3)
        .glassEffect(.regular.tint(Artwork.midnight.opacity(0.4)).interactive(), in: .capsule)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(label)
    }
}
