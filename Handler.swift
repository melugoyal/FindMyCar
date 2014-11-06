//
//  Handler.swift
//  Find My Car
//
//  Created by Mehul Goyal on 11/3/14.
//  Copyright (c) 2014 Mehul Goyal. All rights reserved.
//

import Foundation
import CoreMotion

class Handler {
    var queue: NSOperationQueue
    var lastActivity: String
    
    init() {
        var manager:CMMotionActivityManager = CMMotionActivityManager()
        queue = NSOperationQueue()
        lastActivity = ""
        manager.startActivityUpdatesToQueue(queue, withHandler: {
            (activity:CMMotionActivity!) in
            var newActivity = Activity(activity: activity)
            if self.lastActivity == "Car" && newActivity.type != "Car" {
                var car = PFObject(className: "Vehicle")
                car["longitude"] = newActivity.longitude
                car["latitude"] = newActivity.latitude
                car["type"] = "Car"
                car.saveInBackgroundWithBlock(nil)
            }
            if self.lastActivity == "Bike" && newActivity.type != "Bike" {
                var bike = PFObject(className: "Vehicle")
                bike["longitude"] = newActivity.longitude
                bike["latitude"] = newActivity.latitude
                bike["type"] = "Bike"
                bike.saveInBackgroundWithBlock(nil)
            }
            self.lastActivity = newActivity.type
        })
    }
}