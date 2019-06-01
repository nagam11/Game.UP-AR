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
    func deviceBlinkChanged(value: Bool)
    func deviceSpeedChanged(value: Bool)
    func deviceValueChanged(value: Int)
    func deviceSerialChanged(value: String)
    func deviceDisconnected()
    
}

class BTDevice: NSObject {
    private let peripheral: CBPeripheral
    private let manager: CBCentralManager
    private var greenChar: CBCharacteristic?
    private var yellowChar: CBCharacteristic?
    private var touchChar: CBCharacteristic?
    private var _greenLED: Bool = false
    private var _yellowLED: Bool = false
    private var _touch: Int = 2
    
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
    
    var green: Bool {
        get {
            return _greenLED
        }
        set {
            guard _greenLED != newValue else { return }
            
            _greenLED = newValue
            if let char = greenChar {
                peripheral.writeValue(Data(bytes: [_greenLED ? 1 : 0]), for: char, type: .withResponse)
                
            }
        }
    }
    var yellow: Bool {
        get {
            return _yellowLED
        }
        set {
            guard _yellowLED != newValue else { return }
            
            _yellowLED = newValue
            if let char = yellowChar {
                peripheral.writeValue(Data(bytes: [_yellowLED ? 1 : 0]), for: char, type: .withResponse)
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
                peripheral.discoverCharacteristics([BTUUIDs.greenLED,BTUUIDs.yellowLED, BTUUIDs.touch], for: $0)
            } else {
                peripheral.discoverCharacteristics(nil, for: $0)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        //print("Device: discovered characteristics")
        service.characteristics?.forEach {
            //print("   \($0)")
            
            if $0.uuid == BTUUIDs.greenLED {
                self.greenChar = $0
                peripheral.readValue(for: $0)
                peripheral.setNotifyValue(true, for: $0)
            } else if $0.uuid == BTUUIDs.yellowLED {
                self.yellowChar = $0
                peripheral.readValue(for: $0)
            } else if $0.uuid == BTUUIDs.infoSerial {
                peripheral.readValue(for: $0)
            } else if $0.uuid == BTUUIDs.touch {
                self.touchChar = $0
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
            delegate?.deviceValueChanged(value: touch)
        }
        
        if characteristic.uuid == greenChar?.uuid, let g = characteristic.value?.parseBool() {
            _greenLED = g
            delegate?.deviceBlinkChanged(value: _greenLED)
        }
        if characteristic.uuid == yellowChar?.uuid, let y = characteristic.value?.parseBool() {
            _yellowLED = y
            delegate?.deviceSpeedChanged(value: _yellowLED)
        }
        
        if characteristic.uuid == BTUUIDs.infoSerial, let d = characteristic.value {
            serial = String(data: d, encoding: .utf8)
            if let serial = serial {
                delegate?.deviceSerialChanged(value: serial)
            }
        }
    }
}


