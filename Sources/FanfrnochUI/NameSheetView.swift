import SwiftUI
import FanfrnochCore

/// What Save as… and Save kit as… open: a field for the name, Cancel and
/// Save. Return saves and Esc cancels. A name a file already has (in any
/// capitals) asks, right here, before it replaces that file: Replace saves
/// over it, Cancel goes back to the name. The name rules are Core's
/// (`NameCheck`). A popover, never a sheet or an alert: a plug-in's window
/// mishandles them.
struct NameSheetView: View {

    /// "Save the sound as a preset".
    let title: String
    /// What is stored, in a line under the field.
    let note: String
    let save: (String) -> Void
    let cancel: () -> Void

    @State private var name: String
    /// The files there were when the popover opened. Kept as they were:
    /// saving adds the name while the popover is still closing, and it must
    /// not turn into a question on the way out.
    @State private var names: [String]
    /// Whether the popover asks before it replaces a file.
    @State private var asking: Bool
    /// Save has been asked for: Return and the button may both ask.
    @State private var saved = false

    /// The field has the keyboard as soon as it opens: the next thing to do is to type.
    @FocusState private var typing: Bool

    /// `asking` opens the popover asking about the file `name` would replace, for a picture
    /// of that state.
    init(title: String, note: String, name: String, names: [String], asking: Bool = false,
         save: @escaping (String) -> Void, cancel: @escaping () -> Void) {
        self.title = title
        self.note = note
        self.save = save
        self.cancel = cancel
        _name = State(initialValue: name)
        _names = State(initialValue: names)
        _asking = State(initialValue: asking)
    }

    private var check: NameCheck { NameCheck(name, among: names) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 17, weight: .semibold, design: .serif))
                .foregroundStyle(Artwork.silver)
            TextField("Name", text: $name)
                .textFieldStyle(.roundedBorder)
                .frame(width: 260)
                .focused($typing)
                .disabled(asking)
                .onSubmit(saveOrAsk)
            if asking, let question = check.question {
                Text(question)
                    .font(.system(size: 13))
                    .foregroundStyle(Artwork.bone)
                HStack {
                    Spacer()
                    Button("Cancel") {
                        asking = false
                        typing = true
                    }
                    .keyboardShortcut(.cancelAction)
                    Button("Replace") { finish() }
                        .keyboardShortcut(.defaultAction)
                }
            } else {
                Text(note)
                    .font(.system(size: 11))
                    .foregroundStyle(Artwork.silver.opacity(0.7))
                    .frame(width: 260, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                HStack {
                    Spacer()
                    Button("Cancel", action: cancel)
                        .keyboardShortcut(.cancelAction)
                    Button("Save", action: saveOrAsk)
                        .keyboardShortcut(.defaultAction)
                        .disabled(!check.canSave)
                }
            }
        }
        .padding(14)
        .fixedSize()
        // The popover in the panel's dark look, whatever the system's.
        .preferredColorScheme(.dark)
        // On the next turn of the main queue: while the view appears it is not in its window
        // yet, and a focus asked for that early is dropped.
        .onAppear { DispatchQueue.main.async { typing = true } }
    }

    /// Save: a new name is saved at once; a file's name asks first.
    private func saveOrAsk() {
        switch check {
        case .unusable: break
        case .new: finish()
        case .replaces: asking = true
        }
    }

    /// Saves under the name as cleaned: the one `check` judged, in the capitals typed.
    private func finish() {
        guard !saved, check.canSave, let cleaned = NameCheck.cleaned(name) else { return }
        saved = true
        save(cleaned)
    }
}
