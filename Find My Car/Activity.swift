//
//  Activity.swift
//  Find My Car
//
//  Created by Mehul Goyal on 11/3/14.
//  Copyright (c) 2014 Mehul Goyal. All rights reserved.
//

import Foundation
import CoreMotion

class Activity {
    var time: NSDate
    var confidence: Int
    var car: Bool
    var bike: Bool
    var notCarNorBike: Bool
    var type: String = ""
    var longitude: Double
    var latitude: Double
    init(activity:CMMotionActivity) {
        notCarNorBike = activity.walking || activity.running || activity.stationary || activity.unknown
        bike = activity.cycling
        car = activity.automotive
        time = activity.startDate
        confidence = activity.confidence == CMMotionActivityConfidence.High ? 2 : (activity.confidence == CMMotionActivityConfidence.Medium ? 1 : 0) // 2 is high, 0 is low
        type = bike ? "Bike" : (car ? "Car" : "")
        latitude = 0
        longitude = 0
    }
}
