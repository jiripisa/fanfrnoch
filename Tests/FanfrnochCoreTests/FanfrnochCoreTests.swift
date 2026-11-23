import Testing
@testable import FanfrnochCore

@Suite("FanfrnochCore")
struct FanfrnochCoreTests {

    @Test("Greeting names the app")
    func greetingNamesTheApp() {
        #expect(FanfrnochCore.greeting(appName: "Fanfrnoch") == "Welcome to Fanfrnoch")
    }
}
