//
//  DetailViewController.swift
//  Find My Car
//
//  Created by Mehul Goyal on 11/3/14.
//  Copyright (c) 2014 Mehul Goyal. All rights reserved.
//

import UIKit
import Social

class DetailViewController: UITableViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var detailDescriptionLabel: UILabel!
    var locations = [Location]()
    let cellIdentifier = "cellIdentifier"
    var selectedRows = [NSIndexPath]()
    var deleteButton:UIBarButtonItem?

    var detailItem: AnyObject? {
        didSet {
            // Update the view.
            self.configureView()
        }
    }

    func configureView() {
        // Update the user interface for the detail item.
        if let detail: AnyObject = self.detailItem {
            if let label = self.detailDescriptionLabel {
                label.text = detail.description
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.configureView()
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        self.navigationItem.leftBarButtonItem = editButtonItem()
        deleteButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Trash, target: self, action: "deleteButtonHandler:")
        self.tableView.allowsMultipleSelectionDuringEditing = true
        locations = Location.getLocations()
        var setEditingMode:Bool = false
        var setNonEditingMode:Bool = false
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            while (2>1) {
                if (self.editing && !setEditingMode) {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.navigationItem.rightBarButtonItem = self.deleteButton
                        setEditingMode = true
                        setNonEditingMode = false
                    }
                }
                else if (!self.editing && !setNonEditingMode) {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.navigationItem.rightBarButtonItem = nil
                        setNonEditingMode = true
                        setEditingMode = false
                    }
                }
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        locations = Location.getLocations()
        super.viewWillAppear(true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return locations.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell:UITableViewCell = self.tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as UITableViewCell
        cell.textLabel?.text = self.locations[indexPath.row].description
        return cell
    }
    
    override func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        if (editing) {
            var i:Int = 0
            for indexPath in selectedRows {
                selectedRows.removeAtIndex(i)
                i++
            }
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if (editing) {
            selectedRows.append(indexPath)
            return
        }
        let alert = UIAlertController(title: nil, message: "What would you like to do?", preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        let location = self.locations[indexPath.row]
        
        alert.addAction(UIAlertAction(title: "Edit Location Name", style: UIAlertActionStyle.Default,
            handler: { (alert: UIAlertAction!) in
                var editLocation = UIAlertController(title: "Edit Location Name", message: "Enter the new location name.", preferredStyle: UIAlertControllerStyle.Alert)
                editLocation.addTextFieldWithConfigurationHandler({(textField: UITextField!) in
                    textField.placeholder = location.type
                    textField.keyboardAppearance = UIKeyboardAppearance.Dark
                })
                editLocation.addAction(UIAlertAction(title: "Save", style: UIAlertActionStyle.Default, handler:
                    { (alert: UIAlertAction!) in
                        location.updateType((editLocation.textFields?[0] as UITextField).text)
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                            
                            self.locations = Location.getLocations() // update the data so we can refresh the table view
                            
                            dispatch_async(dispatch_get_main_queue()) {
                                self.tableView.reloadData()
                            }
                            
                        }
                    }))
                self.presentViewController(editLocation, animated: true, completion: nil)
            }
        ))
        
        alert.addAction(UIAlertAction(title: "Set active location", style: UIAlertActionStyle.Default,
            handler: { (alert: UIAlertAction!) in
                location.makeActive()
            }
        ))
        
        alert.addAction(UIAlertAction(title: "Share", style: UIAlertActionStyle.Default,
            handler: { (alert: UIAlertAction!) in
                var fbOrTwitter = UIAlertController(title: nil, message: "Select a social network.", preferredStyle: .Alert)
                fbOrTwitter.addAction((UIAlertAction(title: "Facebook", style: UIAlertActionStyle.Default,
                    handler: { (alert: UIAlertAction!) in
                        self.share(location, network: "Facebook")
                    }
                )))
                fbOrTwitter.addAction((UIAlertAction(title: "Twitter", style: UIAlertActionStyle.Default,
                    handler: { (alert: UIAlertAction!) in
                        self.share(location, network: "Twitter")
                    }
                )))
                self.presentViewController(fbOrTwitter, animated: true, completion: nil)
            }
        ))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        
        self.presentViewController(alert, animated: true, completion: {
            self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
        })
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            deleteRow(indexPath)
        }
    }
    
    func deleteRow(indexPath:NSIndexPath) -> Void {
        let location = self.locations[indexPath.row]
        location.deleteObject()
        locations.removeAtIndex(indexPath.row)
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
    }
    
    func share(location:Location, network:String) {
        var serviceType = network == "Twitter" ? SLServiceTypeTwitter : SLServiceTypeFacebook
        if SLComposeViewController.isAvailableForServiceType(serviceType){
            var sheet:SLComposeViewController = SLComposeViewController(forServiceType: serviceType)
            sheet.setInitialText("I found my car (\(location)) using Find My Car on iOS. Go check it out.")
            self.presentViewController(sheet, animated: true, completion: nil)
        } else {
            var alert = UIAlertController(title: "Accounts", message: "Please login to a \(network) account to share.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    func deleteButtonHandler(sender:AnyObject) {
        selectedRows.sort { $1.row < $0.row }
        for i in selectedRows {
            deleteRow(i)
        }
        selectedRows.removeAll(keepCapacity: false)
    }
}

