//
//  ConnectivityData.swift
//  com.aware.ios.sensor.connectivity
//
//  Created by Yuuki Nishiyama on 2018/11/06.
//

import UIKit
import com_awareframework_ios_sensor_core

public class ConnectivityData: AwareObject {
    
    public static let TABLE_NAME = "connectivityData"
    
    @objc dynamic public var type: Int = -1
    @objc dynamic public var subtype: String = ""
    @objc dynamic public var state: Int = 0
    
    public override func toDictionary() -> Dictionary<String, Any> {
        var dict = super.toDictionary()
        dict["type"] = type
        dict["subtype"] = subtype
        dict["state"] = state
        return dict
    }
}
