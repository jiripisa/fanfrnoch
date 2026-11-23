import SwiftUI
import FanfrnochCore

/// MIDI input, audio output and the Audio Unit installer.
struct SettingsView: View {

    @Bindable var model: AppModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Form {
                Section("MIDI input") {
                    Picker("Device", selection: $model.midiSource) {
                        Text("All devices").tag(MIDISourceChoice.all)
                        Text("None").tag(MIDISourceChoice.none)
                        if !model.midiSources.isEmpty { Divider() }
                        ForEach(model.midiSources) { source in
                            Text(source.name).tag(MIDISourceChoice.source(source.id))
                        }
                        if let missing = model.missingMIDISourceName {
                            Text("\(missing) (not connected)").tag(model.midiSource)
                        }
                    }
                    Picker("Channel", selection: $model.midiChannel) {
                        Text("All channels").tag(MIDIChannelFilter.omni)
                        ForEach(1...16, id: \.self) { channel in
                            Text("Channel \(channel)").tag(MIDIChannelFilter.channel(channel))
                        }
                    }
                    Text("Other applications can also send MIDI to the port “Fanfrnoch”.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Section("Audio output") {
                    Picker("Device", selection: $model.audioDeviceUID) {
                        Text("System default").tag(String?.none)
                        if !model.audioDevices.isEmpty { Divider() }
                        ForEach(model.audioDevices) { device in
                            Text(device.name).tag(String?.some(device.uid))
                        }
                        if let missing = model.missingAudioDeviceName {
                            Text("\(missing) (not connected)").tag(model.audioDeviceUID)
                        }
                    }
                    if model.audioChannelPairs.count > 1 {
                        Picker("Channels", selection: Binding(get: { model.audioChannelPairInUse },
                                                              set: { model.audioFirstChannel = $0 })) {
                            ForEach(model.audioChannelPairs, id: \.self) { first in
                                Text("\(first + 1) – \(first + 2)").tag(first)
                            }
                        }
                    }
                    if let problem = model.audioProblem {
                        Text(problem).font(.footnote).foregroundStyle(.red)
                    }
                }
                Section("Audio Unit plug-in") {
                    Text(model.audioUnitStatus)
                    Button("Install Audio Unit") { model.installAudioUnit() }
                        .disabled(!model.canInstallAudioUnit)
                    Text("Copies Fanfrnoch.component into ~/Library/Audio/Plug-Ins/Components so that Ableton Live, Logic Pro and other hosts can load it. Rescan plug-ins or restart the host afterwards.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
            HStack {
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding([.horizontal, .bottom], 16)
        }
        .frame(width: 460, height: 520)
        .onAppear {
            model.refreshDevices()
            model.refreshAudioUnitStatus()
        }
    }
}
