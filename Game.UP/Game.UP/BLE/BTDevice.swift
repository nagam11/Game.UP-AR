//
//  BTDevice.swift
//  BLEDemo
//
//  Created by Jindrich Dolezy on 11/04/2018.
//  Copyright © 2018 Dzindra. All rights reserved.
//

import Foundation
import CoreBluetooth


protocol BTDeviceDelegate: class {
    func deviceConnected()
    func deviceReady()
    func deviceB1Changed(value: Bool)
    func deviceB2Changed(value: Bool)
    func deviceB4Changed(value: Int)
    func deviceB6Changed(value: Bool)
    func deviceTouchChanged(value: Int)
    func deviceLongTouchB4Changed(value: Int)
    func deviceLongTouchB5Changed(value: Int)
    func deviceSerialChanged(value: String)
    func deviceDisconnected()
}

class BTDevice: NSObject {
    private let peripheral: CBPeripheral
    private let manager: CBCentralManager
    private var b1Char: CBCharacteristic?
    private var b2Char: CBCharacteristic?
    private var b4Char: CBCharacteristic?
    private var b6Char: CBCharacteristic?
    private var touchChar: CBCharacteristic?
    private var long_touch_b4_Char: CBCharacteristic?
    private var long_touch_b5_Char: CBCharacteristic?
    private var _b1_led: Bool = false
    private var _b2_led: Bool = false
    private var _b4_led: Int = 0
    private var _b6_led: Bool = false
    private var _touch: Int = 2
    private var _long_touch_b4: Int = 0
    private var _long_touch_b5: Int = 0
    
    weak var delegate: BTDeviceDelegate?
    var touch: Int {
        get {
            return _touch
        }
        set {
            guard _touch != newValue else { return }
            
            _touch = newValue
            if let char = touchChar {
                peripheral.writeValue(Data(bytes: [UInt8(_touch)]), for: char, type: .withResponse)
            }
        }
    }
    
    var long_touch_b4: Int {
        get {
            return _long_touch_b4
        }
        set {
            guard _long_touch_b4 != newValue else { return }
            
            _long_touch_b4 = newValue
            if let char = long_touch_b4_Char {
                peripheral.writeValue(Data(bytes: [UInt8(_long_touch_b4)]), for: char, type: .withResponse)
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
                peripheral.writeValue(Data(bytes: [UInt8(_long_touch_b5)]), for: char, type: .withResponse)
            }
        }
    }
    
    var b1_led: Bool {
        get {
            return _b1_led
        }
        set {
            guard _b1_led != newValue else { return }
            
            _b1_led = newValue
            if let char = b1Char {
                peripheral.writeValue(Data(bytes: [_b1_led ? 1 : 0]), for: char, type: .withResponse)
                
            }
        }
    }
    var b2_led: Bool {
        get {
            return _b2_led
        }
        set {
            guard _b2_led != newValue else { return }
            
            _b2_led = newValue
            if let char = b2Char {
                peripheral.writeValue(Data(bytes: [_b2_led ? 1 : 0]), for: char, type: .withResponse)
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
                peripheral.writeValue(Data(bytes: [UInt8(_b4_led)]), for: char, type: .withResponse)
            }
        }
    }
    
    var b6_led: Bool {
        get {
            return _b6_led
        }
        set {
            guard _b6_led != newValue else { return }
            
            _b6_led = newValue
            if let char = b6Char {
                peripheral.writeValue(Data(bytes: [_b6_led ? 1 : 0]), for: char, type: .withResponse)
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
        delegate?.deviceConnected()
    }
    
    func disconnectedCallback() {
        delegate?.deviceDisconnected()
    }
    
    func errorCallback(error: Error?) {
        print("Device: error \(String(describing: error))")
    }
}

extension BTDevice: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        //print("Device: discovered services")
        peripheral.services?.forEach {
            //print("  \($0)")
            if $0.uuid == BTUUIDs.infoService {
                peripheral.discoverCharacteristics([BTUUIDs.infoSerial], for: $0)
            } else if $0.uuid == BTUUIDs.service {
                peripheral.discoverCharacteristics([BTUUIDs.B1_UUID,BTUUIDs.B2_UUID, BTUUIDs.B4_UUID, BTUUIDs.B6_UUID, BTUUIDs.touch, BTUUIDs.B4_LONG_TOUCH_UUID, BTUUIDs.B5_LONG_TOUCH_UUID  ], for: $0)
            } else {
                peripheral.discoverCharacteristics(nil, for: $0)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        //print("Device: discovered characteristics")
        service.characteristics?.forEach {
            //print("   \($0)")
            
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
            } else if $0.uuid == BTUUIDs.infoSerial {
                peripheral.readValue(for: $0)
            } else if $0.uuid == BTUUIDs.touch {
                self.touchChar = $0
                peripheral.readValue(for: $0)
                peripheral.setNotifyValue(true, for: $0)
            }else if $0.uuid == BTUUIDs.B5_LONG_TOUCH_UUID   {
                self.long_touch_b5_Char = $0
                peripheral.readValue(for: $0)
                peripheral.setNotifyValue(true, for: $0)
            } else if $0.uuid == BTUUIDs.B4_LONG_TOUCH_UUID {
                self.long_touch_b4_Char = $0
                peripheral.readValue(for: $0)
                peripheral.setNotifyValue(true, for: $0)
            }
        }
        delegate?.deviceReady()
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        print("Device: updated value for \(characteristic)")
        
        if characteristic.uuid == touchChar?.uuid, let t = characteristic.value?.parseInt() {
            _touch = Int(t)
            delegate?.deviceTouchChanged(value: touch)
        }
        
        if characteristic.uuid == long_touch_b4_Char?.uuid, let q = characteristic.value?.parseInt() {
            _long_touch_b4 = Int(q)
            delegate?.deviceLongTouchB4Changed(value: long_touch_b4)
        }
        
        if characteristic.uuid == long_touch_b5_Char?.uuid, let w = characteristic.value?.parseInt() {
            _long_touch_b5 = Int(w)
            delegate?.deviceLongTouchB5Changed(value: long_touch_b5)
        }
        
        if characteristic.uuid == b1Char?.uuid, let g = characteristic.value?.parseBool() {
            _b1_led = g
            delegate?.deviceB1Changed(value: _b1_led)
        }
        if characteristic.uuid == b2Char?.uuid, let y = characteristic.value?.parseBool() {
            _b2_led = y
            delegate?.deviceB2Changed(value: _b2_led)
        }
        if characteristic.uuid == b4Char?.uuid, let u = characteristic.value?.parseInt() {
            _b4_led = Int(u)
            delegate?.deviceB4Changed(value: _b4_led)
        }
        if characteristic.uuid == b6Char?.uuid, let z = characteristic.value?.parseBool() {
            _b6_led = z
            delegate?.deviceB6Changed(value: _b6_led)
        }
        
        if characteristic.uuid == BTUUIDs.infoSerial, let d = characteristic.value {
            serial = String(data: d, encoding: .utf8)
            if let serial = serial {
                delegate?.deviceSerialChanged(value: serial)
            }
        }
    }
}


