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
           /* switch viewState {
            case .disconnected:
                /*touchLabel.text = "Disconnected"
                greenSwitch.isEnabled = false
                greenSwitch.isOn = false
                yellowSwitch.isEnabled = false
                yellowSwitch.isOn = false
                disconnectButton.isEnabled = false*/
            case .connected:
                /*statusLabel.text = "Probing..."
                greenSwitch.isEnabled = true
                yellowSwitch.isEnabled = true
                disconnectButton.isEnabled = true*/
            //serialLabel.isHidden = true
            case .ready:
                /*statusLabel.text = "Ready"
                greenSwitch.isEnabled = true
                yellowSwitch.isEnabled = true
                disconnectButton.isEnabled = true*/
                
                if let b = device?.b1_led {
                    //greenSwitch.isOn = b
                }
                if let v = device?.touch {
                    print(v)
                   // touchLabel.text = String(v)
                }
                if let s = device?.b2_led {
                    //yellowSwitch.isOn = s
                }
            }*/
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
    func deviceB4Changed(value: Int) {
        
    }
    
    func deviceB6Changed(value: Int) {
        
    }
    func deviceLongTouchB1Changed(value: Int) {
           
       }
    func deviceLongTouchB2Changed(value: Int) {
           
       }
    func deviceLongTouchB3Changed(value: Int) {
           
       }
    func deviceLongTouchB6Changed(value: Int) {
           
       }
    func deviceLongTouchB4Changed(value: Int) {
        
    }
    
    func deviceLongTouchB5Changed(value: Int) {
        
    }
    
    func deviceSerialChanged(value: String) {
    }
    
    func deviceB2Changed(value: Int) {
        //yellowSwitch.setOn(value, animated: true)
        
     /*   if UIApplication.shared.applicationState == .background {
            let content = UNMutableNotificationContent()
            content.title = "ESP Blinky"
            content.body = value ? "Now blinking" : "Not blinking anymore"
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            UNUserNotificationCenter.current().add(request) { (error) in
                if let error = error {
                    print("DeviceVC: failed to deliver notification \(error)")
                }
            }
        }*/
    }
    
    func deviceTouchChanged(value: Int) {
        //touchLabel.text = String(value)
    }
    
    func deviceConnected() {
        viewState = .connected
    }
    
    func deviceDisconnected() {
        viewState = .disconnected
    }
    
    func deviceReady() {
        viewState = .ready
    }
    
    func deviceB1Changed(value: Int) {
        //greenSwitch.setOn(value, animated: true)
        
      /*  if UIApplication.shared.applicationState == .background {
            let content = UNMutableNotificationContent()
            content.title = "ESP Blinky"
            content.body = value ? "Now blinking" : "Not blinking anymore"
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            UNUserNotificationCenter.current().add(request) { (error) in
                if let error = error {
                    print("DeviceVC: failed to deliver notification \(error)")
                }
            }
        }*/
    }
}
