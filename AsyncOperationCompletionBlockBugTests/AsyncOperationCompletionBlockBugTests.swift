//
//  AsyncOperationCompletionBlockBugTests.swift
//  AsyncOperationCompletionBlockBugTests
//
//  Created by Alexey Kozhevnikov on 29/03/2017.
//  Copyright © 2017 None. All rights reserved.
//

import XCTest
import Mockingjay

@testable import AsyncOperationCompletionBlockBug

class AsyncOperationCompletionBlockBugTests: XCTestCase {
    
    var urlSession: URLSession!
    var operationQueue: OperationQueue!
    
    override func setUp() {
        super.setUp()
        urlSession = URLSession(configuration: .default)
        operationQueue = OperationQueue()
    }
    
    override func tearDown() {
        operationQueue = nil
        urlSession = nil
        super.tearDown()
    }
    
    func testSingleOperationFinished() {
        stub(everything, http(200))
        
        let taskExpectation = expectation(description: "Task completion handler called")
        
        let task = urlSession.dataTask(with: URL(string: "http://dummy.com")!) { data, response, error in
            taskExpectation.fulfill()
        }
        
        let operation = UrlSessionTaskOperation(task: task)
        
        let operationExpectation = expectation(description: "Operation completion block called")
        
        operation.completionBlock = { _ in
            operationExpectation.fulfill()
        }
        
        operationQueue.addOperation(operation)
        
        waitForExpectations(timeout: 1) { _ in
            XCTAssert(self.operationQueue.operationCount == 0)
            XCTAssert(operation.isFinished)
        }
    }
}
