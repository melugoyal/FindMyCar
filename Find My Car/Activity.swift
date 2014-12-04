//
//  Activity.swift
//  Find My Car
//
//  Created by Mehul Goyal on 11/3/14.
//  Copyright (c) 2014 Mehul Goyal. All rights reserved.
//

import Foundation
import CoreMotion
import CoreLocation

class Activity {
    var time:NSDate
    var confidence:Int
    var car:Bool
    var bike:Bool
    var type:String = ""
    var longitude:Double
    var latitude:Double
    var elevation:Double
    init(activity:CMMotionActivity, location:CLLocation) {
        time = activity.startDate
        confidence = activity.confidence == CMMotionActivityConfidence.High ? 2 : (activity.confidence == CMMotionActivityConfidence.Medium ? 1 : 0) // 2 is high, 0 is low
        var highConfidence:Bool = confidence == 2
        bike = activity.cycling && highConfidence
        car = activity.automotive && highConfidence
        type = bike ? "Bike" : (car ? "Car" : "")
        latitude = location.coordinate.latitude
        longitude = location.coordinate.longitude
        elevation = location.altitude
    }
}