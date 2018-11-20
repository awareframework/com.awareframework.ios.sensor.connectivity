# Aware Connectivity

[![CI Status](https://img.shields.io/travis/tetujin/com.awareframework.ios.sensor.connectivity.svg?style=flat)](https://travis-ci.org/tetujin/com.awareframework.ios.sensor.connectivity)
[![Version](https://img.shields.io/cocoapods/v/com.awareframework.ios.sensor.connectivity.svg?style=flat)](https://cocoapods.org/pods/com.awareframework.ios.sensor.connectivity)
[![License](https://img.shields.io/cocoapods/l/com.awareframework.ios.sensor.connectivity.svg?style=flat)](https://cocoapods.org/pods/com.awareframework.ios.sensor.connectivity)
[![Platform](https://img.shields.io/cocoapods/p/com.awareframework.ios.sensor.connectivity.svg?style=flat)](https://cocoapods.org/pods/com.awareframework.ios.sensor.connectivity)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements
iOS 10 or later

## Installation

com.awareframework.ios.sensor.connectivity is available through [CocoaPods](https://cocoapods.org).

1. To install it, simply add the following line to your Podfile:
```ruby
pod 'com.awareframework.ios.sensor.connectivity'
```

2. Import com.awareframework.ios.sensor.connectivity library into your source code.
```swift
import com_awareframework_ios_sensor_connectivity
```

3.  Add `UIRequiresPersistentWiFi` to `Info.plist`

## Example usage
```swift
let connectivity = ConnectivitySensor.init(ConnectivitySensor.Config().apply{config in
    config.debug  = true
    config.dbType = .REALM
    config.sensorObserver = Observer()
})
connectivity?.start()
```

```swift
class Observer:ConnectivityObserver {
    func onInternetON() {
        // Your code here
    }

    func onInternetOFF() {
        // Your code here
    }

    func onGPSON() {
        // Your code here
    }

    func onGPSOFF() {
        // Your code here
    }

    func onBluetoothON() {
        // Your code here
    }

    func onBluetoothOFF() {
        // Your code here
    }

    func onBackgroundRefreshON() {
        // Your code here
    }

    func onBackgroundRefreshOFF() {
        // Your code here
    }

    func onLowPowerModeON() {
        // Your code here
    }

    func onLowPowerModeOFF() {
        // Your code here
    }

    func onPushNotificationOn() {
        // Your code here
    }

    func onPushNotificationOff() {
        // Your code here
    }

    func onWiFiON() {
        // Your code here
    }

    func onWiFiOFF() {
        // Your code here
    }
}
```

## Author

Yuuki Nishiyama, tetujin@ht.sfc.keio.ac.jp

## License

Copyright (c) 2018 AWARE Mobile Context Instrumentation Middleware/Framework (http://www.awareframework.com)

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0 Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
