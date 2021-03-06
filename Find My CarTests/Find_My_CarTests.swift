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
import CoreLocation

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
        var location:CLLocation = CLLocation(latitude: Double(rand()), longitude: Double(rand()))
        
        var testObj:Activity = Activity(activity: activity, location: CLLocation(latitude: 50, longitude: 100))
        
        XCTAssertEqual(activity.cycling, false)
        XCTAssertEqual(activity.automotive, false)
        XCTAssertEqual(activity.unknown, true)
        XCTAssertEqual(testObj.type, "")
        XCTAssertEqual(testObj.latitude, 50)
        XCTAssertEqual(testObj.longitude, 100)
    }
}
