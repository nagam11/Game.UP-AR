//
//  BTUUIDs.swift
//  Game.UP
//
//  Created by Marla Nagasaki on 01.06.19.
//  Copyright © 2019 Marla Na. All rights reserved.
//
import CoreBluetooth

struct BTUUIDs {
    static let service = CBUUID(string: "9a8ca9ef-e43f-4157-9fee-c37a3d7dc12d")
    static let B1_UUID = CBUUID(string: "e94f85c8-7f57-4dbd-b8d3-2b56e107ed60")
    static let B2_UUID = CBUUID(string: "a8985fda-51aa-4f19-a777-71cf52abba1e")
    static let B4_UUID = CBUUID(string: "4fde9fc5-a828-40c6-a728-3fe2a5bc88b9")
    static let B6_UUID = CBUUID(string: "ec666639-a88e-4166-a7ba-dd59a2fabfc1")
    static let touch = CBUUID(string: "beb5483e-36e1-4688-b7f5-ea07361b26a8")
    static let B1_LONG_TOUCH_UUID = CBUUID(string: "34990849-3601-45cf-b7cd-cb7f2d36335f")
    static let B2_LONG_TOUCH_UUID = CBUUID(string: "45ae2e7b-0d43-4392-a479-233f67f1fad1")
    static let B3_LONG_TOUCH_UUID = CBUUID(string: "ab31a51e-7cbc-4de3-8e67-d48bd8ad6f7a")
    static let B4_LONG_TOUCH_UUID = CBUUID(string: "455bf338-29c2-4a9f-a6ff-5fa0dfd04af9")
    static let B5_LONG_TOUCH_UUID = CBUUID(string: "403828e6-6b6e-4273-9c92-3c4c13cffe0c")
    static let B6_LONG_TOUCH_UUID = CBUUID(string: "ebd771ed-068d-46ea-bf28-80c8f2db9191")
    static let infoService = CBUUID(string: "180a")
    static let infoManufacturer = CBUUID(string: "2a29")
    static let infoName = CBUUID(string: "2a24")
    static let infoSerial = CBUUID(string: "2a25")
}
