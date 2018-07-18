//
//  ResultCrashDemoTests.swift
//  ResultCrashDemoTests
//
//  Created by Cody Rayment on 2018-06-12.
//  Copyright © 2018 Robots & Pencils Inc. All rights reserved.
//

import XCTest

class ResultCrashTests: XCTestCase {
    
    /*
     Demonstrates a crash when passing a block property of a generic class directly to an escaping block parameter.
     This crash occurs when directly passing `box.block` to an escaping completion handler.
     If the parameter is not @escaping then it does not crash.
     If you pass a block directly and call box.block($0) then it does not crash.
     If the BlockBox isn't generic then it does not crash.
     */
    func testEscapingBlockInGenericWrapper() {
        let exp = expectation(description: "futureValue")
        
        // Use a Generic class to store a block that takes our Result
        let box = BlockBox<String>(block: { value in
            print(value)
            exp.fulfill()
        })
        
        
        // If we pass a closure that calls box.block everything works as desired.
        escapingCompletion(completion: { box.block($0) })
        
        // If we use the block directly as the @escaping completion handler, we crash
        escapingCompletion(completion: box.block) // Crashes
        
        waitForExpectations(timeout: 1, handler: nil)
    }
}

// MARK: - Helpers

/// Class wrapper around a block of (T) -> Void
class BlockBox<T> {
    let block: (T) -> Void
    
    init(block: @escaping (T) -> Void) {
        self.block = block
    }
}

func escapingCompletion(completion: @escaping (String) -> Void) {
    completion("Foo")
}
