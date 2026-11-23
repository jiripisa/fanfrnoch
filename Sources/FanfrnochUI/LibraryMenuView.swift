import SwiftUI
import FanfrnochCore

/// A menu of the player's files, the Preset menu in the header or the Kit menu
/// beside the pads: the entries Core lists (`LibraryMenu`) and the popovers
/// they open. Save opens the name popover (`NameSheetView`); Delete asks in a
/// small popover of its own. No sheet or alert: a plug-in's window mishandles
/// them.
///
/// The model keeps a file's error for the panel's error line, so a failed
/// load, save or delete needs nothing here.
struct LibraryMenuView<Label: View>: View {

    let library: LibraryMenuFiles
    /// The menu's width, which its button fills: a menu button would take its
    /// width from the ticked item's name, whatever its label says.
    let width: CGFloat
    /// Before the menu shows: the folders read again.
    let opening: () -> Void
    @ViewBuilder let label: () -> Label

    /// The popover open below the menu, if any.
    @State private var popover: Popover?

    private enum Popover: Identifiable, Hashable {
        case naming
        case deleting(String)
        var id: Self { self }
    }

    var body: some View {
        Menu {
            ForEach(library.entries.indices, id: \.self) { index in
                entry(library.entries[index])
            }
            // The menu's items are made as it opens: the moment to look at the folders.
            .onAppear(perform: opening)
        } label: {
            label()
        }
        .menuStyle(.button)
        .buttonStyle(.glass)
        .buttonSizing(.flexible)
        .frame(width: width)
        .popover(item: $popover, arrowEdge: .bottom) { which in
            switch which {
            case .naming:
                NameSheetView(title: library.saveTitle, note: library.saveNote, name: library.suggestedName,
                              names: library.names,
                              save: { name in
                                  popover = nil
                                  try? library.save(name)
                              },
                              cancel: { popover = nil })
            case .deleting(let name):
                DeleteQuestionView(name: name,
                                   delete: {
                                       popover = nil
                                       try? library.delete(name)
                                   },
                                   cancel: { popover = nil })
            }
        }
    }

    @ViewBuilder
    private func entry(_ entry: LibraryMenu.Entry) -> some View {
        switch entry {
        case .file(let name, let ticked?):
            Toggle(name, isOn: Binding(get: { ticked }, set: { _ in try? library.load(name) }))
        case .file(let name, nil):
            Button(name) { try? library.load(name) }
        case .standard(let title):
            Button(title, action: library.loadStandard)
        case .divider:
            Divider()
        case .save(let title):
            Button(title) { popover = .naming }
        case .delete(let title, let names):
            Menu(title) {
                ForEach(names, id: \.self) { name in
                    Button(name) { popover = .deleting(name) }
                }
            }
        }
    }
}

/// What a `LibraryMenuView` lists and does: the entries, the files a new name
/// is checked against, and the actions.
struct LibraryMenuFiles {
    let entries: [LibraryMenu.Entry]
    let names: [String]
    /// The name popover's title and its line about what is stored.
    let saveTitle: String
    let saveNote: String
    /// What the name field opens with.
    let suggestedName: String
    let load: (String) throws -> Void
    var loadStandard: () -> Void = {}
    let save: (String) throws -> Void
    let delete: (String) throws -> Void
}

/// What Delete asks before a file goes: "Delete “Bright”? It goes to the
/// Trash." with Cancel (Return) and Delete. Esc closes the popover.
struct DeleteQuestionView: View {

    let name: String
    let delete: () -> Void
    let cancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(LibraryMenu.deleteQuestion(name))
                .font(.system(size: 13))
                .foregroundStyle(Artwork.cream)
                .frame(maxWidth: 260, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
            HStack {
                Spacer()
                // Return keeps the file: deleting takes a click.
                Button("Cancel", action: cancel)
                    .keyboardShortcut(.defaultAction)
                Button("Delete", role: .destructive, action: delete)
            }
        }
        .padding(14)
        .fixedSize()
        .preferredColorScheme(.dark)
    }
}
