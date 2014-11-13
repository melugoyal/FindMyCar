//
//  MasterViewController.swift
//  Find My Car
//
//  Created by Mehul Goyal on 11/3/14.
//  Copyright (c) 2014 Mehul Goyal. All rights reserved.
//

import UIKit
import CoreMotion
import AVFoundation

class MasterViewController: UITableViewController, CLLocationManagerDelegate, GMSMapViewDelegate, AVAudioPlayerDelegate {

    var detailViewController: DetailViewController? = nil
    var objects = NSMutableArray()
    var locationManager:CLLocationManager!
    var gmaps:GMSMapView?
    var player:AVPlayer?

    override func awakeFromNib() {
        super.awakeFromNib()
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            self.preferredContentSize = CGSize(width: 320.0, height: 600.0)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        audioInit()
        locationInit()
        mapInit()
        updateMarkers()
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
        for location in Location.getLocations() {
            addMarker(location)
        }
    }
    
    func locationInit() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
    }
    
    func mapInit() {
        var latitude:CLLocationDegrees = locationManager.location == nil ? 0 : locationManager.location.coordinate.latitude
        var longitude:CLLocationDegrees = locationManager.location == nil ? 0 : locationManager.location.coordinate.longitude
        
        var target: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        var camera: GMSCameraPosition = GMSCameraPosition(target: target, zoom: 10, bearing: 0, viewingAngle: 0)
        
        gmaps = GMSMapView(frame: CGRectMake(0, 0, self.view.bounds.width, self.view.bounds.height))
        if let map = gmaps? {
            map.myLocationEnabled = true
            map.camera = camera
            map.delegate = self
            
            self.view.addSubview(gmaps!)
        }
    }
    
    func addMarker(location:Location) {
        var position:CLLocationCoordinate2D = CLLocationCoordinate2DMake(location.latitude, location.longitude)
        var marker:GMSMarker = GMSMarker(position: position)
        marker.title = location.type
        marker.map = gmaps
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [AnyObject]) {
    }
    
    override func viewDidAppear(animated: Bool) {
        if (CMMotionActivityManager.isActivityAvailable()) {
            Handler(locManager:locationManager, controller: self)
        }
        else {
            showErrorAndKill()
        }
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

