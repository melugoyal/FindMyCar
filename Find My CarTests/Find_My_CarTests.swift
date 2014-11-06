//
//  Find_My_CarTests.swift
//  Find My CarTests
//
//  Created by Mehul Goyal on 11/3/14.
//  Copyright (c) 2014 Mehul Goyal. All rights reserved.
//

import UIKit
import XCTest
import CoreMotion

class Find_My_CarTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testActivityInit() {
        var activity:CMMotionActivity = CMMotionActivity()
        var testObj:Activity = Activity(activity: activity)
        
        XCTAssertEqual(activity.cycling, false)
        XCTAssertEqual(activity.automotive, false)
        XCTAssertEqual(activity.unknown, true)
        XCTAssertEqual(testObj.type, "")
    }
}
