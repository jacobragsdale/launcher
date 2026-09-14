import XCTest
@testable import Launcher

final class SnapTests: XCTestCase {
    func testRects() {
        let v = CGRect(x: 0, y: 25, width: 1000, height: 700)
        XCTAssertEqual(Snap.rect(2, in: v), CGRect(x: 0, y: 25, width: 500, height: 700))
        XCTAssertEqual(Snap.rect(3, in: v), CGRect(x: 500, y: 25, width: 500, height: 700))
        XCTAssertEqual(Snap.rect(4, in: v), v)
    }
}
