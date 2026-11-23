import SwiftUI
import FanfrnochCore

/// One group of controls (Stroke, Hands, Pitch, Friction, Body, Noise, Master) on a glass
/// card: its title in New York over a thin line, then its knobs and switches where
/// `SectionLayout` puts them. A card taller than its controls (Hands, Noise beside their
/// neighbours) centres them below the title, as the mockup does.
struct SectionView: View {

    let section: ParameterSection
    let set: SoundSet
    let model: any InstrumentModel
    let editing: KnobEditing

    /// The card's padding on either side, together: what `PanelLayout.widths` leaves out of the
    /// share of the columns.
    static let inset: CGFloat = 16

    var body: some View {
        let layout = SectionLayout.of(section)
        VStack(alignment: .leading, spacing: 3) {
            Text(section.title)
                .font(.system(size: 21, weight: .semibold, design: .serif))
                .foregroundStyle(Artwork.cream)
                .padding(.leading, 4)
            Rectangle()
                .fill(Artwork.cream.opacity(0.2))
                .frame(height: 1)
            Grid(horizontalSpacing: 0, verticalSpacing: 0) {
                ForEach(layout.rows.indices, id: \.self) { index in
                    switch layout.rows[index] {
                    case .cells(let parameters):
                        GridRow {
                            ForEach(parameters) { control($0).frame(maxWidth: .infinity) }
                        }
                    case .wide(let parameter):
                        // Outside a GridRow a view spans every column.
                        ChoiceView(parameter: parameter, set: set, model: model, editing: editing, inline: true)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                    case .rule:
                        Rectangle()
                            .fill(Artwork.cream.opacity(0.16))
                            .frame(height: 1)
                            .padding(.vertical, 3)
                    }
                }
            }
            .frame(maxHeight: .infinity)
        }
        .padding(.horizontal, Self.inset / 2)
        .padding(.top, 5)
        .padding(.bottom, 7)
        // Room to spare goes to every card alike; each is as tall as the tallest of its row.
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .instrumentCard()
    }

    @ViewBuilder
    private func control(_ parameter: Parameter) -> some View {
        if parameter.isChoice {
            ChoiceView(parameter: parameter, set: set, model: model, editing: editing, inline: false)
        } else {
            KnobView(parameter: parameter, set: set, model: model, editing: editing)
        }
    }
}

/// A switch: its name beside (`inline`, a row of its own) or above a glass
/// segmented control with every choice (Key Up, Drum, LFO Start), or a glass
/// menu where the choices are many (the LFO shapes). Velocity and the LFOs
/// move no switch, so it steps back while their amounts are being set.
///
/// While the MIDI button is on, its controller stands in the control's place,
/// under its name, and it learns as a knob does (`ControllerHandling`).
struct ChoiceView: View {

    let parameter: Parameter
    let set: SoundSet
    let model: any InstrumentModel
    let editing: KnobEditing
    /// The name on the left and the control on the right, in a row across the card.
    let inline: Bool

    /// More choices than this make a menu.
    private static let segmentsAtMost = 4
    /// The width of a segment, and of a menu, in a row of their own: the mockup's.
    private static let segmentWidth: CGFloat = 54
    private static let menuWidth: CGFloat = 112

    private var showsController: Bool { editing == .controller }

    var body: some View {
        Group {
            if inline {
                HStack(spacing: 8) {
                    name
                    Spacer(minLength: 0)
                    shownControl
                }
            } else {
                VStack(spacing: 4) {
                    name
                    shownControl
                }
            }
        }
        .opacity(editing.stepsBack(parameter, in: set) ? 0.3 : 1)
        .allowsHitTesting(!editing.stepsBack(parameter, in: set))
    }

    private var name: some View {
        Text(parameter.name)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(Artwork.cream)
            .lineLimit(1)
            .fixedSize()
    }

    private var shownControl: some View {
        control
            // Kept in the layout under the controller, so that nothing moves.
            .opacity(showsController ? 0 : 1)
            .allowsHitTesting(!showsController)
            .accessibilityHidden(showsController)
            .overlay {
                if showsController { controller }
            }
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
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .menuStyle(.button)
            .buttonStyle(.glass)
            .buttonSizing(.flexible)
            .frame(width: inline ? Self.menuWidth : KnobView.width - 4)
            .controlSize(.small)
            .accessibilityLabel(parameter.name)
        } else {
            GlassSegments(label: parameter.name, titles: choices, selected: chosen,
                          segmentWidth: inline ? Self.segmentWidth : nil, action: choose)
        }
    }

    /// The switch's controller, in a capsule the size of the switch; dashed while it listens.
    private var controller: some View {
        let listening = model.learning == parameter
        let caption = Controllers.caption(of: parameter, in: set, controller: model.controller(of: parameter),
                                          learning: model.learning)
        return Text(caption)
            .font(.system(size: 12).monospacedDigit())
            .foregroundStyle(listening ? Artwork.terracotta : Artwork.cream)
            .lineLimit(1)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Artwork.indigo.opacity(0.5), in: Capsule())
            .overlay {
                if listening {
                    Capsule().stroke(Artwork.terracotta, style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
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

/// Choices side by side in a glass capsule; the chosen one lit in terracotta.
/// Drawn here rather than left to the system's segmented picker, so that it
/// shows what is chosen in a window that is not in front (a plug-in's, in a
/// host).
struct GlassSegments: View {

    /// What the choice is, for VoiceOver ("Key Up", "Mode").
    let label: String
    let titles: [String]
    let selected: Int
    var fontSize: CGFloat = 12
    /// Every segment this wide; nil for each as wide as its title.
    var segmentWidth: CGFloat? = nil
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
                        .foregroundStyle(on ? Artwork.indigo : Artwork.cream)
                        .padding(.horizontal, 6)
                        .frame(width: segmentWidth)
                        .padding(.vertical, 2)
                        .background(on ? Artwork.terracotta : Color.clear, in: Capsule())
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .padding(2)
        .glassEffect(.regular.tint(Artwork.indigo.opacity(0.4)).interactive(), in: .capsule)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(label)
    }
}
