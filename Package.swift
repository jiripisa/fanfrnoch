// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Fanfrnoch",
    platforms: [
        .macOS(.v26)
    ],
    products: [
        // The macOS app (bundle assembled by build.sh — see development_workflow.md §2).
        .executable(name: "Fanfrnoch", targets: ["Fanfrnoch"]),
        // App logic without UI — what `swift test` covers.
        .library(name: "FanfrnochCore", targets: ["FanfrnochCore"]),
        // The Audio Unit and its window (build.sh turns it into Fanfrnoch.component).
        .library(name: "FanfrnochAU", type: .dynamic, targets: ["FanfrnochAU", "FanfrnochAUView", "FanfrnochAUExports"]),
    ],
    dependencies: [
        // Auto-update: the standard updater for apps outside the App Store;
        // EdDSA-signed appcast on GitHub Pages.
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.6.4"),
    ],
    targets: [
        // The sound engine: C++ with a C interface (include/FanfrnochDSP.h).
        .target(
            name: "FanfrnochDSP",
            path: "Sources/FanfrnochDSP"
        ),
        // Apple's AudioUnitSDK (Apache-2.0), vendored: it is not a Swift package.
        .target(
            name: "AudioUnitSDK",
            path: "ThirdParty/AudioUnitSDK",
            exclude: ["LICENSE.txt"],
            sources: ["src"],
            publicHeadersPath: "include",
            linkerSettings: [
                .linkedFramework("AudioToolbox"),
                .linkedFramework("CoreAudio"),
                .linkedFramework("CoreFoundation"),
                .linkedFramework("CoreMIDI"),
            ]
        ),
        // The Audio Unit (AUv2 instrument). build.sh wraps the dylib into Fanfrnoch.component.
        .target(
            name: "FanfrnochAU",
            dependencies: ["FanfrnochDSP", "AudioUnitSDK"],
            path: "Sources/FanfrnochAU"
        ),
        // The Audio Unit's window in a host: the panel over the unit and its engine. The unit
        // names its class (FanfrnochAUViewFactory) in its CocoaUI property.
        .target(
            name: "FanfrnochAUView",
            dependencies: ["FanfrnochCore", "FanfrnochUI"],
            path: "Sources/FanfrnochAUView"
        ),
        // No code, only what the Audio Unit's dynamic library exports.
        .target(
            name: "FanfrnochAUExports",
            path: "Sources/FanfrnochAUExports",
            linkerSettings: [
                // A plug-in shares the host's process with other plug-ins: export only the
                // factory function the host looks up (AudioUnit-Info.plist, factoryFunction).
                .unsafeFlags(["-Xlinker", "-exported_symbol", "-Xlinker", "_FanfrnochAUFactory"]),
            ]
        ),
        .target(
            name: "FanfrnochCore",
            dependencies: ["FanfrnochDSP"],
            path: "Sources/FanfrnochCore"
        ),
        // The instrument's panel, the same in the app's window and in the plug-in's.
        .target(
            name: "FanfrnochUI",
            dependencies: ["FanfrnochCore"],
            path: "Sources/FanfrnochUI"
        ),
        .executableTarget(
            name: "Fanfrnoch",
            dependencies: [
                "FanfrnochCore",
                "FanfrnochUI",
                .product(name: "Sparkle", package: "Sparkle"),
            ],
            path: "Sources/Fanfrnoch",
            linkerSettings: [
                // Embedded frameworks ship in Contents/Frameworks (build.sh).
                .unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "@executable_path/../Frameworks"]),
            ]
        ),
        // The throwaway prototype (.planning/research/spike) as a C++ reference the
        // engine is compared against in tests. Test-only: never linked into the app.
        .target(name: "FanfrnochReference", path: "Tests/FanfrnochReference"),
        .testTarget(
            name: "FanfrnochCoreTests",
            // The Audio Unit too, which the tests run inside their own process, its window's
            // model, and the panel's logic that does not need a window.
            dependencies: ["FanfrnochCore", "FanfrnochDSP", "FanfrnochReference", "FanfrnochAU", "FanfrnochAUView", "FanfrnochUI"],
            path: "Tests/FanfrnochCoreTests"
        ),
    ],
    // AudioUnitSDK needs C++23.
    cxxLanguageStandard: .cxx2b
)
