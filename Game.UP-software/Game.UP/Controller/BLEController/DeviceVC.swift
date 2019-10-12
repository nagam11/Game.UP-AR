//
//  ViewController.swift
//  BLEDemo
//
//  Created by Jindrich Dolezy on 11/04/2018.
//  Copyright © 2018 Dzindra. All rights reserved.
//

import UIKit
import UserNotifications


class DeviceVC: UIViewController {
    
    enum ViewState: Int {
        case disconnected
        case connected
        case ready
    }
    
    var device: BTDevice? {
        didSet {
            navigationItem.title = device?.name ?? "Device"
            device?.delegate = self
        }
    }
    
   /* @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var greenSwitch: UISwitch!
    @IBOutlet weak var yellowSwitch: UISwitch!
    @IBOutlet weak var disconnectButton: UIButton!
    @IBOutlet weak var touchLabel: UILabel!*/
    
    var viewState: ViewState = .disconnected {
        didSet {
        }
    }
    
    deinit {
        //device?.disconnect()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewState = .disconnected
    }
    
    @IBAction func disconnectAction() {
        device?.disconnect()
    }
    
    @IBAction func greenChanged(_ sender: Any) {
         //device?.b1_led = greenSwitch.isOn
    }
    
    @IBAction func yellowChanged(_ sender: Any) {
        //device?.b2_led = yellowSwitch.isOn
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "sendDeviceSegue" {
            let vc : ARViewController = segue.destination as! ARViewController
            vc.device = self.device
        }
    }
}

extension DeviceVC: BTDeviceDelegate {
    
    func deviceLongTouchB3Changed(value: Int) {}
           
    func deviceLongTouchB5Changed(value: Int) {}
 
    func deviceLongTouchB7Changed(value: Int) {}
    
    func deviceTouchChanged(value: Int) {}
    
}
