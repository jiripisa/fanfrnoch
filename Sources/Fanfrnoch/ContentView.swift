import AppKit
import SwiftUI
import FanfrnochUI

/// The app's window: the instrument's panel with the keyboard or the pads
/// below it, and the settings behind the gear in its header.
struct ContentView: View {

    let model: AppModel
    @State private var showingSettings = false

    var body: some View {
        InstrumentPanel(model: model) {
            ModeFooterView(model: model)
        } trailing: {
            settingsButton
        }
        .fixedSize()                    // the panel's width, as tall as its contents
        .instrumentBackground()
        .sheet(isPresented: $showingSettings) { SettingsView(model: model) }
        // A key or pad held with the mouse would sound on (the mouse-up goes
        // elsewhere), and a knob would go on listening for a controller.
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didResignActiveNotification)) { _ in
            model.releaseHeld()
            model.learn(nil)
        }
        .onDisappear {
            model.releaseHeld()
            model.learn(nil)
            model.saveIfEdited()
        }
    }

    private var settingsButton: some View {
        Button {
            showingSettings = true
        } label: {
            Image(systemName: "gearshape")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Artwork.cream)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .contentShape(Capsule())
                .glassEffect(.regular.interactive(), in: .capsule)
        }
        .buttonStyle(.plain)
        .help("MIDI input, audio output and the Audio Unit")
        .accessibilityLabel("Settings")
    }
}
