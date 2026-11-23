import AppKit
import AudioToolbox
import AudioToolbox.AUCocoaUIView
import SwiftUI
import FanfrnochUI

/// The plug-in's window in a host: the instrument's panel with the keyboard or the pads below
/// it, as in the app, without the app's settings, which a host has of its own. The panel follows
/// the host every 40 ms (`InstrumentPanel`).
struct AudioUnitWindow: View {

    let model: AudioUnitModel

    var body: some View {
        InstrumentPanel(model: model) {
            ModeFooterView(model: model)
        }
        .fixedSize()                    // the panel's width, as tall as its contents
        .instrumentBackground()
        // A key or pad held with the mouse would sound on (its mouse-up never comes), and a knob
        // would go on listening for a controller.
        .onDisappear { model.windowClosed() }
    }
}

/// The class a host asks for the plug-in's window. The Audio Unit names it, and the bundle it
/// lives in, in its `kAudioUnitProperty_CocoaUI` property (FanfrnochAU.cpp); the name must stay in
/// step with `FANFRNOCH_AU_VIEW_CLASS`.
@objc(FanfrnochAUViewFactory)
@MainActor
public final class FanfrnochAUViewFactory: NSObject, @preconcurrency AUCocoaUIBase {

    public func interfaceVersion() -> UInt32 { 0 }

    public func uiView(forAudioUnit unit: AudioUnit, with preferredSize: NSSize) -> NSView? {
        Artwork.bundle = Bundle(for: FanfrnochAUViewFactory.self)      // the component, not the host
        guard let model = AudioUnitModel(unit: unit) else { return nil }
        let view = NSHostingView(rootView: AudioUnitWindow(model: model))
        // A host shows the view at the size it comes in.
        view.frame = NSRect(x: 0, y: 0, width: InstrumentPanel<EmptyView, EmptyView>.width, height: view.fittingSize.height)
        return view
    }
}
