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
}
