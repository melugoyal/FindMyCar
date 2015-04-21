//
//  Location.swift
//  Find My Car
//
//  Created by Mehul Goyal on 11/10/14.
//  Copyright (c) 2014 Mehul Goyal. All rights reserved.
//

import Foundation

class Location: Printable {
    var latitude:Double
    var longitude:Double
    var elevation:Double
    var type:String
    var timestamp:NSDate
    var active:Bool
    var description: String {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "MM/dd/yyyy hh:mm a"
        formatter.timeZone = NSTimeZone.localTimeZone()
        return type + " (\(formatter.stringFromDate(timestamp)))"
    }
    
    init(geoPoint:PFGeoPoint, elevation:Double, type:String, timestamp:NSDate, active:Bool) {
        latitude = geoPoint.latitude
        longitude = geoPoint.longitude
        self.elevation = elevation
        self.type = type
        self.timestamp = timestamp
        self.active = active
    }
    
    // incorporate elevation to get the actual distance between two locations
    func getDistanceFromLocation(destination:CLLocation) -> Double {
        var location:CLLocation = CLLocation(latitude: latitude, longitude: longitude)
        return sqrt(pow(location.distanceFromLocation(destination), 2) + pow(elevation - destination.altitude, 2))
    }
    
    // query the database to get all the locations saved for the current user, sorted by creation time
    class func getLocations() -> [Location] {
        var locations = [Location]()
        if (PFUser.currentUser().objectId == nil) {
            return locations
        }
        var query = PFQuery(className:"Vehicle")
        query.whereKey("user", equalTo:PFUser.currentUser())
        query.orderByDescending("createdAt")
        for object in query.findObjects() {
            locations.append(locationFromPFObj(object as! PFObject))
        }
        return locations
    }
    
    // convert a Parse object to a Location object
    class func locationFromPFObj(pfObj:PFObject!) -> Location {
        return Location(geoPoint: pfObj["location"] as! PFGeoPoint, elevation: pfObj["elevation"] as! Double, type: pfObj["type"] as! String, timestamp: pfObj.createdAt, active: pfObj["active"] as! Bool)
    }
    
    // convert a Location object to a Parse object
    func pfObjFromLocation() -> PFObject {
        var query = PFQuery(className:"Vehicle")
        query.whereKey("user", equalTo:PFUser.currentUser())
        query.whereKey("createdAt", equalTo: timestamp)
        return query.getFirstObject()
    }
    
    // get the most recent location saved for the current user
    class func getMostRecentLocation() -> Location? {
        if PFUser.currentUser().objectId == nil {
            return nil
        }
        var query = PFQuery(className:"Vehicle")
        query.whereKey("user", equalTo:PFUser.currentUser())
        query.orderByDescending("createdAt")
        if query.getFirstObject() != nil {
            return locationFromPFObj(query.getFirstObject() as PFObject)
        }
        return nil
    }
    
    // get the current active location for this user. this is the most recent location with the active bit set, and if no locations are set as active then simply the most recent location
    class func getActiveLocation() -> Location? {
        for location in getLocations() {
            if location.active {
                return location
            }
        }
        return getMostRecentLocation()
    }
    
    // update the type attribute of the location object in parse
    func updateType(type:String) {
        var pfObj = pfObjFromLocation()
        pfObj["type"] = type
        pfObj.save() // save synchronously so we can immediately update the data in the table view
    }
    
    // delete the object from the database
    func deleteObject() {
        pfObjFromLocation().delete()
    }
    
    // set this location object as active. this involves setting all the other location objects as inactive
    func makeActive() {
        var query = PFQuery(className:"Vehicle")
        query.whereKey("user", equalTo:PFUser.currentUser())
        query.findObjectsInBackgroundWithBlock {
            (objects: [AnyObject]!, error: NSError!) -> Void in
            for object in objects {
                var pfObj = object as! PFObject
                pfObj["active"] = pfObj.createdAt == self.timestamp ? true : false // set all the other locations to inactive
                pfObj.saveInBackgroundWithBlock(nil)
            }
        }
    }
}