//
//  ResultCrashDemoTests.swift
//  ResultCrashDemoTests
//
//  Created by Cody Rayment on 2018-06-12.
//  Copyright © 2018 Robots & Pencils Inc. All rights reserved.
//

import XCTest

class ResultCrashTests: XCTestCase {
    
    // MARK: - Crash 1: Passing a boxed block that takes a Result directly to an escaping completion handler.
    /*
     This crash occurs when directly passing `box.block` to an escaping completion handler. If it's not
     @escaping then the crash doesn't occur. If you pass a block directly and call box.block($0) then it also
     doesn't crash.
     */
    
    func testEscapingBlockThatWorks() {
        let exp = expectation(description: "futureValue")
        
        // Use a class Box to store a block that takes our Result
        let box = BlockBox<Result<String>>(block: { result in
            print(result)
            exp.fulfill()
        })
        
        // When we use a closure and call the boxed block inside it, everyting is fine.
        escapingCompletionResult(completion: { box.block($0) })
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testEscapingBlockThatCrashes() {
        let exp = expectation(description: "futureValue")
        
        // Use a class Box to store a block that takes our Result
        let box = BlockBox<Result<String>>(block: { result in
            print(result)
            exp.fulfill()
        })
        
        // If we use the block directly as the @escaping completion handler, we crash
        escapingCompletionResult(completion: box.block)
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    
    // MARK: - Crash 2: Result with associated type where value is HTTPCookie from network request.
    /*
     This crash seems to be related to the associated type in the Result<T> being of type HTTPCookie
     I can't get it to crash when I construct the HTTPCookie myself, but when it comes from a real
     network request then it crashes.
     
     Note: These tests use a real network request to jsonplaceholder.typicode.com and therefore require
     an internet connection.
     */
    
    let networkClient = NetworkClient()
    
    func testNetworkFetchThatWorks() {
        let networkExpectation = expectation(description: "network fetch")
        networkClient.fetchData(completion: { (result) in
            print(result)
            networkExpectation.fulfill()
        })
        wait(for: [networkExpectation], timeout: 2)
    }
    
    func testNetworkFetchThatCrashes() {
        let networkExpectation = expectation(description: "network fetch")
        networkClient.fetchCookies(completion: { (result) in
            // This crashes when we access result if the network request succeeded.
            // If we get a network error then there is no crash.
            // Something about the associated value in the enum being `[HTTPCookie]`?
            print(result)
            networkExpectation.fulfill()
        })
        wait(for: [networkExpectation], timeout: 2)
    }
}


// MARK: - Types

/// A typical Result enum
public enum Result<Subject> {
    case value(Subject)
    case error(Error)
}

/// Class wrapper around a block of (T) -> Void
class BlockBox<T> {
    let block: (T) -> Void
    
    init(block: @escaping (T) -> Void) {
        self.block = block
    }
}


// MARK: - Helpers

// If completion is not @escaping we don't crash
func escapingCompletionResult(completion: @escaping (Result<String>) -> Void) {
    let value = "Foo"
    let result = Result.value(value)
    completion(result)
}

class NetworkClient {
    var activeTasks: [Any] = []
    let session = URLSession(configuration: .ephemeral)
    
    func fetchData(completion: @escaping (Result<Data>) -> Void) {
        let url = URL(string: "https://jsonplaceholder.typicode.com/posts/1")!
        
        let task = session.dataTask(with: url) { (data, response, error) in
            if let data = data {
                completion(Result.value(data))
            } else {
                completion(Result.error(error!))
            }
        }
        task.resume()
        activeTasks.append(task)
    }
    
    func fetchCookies(completion: @escaping (Result<[HTTPCookie]>) -> Void) {
        let url = URL(string: "https://jsonplaceholder.typicode.com/posts/1")!
        
        let task = session.dataTask(with: url) { (data, response, error) in
            if let response = response as? HTTPURLResponse, let headers = response.allHeaderFields as? [String: String] {
                let cookies = HTTPCookie.cookies(withResponseHeaderFields: headers, for: url)
                let result = Result.value(cookies)
                
//                print(result) // This will crash

                // If we ignore the response cookie and use the mock cookies, no crash
//                let result = Result<[HTTPCookie]>.value([HTTPCookie.mock, HTTPCookie.mock2])
                
                completion(result)
            } else {
                completion(Result.error(error!))
            }
        }
        task.resume()
        activeTasks.append(task)
    }
}

extension HTTPCookie {
    static let mock = HTTPCookie.init(properties: [
        .domain: ".apple.com",
        .path: "/",
        .name: "MyCookie",
        .value: "chocolate chip"
    ])!
    
    static let mock2 =  HTTPCookie.init(properties: [
        .expires: Date(),
        .path: "/",
        .secure: true,
        .name: "__cfduid",
        .domain: ".typicode.com",
        .value: "d8faa06c1060a794404ccb543371827721528752401"
    ])!
}
