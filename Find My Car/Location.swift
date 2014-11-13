//
//  Location.swift
//  Find My Car
//
//  Created by Mehul Goyal on 11/10/14.
//  Copyright (c) 2014 Mehul Goyal. All rights reserved.
//

import Foundation

class Location {
    var latitude:Double
    var longitude:Double
    var type:String
    
    init(geoPoint:PFGeoPoint, type:String) {
        latitude = geoPoint.latitude
        longitude = geoPoint.longitude
        self.type = type
    }
    
    class func getLocations() -> [Location] {
        var locations = [Location]()
        if (PFUser.currentUser().objectId == nil) {
            return locations
        }
        var query = PFQuery(className:"Vehicle")
        query.whereKey("user", equalTo:PFUser.currentUser())
        for object in query.findObjects() {
            var pfObj:PFObject = object as PFObject
            var loc:Location = Location(geoPoint: pfObj["location"] as PFGeoPoint, type: pfObj["type"] as String)
            locations.append(loc)
        }
        return locations
    }
}