import XCTest
@testable import Launcher

final class DoubleTapTests: XCTestCase {
    func testTaps() {
        var d = DoubleTap()
        XCTAssertFalse(d.feed(.cmd, at: 0)); XCTAssertFalse(d.feed(.none, at: 0.1))
        XCTAssertFalse(d.feed(.cmd, at: 0.2)); XCTAssertTrue(d.feed(.none, at: 0.3))
        XCTAssertFalse(d.feed(.cmd, at: 0.4)); XCTAssertFalse(d.feed(.none, at: 0.5)) // a third tap starts over

        d = DoubleTap() // Cmd+C, Cmd+V
        _ = d.feed(.cmd, at: 0); _ = d.feed(.other, at: 0.05); _ = d.feed(.none, at: 0.1)
        _ = d.feed(.cmd, at: 0.2); _ = d.feed(.other, at: 0.25)
        XCTAssertFalse(d.feed(.none, at: 0.3))

        d = DoubleTap() // too slow
        _ = d.feed(.cmd, at: 0); _ = d.feed(.none, at: 0.1); _ = d.feed(.cmd, at: 0.5)
        XCTAssertFalse(d.feed(.none, at: 0.6))
    }
}
