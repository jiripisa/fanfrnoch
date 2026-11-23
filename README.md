# Fanfrnoch

A playable synthesized friction drum, after the Czech fanfrnoch: wet-hand strokes on a horsehair drum, its relatives from the Brummtopf to the cuíca, as an Audio Unit and a standalone app.

Native macOS app (SwiftUI, macOS 26 or later), built with Swift Package
Manager and shell scripts; no Xcode project.

Website and manual: https://jiripisa.github.io/fanfrnoch/

## Build and run

You need the Xcode command line tools.

```
./run.sh            # debug build, runs in the terminal with logs (Ctrl+C quits)
./run.sh release    # optimized build, opens the app
swift test          # tests
./build.sh dist     # signed, notarized DMG (needs a Developer ID, see development_workflow.md)
```

Details: [development_workflow.md](development_workflow.md).

## License

MIT License, see [LICENSE](LICENSE).
