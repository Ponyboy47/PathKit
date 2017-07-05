//
//  PathKitTests.swift
//  Strings
//
//  Created by Jacob Williams on 7/3/17.
//

import XCTest
@testable import PathKit

class PathKitTests: XCTestCase {
    let fixtures = Path(#file).parent + "Fixtures"

    func setCWD() {
        Path.current = Path(#file).parent
        XCTAssertTrue(Path.current == Path(#file).parent)
        XCTAssertTrue(Path.current.isDirectory)
    }
}


#if os(Linux)
    extension PathKitTests {
        static var allTests = [
            ("setCWD", setCWD)
        ]
    }
#endif
