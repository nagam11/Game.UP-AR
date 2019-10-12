//
//  BTDevice.swift
//  BLEDemo
//
//  Created by Jindrich Dolezy on 11/04/2018.
//  Copyright © 2018 Dzindra. All rights reserved.
//

import Foundation
import CoreBluetooth

/*
 Delegate functions to be implemented in the AR delegate for receiving notifications.
 */
protocol BTDeviceDelegate: class {
    func deviceTouchChanged(value: Int)
    func deviceLongTouchB3Changed(value: Int)
    func deviceLongTouchB5Changed(value: Int)
    func deviceLongTouchB7Changed(value: Int)
}

class BTDevice: NSObject {
    private let peripheral: CBPeripheral
    private let manager: CBCentralManager
    // LED variables
    private var b1Char: CBCharacteristic?
    private var b2Char: CBCharacteristic?
    private var b4Char: CBCharacteristic?
    private var b6Char: CBCharacteristic?
    private var b7Char: CBCharacteristic?
    private var b8Char: CBCharacteristic?
    private var _b1_led: Int = 0
    private var _b2_led: Int = 0
    private var _b4_led: Int = 0
    private var _b6_led: Int = 0
    private var _b7_led: Int = 0
    private var _b8_led: Int = 0
    // Touch variables
    private var touchChar: CBCharacteristic?
    private var long_touch_b3_Char: CBCharacteristic?
    private var long_touch_b5_Char: CBCharacteristic?
    private var long_touch_b7_Char: CBCharacteristic?
    private var _touch: Int = 8
    private var _long_touch_b3: Int = 0
    private var _long_touch_b5: Int = 0
    private var _long_touch_b7: Int = 0
    
    weak var delegate: BTDeviceDelegate?
    
    // BLE Callbacks for touch notifications and LED commands.
    var touch: Int {
        get {
            return _touch
        }
        set {
            guard _touch != newValue else { return }
            
            _touch = newValue
            if let char = touchChar {
                peripheral.writeValue(Data([UInt8(_touch)]), for: char, type: .withResponse)
            }
        }
    }
    
    var long_touch_b3: Int {
        get {
            return _long_touch_b3
        }
        set {
            guard _long_touch_b3 != newValue else { return }
            
            _long_touch_b3 = newValue
            if let char = long_touch_b3_Char {
                peripheral.writeValue(Data([UInt8(_long_touch_b3)]), for: char, type: .withResponse)
            }
        }
    }
    
    var long_touch_b5: Int {
        get {
            return _long_touch_b5
        }
        set {
            guard _long_touch_b5 != newValue else { return }
            
            _long_touch_b5 = newValue
            if let char = long_touch_b5_Char {
                peripheral.writeValue(Data([UInt8(_long_touch_b5)]), for: char, type: .withResponse)
            }
        }
    }
    
    var long_touch_b7: Int {
        get {
            return _long_touch_b7
        }
        set {
            guard _long_touch_b7 != newValue else { return }
            
            _long_touch_b7 = newValue
            if let char = long_touch_b7_Char {
                peripheral.writeValue(Data([UInt8(_long_touch_b7)]), for: char, type: .withResponse)
            }
        }
    }
    
    // Color of building as Int
    var b1_led: Int {
        get {
            return _b1_led
        }
        set {
            guard _b1_led != newValue else { return }
            
            _b1_led = newValue
            if let char = b1Char {
                peripheral.writeValue(Data([UInt8(_b1_led)]), for: char, type: .withResponse)
                
            }
        }
    }
    var b2_led: Int {
        get {
            return _b2_led
        }
        set {
            guard _b2_led != newValue else { return }
            
            _b2_led = newValue
            if let char = b2Char {
                peripheral.writeValue(Data([UInt8(_b2_led)]), for: char, type: .withResponse)
            }
        }
    }
    var b4_led: Int {
        get {
            return _b4_led
        }
        set {
            guard _b4_led != newValue else { return }
            
            _b4_led = newValue
            if let char = b4Char {
                peripheral.writeValue(Data([UInt8(_b4_led)]), for: char, type: .withResponse)
            }
        }
    }
    
    var b6_led: Int {
        get {
            return _b6_led
        }
        set {
            guard _b6_led != newValue else { return }
            
            _b6_led = newValue
            if let char = b6Char {
                peripheral.writeValue(Data([UInt8(_b6_led)]), for: char, type: .withResponse)
            }
        }
    }
    
    var b7_led: Int {
           get {
               return _b7_led
           }
           set {
               guard _b7_led != newValue else { return }
               
               _b7_led = newValue
               if let char = b7Char {
                   peripheral.writeValue(Data([UInt8(_b7_led)]), for: char, type: .withResponse)
               }
           }
       }
    
    var b8_led: Int {
           get {
               return _b8_led
           }
           set {
               guard _b8_led != newValue else { return }
               
               _b8_led = newValue
               if let char = b8Char {
                   peripheral.writeValue(Data([UInt8(_b8_led)]), for: char, type: .withResponse)
               }
           }
       }
    
    var name: String {
        return peripheral.name ?? "Unknown device"
    }
    var detail: String {
        return peripheral.identifier.description
    }
    private(set) var serial: String?
    
    init(peripheral: CBPeripheral, manager: CBCentralManager) {
        self.peripheral = peripheral
        self.manager = manager
        super.init()
        self.peripheral.delegate = self
    }
    
    func connect() {
        manager.connect(peripheral, options: nil)
    }
    
    func disconnect() {
        manager.cancelPeripheralConnection(peripheral)
    }
}

extension BTDevice {
    // these are called from BTManager, do not call directly
    
    func connectedCallback() {
        peripheral.discoverServices([BTUUIDs.service, BTUUIDs.infoService])
    }
    
    func disconnectedCallback() {
    }
    
    func errorCallback(error: Error?) {
        print("Device: error \(String(describing: error))")
    }
}

extension BTDevice: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        peripheral.services?.forEach {            
            if $0.uuid == BTUUIDs.infoService {
                peripheral.discoverCharacteristics([BTUUIDs.infoSerial], for: $0)
            } else if $0.uuid == BTUUIDs.service {
                peripheral.discoverCharacteristics([BTUUIDs.B1_UUID,BTUUIDs.B2_UUID, BTUUIDs.B4_UUID, BTUUIDs.B6_UUID,BTUUIDs.B7_UUID, BTUUIDs.B8_UUID, BTUUIDs.touch,  BTUUIDs.B3_LONG_TOUCH_UUID, BTUUIDs.B5_LONG_TOUCH_UUID, BTUUIDs.B7_LONG_TOUCH_UUID  ], for: $0)
            } else {
                peripheral.discoverCharacteristics(nil, for: $0)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        service.characteristics?.forEach {
            print($0.uuid)
            if $0.uuid == BTUUIDs.B1_UUID {
                self.b1Char = $0
                peripheral.readValue(for: $0)
            } else if $0.uuid == BTUUIDs.B2_UUID {
                self.b2Char = $0
                peripheral.readValue(for: $0)
            } else if $0.uuid == BTUUIDs.B4_UUID {
                self.b4Char = $0
                peripheral.readValue(for: $0)
            } else if $0.uuid == BTUUIDs.B6_UUID {
                self.b6Char = $0
                peripheral.readValue(for: $0)
            } else if $0.uuid == BTUUIDs.B7_UUID {
                self.b7Char = $0
                peripheral.readValue(for: $0)
            } else if $0.uuid == BTUUIDs.B8_UUID {
                self.b8Char = $0
                peripheral.readValue(for: $0)
            } else if $0.uuid == BTUUIDs.infoSerial {
                peripheral.readValue(for: $0)
            } else if $0.uuid == BTUUIDs.touch {
                self.touchChar = $0
                peripheral.readValue(for: $0)
                peripheral.setNotifyValue(true, for: $0)
            } else if $0.uuid == BTUUIDs.B3_LONG_TOUCH_UUID   {
                self.long_touch_b3_Char = $0
                peripheral.readValue(for: $0)
                peripheral.setNotifyValue(true, for: $0)
            } else if $0.uuid == BTUUIDs.B5_LONG_TOUCH_UUID   {
                self.long_touch_b5_Char = $0
                peripheral.readValue(for: $0)
                peripheral.setNotifyValue(true, for: $0)
            } else if $0.uuid == BTUUIDs.B7_LONG_TOUCH_UUID   {
                self.long_touch_b7_Char = $0
                peripheral.readValue(for: $0)
                peripheral.setNotifyValue(true, for: $0)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        print("Device: updated value for \(characteristic)")
        
        if characteristic.uuid == touchChar?.uuid, let t = characteristic.value?.parseInt() {
            _touch = Int(t)
            delegate?.deviceTouchChanged(value: touch)
        }

        if characteristic.uuid == long_touch_b3_Char?.uuid, let c = characteristic.value?.parseInt() {
            _long_touch_b3 = Int(c)
            delegate?.deviceLongTouchB3Changed(value: long_touch_b3)
        }
        
        if characteristic.uuid == long_touch_b5_Char?.uuid, let w = characteristic.value?.parseInt() {
            _long_touch_b5 = Int(w)
            delegate?.deviceLongTouchB5Changed(value: long_touch_b5)
        }
        
        if characteristic.uuid == long_touch_b7_Char?.uuid, let d = characteristic.value?.parseInt() {
            _long_touch_b7 = Int(d)
            delegate?.deviceLongTouchB7Changed(value: long_touch_b7)
        }
    }
}
