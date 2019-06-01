//
//  BTUUIDs.swift
//  Game.UP
//
//  Created by Marla Nagasaki on 01.06.19.
//  Copyright © 2019 Marla Na. All rights reserved.
//
import CoreBluetooth

struct BTUUIDs {
    // touch 0: green , 1: yellow
    static let touch = CBUUID(string: "beb5483e-36e1-4688-b7f5-ea07361b26a8")
    static let greenLED = CBUUID(string: "e94f85c8-7f57-4dbd-b8d3-2b56e107ed60")
    static let yellowLED = CBUUID(string: "a8985fda-51aa-4f19-a777-71cf52abba1e")
    static let service = CBUUID(string: "9a8ca9ef-e43f-4157-9fee-c37a3d7dc12d")
    static let infoService = CBUUID(string: "180a")
    static let infoManufacturer = CBUUID(string: "2a29")
    static let infoName = CBUUID(string: "2a24")
    static let infoSerial = CBUUID(string: "2a25")
}
