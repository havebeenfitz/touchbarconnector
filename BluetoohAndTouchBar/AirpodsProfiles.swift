//
//  AirpodsProfiles.swift
//  BluetoohAndTouchBar
//
//  Created by Max Kraev on 07/06/2018.
//  Copyright © 2018 Max Kraev. All rights reserved.
//

import Foundation
import CoreBluetooth

struct AirpodsProfiles {
    
    let handsFreeProfile = CBUUID(string: "0x111E")
    
    let avrcpTargetProfile = CBUUID(string: "0x110C")
    let avrcpRemoteControlProfile = CBUUID(string: "0x110E")
    let avrcpRemoteControlControllerProfile = CBUUID(string: "0x110F")
    
    let audioSinkProfile = CBUUID(string: "0x110B")
    
    let aapServerProfile: CBUUID? = nil
    let wirlessIAPProfile: CBUUID? = nil
}
