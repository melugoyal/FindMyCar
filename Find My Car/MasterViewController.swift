//
//  MasterViewController.swift
//  Find My Car
//
//  Created by Mehul Goyal on 11/3/14.
//  Copyright (c) 2014 Mehul Goyal. All rights reserved.
//

import CoreMotion
import AVFoundation

class MasterViewController: UITableViewController, CLLocationManagerDelegate, GMSMapViewDelegate, AVAudioPlayerDelegate {
    
    @IBOutlet weak var addButton: UIBarButtonItem! // the button that a user will use to add a new location
    var listenForPinDrop:Bool = false // a variable to tell us whether we should be listening for a user to drop a pin on the map (used for adding custom locations)
    var locationOfDroppedPin:CLLocationCoordinate2D! // the location of the pin dropped by the user
    var newLocationPrompt:UIAlertController! // the prompt asking the user to enter information about a new location

    var detailViewController: DetailViewController? = nil
    var objects = NSMutableArray()

    var locationManager:CLLocationManager!
    var gmaps:GMSMapView?
    var player:AVPlayer?
    var activeLocation:Location!
    var distanceLabel:UILabel?
    let distanceLabelXpos:CGFloat = 5
    let distanceLabelYpos:CGFloat = 400
    var elevationIndicator:UIImageView?
    let upArrow:UIImage = UIImage(named: "upArrow.png")!
    let downArrow:UIImage = UIImage(named: "downArrow.png")!

    override func awakeFromNib() {
        super.awakeFromNib()
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            self.preferredContentSize = CGSize(width: 320.0, height: 600.0)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        audioInit()
        locationInit()
        mapInit()
        subviewsAndButtonsInit()
    }
    
    func subviewsAndButtonsInit() {
        distanceLabel = UILabel(frame: CGRectMake(distanceLabelXpos, distanceLabelYpos, view.bounds.width - distanceLabelXpos, view.bounds.height - distanceLabelYpos))
        self.view.addSubview(distanceLabel!)
        elevationIndicator = UIImageView(frame: CGRectMake(view.bounds.width - 50, distanceLabelYpos + 100, 50, 50))
        self.view.addSubview(elevationIndicator!)
        addButton.target = self
        addButton.action = "insertNewLocation:"
    }
    
    func insertNewLocation(sender: AnyObject) {
        
        newLocationPrompt = UIAlertController(title: nil, message: "Enter information about the new location, then click drop pin. You can then drop a pin by pressing and holding a place on the map.", preferredStyle: UIAlertControllerStyle.Alert)
        
        newLocationPrompt.addTextFieldWithConfigurationHandler({(locationNameField: UITextField!) in
            locationNameField.placeholder = "Location Name"
            locationNameField.keyboardAppearance = UIKeyboardAppearance.Dark
        })
        
        newLocationPrompt.addTextFieldWithConfigurationHandler({(elevationField: UITextField!) in
            elevationField.placeholder = "Elevation"
            elevationField.text = "\(self.locationManager.location.altitude)"
            elevationField.keyboardType = UIKeyboardType.DecimalPad
            elevationField.keyboardAppearance = UIKeyboardAppearance.Dark
        })
        
        newLocationPrompt.addAction(UIAlertAction(title: "Drop Pin", style: UIAlertActionStyle.Default, handler:
            { (alert: UIAlertAction!) in
                self.listenForPinDrop = true
            }
        ))
        
        newLocationPrompt.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        
        self.presentViewController(newLocationPrompt, animated: true, completion: nil)
    }
    
    // function to handle a long press on the map. this will be used for users to drop a pin to add a new location.
    func mapView(mapView: GMSMapView!, didLongPressAtCoordinate coordinate: CLLocationCoordinate2D) {
        
        if !listenForPinDrop {
            return
        }
        
        locationOfDroppedPin = coordinate
        let savePrompt = UIAlertController(title: nil, message: "Save?", preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        savePrompt.addAction(UIAlertAction(title: "Save", style: UIAlertActionStyle.Default,
            handler: { (alert: UIAlertAction!) in
                self.listenForPinDrop = false // stop listening for a pin drop
                var vehicle = PFObject(className: "Vehicle")
                vehicle["location"] = PFGeoPoint(latitude: self.locationOfDroppedPin.latitude, longitude: self.locationOfDroppedPin.longitude)
                vehicle["elevation"] = NSString(string:(self.newLocationPrompt.textFields?[1] as! UITextField).text).doubleValue
                vehicle["type"] = (self.newLocationPrompt.textFields?[0] as! UITextField).text
                vehicle["user"] = PFUser.currentUser()
                vehicle["active"] = true
                vehicle.save()
                self.locationOfDroppedPin = nil
                self.updateMarkers() // update the markers again to reflect the changes
            }
        ))
        
        savePrompt.addAction(UIAlertAction(title: "Pick New Location", style: UIAlertActionStyle.Default, handler: nil))
        savePrompt.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler:
            { (alert: UIAlertAction!) in
                self.listenForPinDrop = false
                self.locationOfDroppedPin = nil
            }
        ))
        
        self.presentViewController(savePrompt, animated: true, completion: nil)
    }
    
    // create an audio player that will always run so the app can run in the background
    func audioInit() {
        var sharedInstance:AVAudioSession = AVAudioSession()
        sharedInstance.setCategory(AVAudioSessionCategoryPlayback, withOptions: AVAudioSessionCategoryOptions.MixWithOthers, error: nil)
        self.player = AVPlayer(playerItem: AVPlayerItem(URL: NSURL(string: "http://www.xamuel.com/blank-mp3-files/point1sec.mp3")))
        self.player?.actionAtItemEnd = AVPlayerActionAtItemEnd.None
        self.player?.play()
    }
    
    func updateMarkers() {
        gmaps?.clear() // remove all the currently shown markers
        
        // get locations in a background thread and add the markers to the map
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            
            self.activeLocation = Location.getActiveLocation()
            if self.activeLocation != nil {
                dispatch_async(dispatch_get_main_queue()) {
                    self.addMarker(self.activeLocation)
                }
            }
        }
    }
    
    func locationInit() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        self.activeLocation = Location.getActiveLocation()
        startLocationUpdates()
    }
    
    func mapInit() {
        var latitude:CLLocationDegrees = locationManager.location == nil ? 0 : locationManager.location.coordinate.latitude
        var longitude:CLLocationDegrees = locationManager.location == nil ? 0 : locationManager.location.coordinate.longitude
        
        var target: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        var camera: GMSCameraPosition = GMSCameraPosition(target: target, zoom: 10, bearing: 0, viewingAngle: 0)
        
        gmaps = GMSMapView(frame: CGRectMake(0, 0, self.view.bounds.width, self.view.bounds.height))
        if let map = gmaps {
            map.myLocationEnabled = true
            map.camera = camera
            map.delegate = self
            
            self.view.addSubview(gmaps!)
        }
    }
    
    func addMarker(location:Location) {
        var position:CLLocationCoordinate2D = CLLocationCoordinate2DMake(location.latitude, location.longitude)
        var marker:GMSMarker = GMSMarker(position: position)
        marker.title = location.description
        marker.map = gmaps
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [AnyObject]) {
        var currLocation:CLLocation = locations.last as! CLLocation
        var currAltitude:Double = currLocation.altitude
        var currLatitude:Double = currLocation.coordinate.latitude
        var currLongitude:Double = currLocation.coordinate.longitude
        
        // get the most recent location and calculate the distance in a background thread
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            if self.activeLocation == nil {
                return
            }
            var distance:Double = self.activeLocation.getDistanceFromLocation(currLocation)
            var above:Bool = self.activeLocation.elevation > currLocation.altitude
            
            dispatch_async(dispatch_get_main_queue()) {
                self.distanceLabel!.text = String(format: "%.2f m", distance)
                self.elevationIndicator?.image = above ? self.upArrow : self.downArrow
            }
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        if (CMMotionActivityManager.isActivityAvailable()) {
            Handler(locManager:locationManager, controller: self)
            updateMarkers()
        }
        else {
            showErrorAndKill()
        }
    }
    
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
    }
    
    func startLocationUpdates() {
        locationManager.startUpdatingLocation()
    }
    
    func showErrorAndKill() {
        var alert = UIAlertController(title: "Error", message: "error", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: .Default) { (action) in
            exit(0)
            })
        self.presentViewController(alert, animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func insertNewObject(sender: AnyObject) {
        objects.insertObject(NSDate(), atIndex: 0)
        let indexPath = NSIndexPath(forRow: 0, inSection: 0)
    }
}

