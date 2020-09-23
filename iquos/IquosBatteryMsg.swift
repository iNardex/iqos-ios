//
//  IquosBatteryMsg.swift
//  iquos
//
//  Created by William Nardo on 21/09/2020.
//

import Foundation

class IquosBatteryMsg {
    
    let batteryPercentage: UInt8
    let holderStatus: HolderStatus
    
    init(data: Data){
        batteryPercentage = data[2]
        if data.count != 7 {
            holderStatus = .outOfTheBox
        } else {
            holderStatus = data[6] == 100 ? .charged : .inRecharge
        }
    }
    
}

enum HolderStatus {
    case charged
    case outOfTheBox
    case inRecharge
}
