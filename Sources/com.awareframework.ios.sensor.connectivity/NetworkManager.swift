//
//  NetworkManager.swift
//
//  Created by Yuuki Nishiyama on 2018/11/06.
//  Copyright © 2018 Yuuki Nishiyama. All rights reserved.
//
//  NetworkManager.swift is inspired by the following codes which are under the MIT License.
//  https://github.com/joncardasis/To-The-Apples-Core (MIT)
//  https://github.com/kmussel/ifaddrs/blob/master/Sources/ifaddrs/Interface.swift (MIT)

import Foundation

public class NetworkManager {
    private struct BroadcomWifiInterfaces{
        static let standardWifi         = "en0"      //Standard Wifi Interface
        static let tethering            = "ap1"      //Access point interface used for Wifi tethering
        static let tetheringConnected   = "bridge"   //Interface for communicating to connected device via tether (Seems like the interface is always bridge100)
        static let awdl                 = "awdl0"    //Apple Wireless Direct Link interface - used for AirDrop, GameKit, AirPlay, etc.
        
        //pdp_ip (1-4) could be a PDS (Phone Data Service) data packet, the data portion of GSM. Since there are four I could assume one for each iphone antenna?
        //ipsec is for Internet Protocol Security
        //lo0 - software loopback network interface
    }
    
    /* Returns true if the device has Wifi turned on */
    public static func wifiEnabled() -> Bool {
        let interfaces = activeNetworkInterfaces();
        for interface in interfaces{
            if interface == BroadcomWifiInterfaces.awdl {
                return true
            }
        }
        return false
    }
    
    /* Returns true if the device is connected to a Wifi network */
    public static func wifiConnected() -> Bool {
        let interfaces = activeNetworkInterfaces();
        for interface in interfaces{
            if interface == BroadcomWifiInterfaces.standardWifi {
                return true
            }
        }
        return false
    }
    
    //    MARK: Harder to implement since the interface turns off sometimes if you exit settings and theres not yet a connection
    //    static func tetheringEnabled() -> Bool {
    //        if activeNetworkInterfaces().filter({ $0 == BroadcomWifiInterfaces.tethering }).count > 1 {
    //            //If more than 1 ap1 interface, then tethering is truned on
    //            return true
    //        }
    //        return false
    //    }
    
    /* Returns true if the device is tethering its connection to another device */
    public static func isTethering() -> Bool {
        let interfaces = activeNetworkInterfaces();
        for interface in interfaces{
            if interface == BroadcomWifiInterfaces.tetheringConnected {
                return true
            }
        }
        return false
    }
    
    private static func activeNetworkInterfaces() -> [String]{
        var interfaces : [String] = []
        var ifaddrsPtr : UnsafeMutablePointer<ifaddrs>? = nil
        if getifaddrs(&ifaddrsPtr) == 0 {
            var ifaddrPtr = ifaddrsPtr
            while ifaddrPtr != nil {
                let addr = ifaddrPtr?.pointee.ifa_addr.pointee
                if addr?.sa_family == UInt8(AF_INET) || addr?.sa_family == UInt8(AF_INET6) {
                    let data = (ifaddrPtr?.pointee)!
                    interfaces.append(String(cString: data.ifa_name))
                }
                ifaddrPtr = ifaddrPtr?.pointee.ifa_next
            }
            freeifaddrs(ifaddrsPtr)
        }
        // print(interfaces)
        return interfaces
    }
}
