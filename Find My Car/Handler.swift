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
    var lastActivity: String = ""
    var controller:MasterViewController
    
    init(locManager: CLLocationManager, controller:MasterViewController) {
        var manager:CMMotionActivityManager = CMMotionActivityManager()
        queue = NSOperationQueue()
        self.controller = controller
        manager.startActivityUpdatesToQueue(queue, withHandler: {
            (activity:CMMotionActivity!) in
            if (locManager.location == nil) {
                return
            }
            var newActivity = Activity(activity: activity, location:locManager.location)
            if (self.lastActivity == "Car" && newActivity.type != "Car") || (self.lastActivity == "Bike" && newActivity.type != "Bike") {
                self.postActivity(newActivity)
            }
            self.lastActivity = newActivity.type
        })
    }
    
    func postActivity(newActivity:Activity) {
        var vehicle = PFObject(className: "Vehicle")
        vehicle["location"] = PFGeoPoint(latitude: newActivity.latitude, longitude: newActivity.longitude)
        vehicle["type"] = newActivity.type
        vehicle["user"] = PFUser.currentUser()
        vehicle.saveInBackgroundWithBlock({ (Bool, NilLiteralConvertible) -> Void in
            self.controller.updateMarkers() // update the markers on the view after the newest marker has been saved
        })
    }
}