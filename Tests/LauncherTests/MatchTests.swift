import XCTest
@testable import Launcher

final class MatchTests: XCTestCase {
    func testTiers() {
        XCTAssertEqual(Apps.score(query: "saf", name: "Safari"), 0)
        XCTAssertEqual(Apps.score(query: "code", name: "Visual Studio Code"), 1)
        XCTAssertEqual(Apps.score(query: "vsc", name: "Visual Studio Code"), 2)
        XCTAssertEqual(Apps.score(query: "vsl", name: "Visual Studio Code"), 3)
        XCTAssertNil(Apps.score(query: "xyz", name: "Safari"))
        XCTAssertEqual(Apps.score(query: "Éa", name: "eA"), 0)
    }

    func testRanking() {
        let app = { (n: String, u: Int) in App(url: URL(fileURLWithPath: "/\(n).app"), name: n, uses: u) }
        let apps = [app("Alpha", 0), app("Safari", 5), app("Slack", 50), app("Zed", 90)]
        XCTAssertEqual(Apps.matches("", in: apps).map(\.name), ["Zed", "Slack", "Safari", "Alpha"])
        XCTAssertEqual(Apps.matches("s", in: apps).map(\.name), ["Slack", "Safari"])
    }
}
