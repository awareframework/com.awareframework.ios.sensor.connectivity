# AWARE: Connectivity

[![CI Status](https://img.shields.io/travis/awareframework/com.awareframework.ios.sensor.connectivity.svg?style=flat)](https://travis-ci.org/awareframework/com.awareframework.ios.sensor.connectivity)
[![Version](https://img.shields.io/cocoapods/v/com.awareframework.ios.sensor.connectivity.svg?style=flat)](https://cocoapods.org/pods/com.awareframework.ios.sensor.connectivity)
[![License](https://img.shields.io/cocoapods/l/com.awareframework.ios.sensor.connectivity.svg?style=flat)](https://cocoapods.org/pods/com.awareframework.ios.sensor.connectivity)
[![Platform](https://img.shields.io/cocoapods/p/com.awareframework.ios.sensor.connectivity.svg?style=flat)](https://cocoapods.org/pods/com.awareframework.ios.sensor.connectivity)

The Connectivity sensor provides information on the network sensors availability of the device. These include use of Wi-Fi, Bluetooth, GPS, mobile, Push-Notification, Low-Battery mode, Background Refresh status and internet availability. This sensor can be leveraged to detect the availability of wireless sensors and internet on the device at any time. 

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


## Public functions

### ConnectivitySensor

+ `init(config:ConnectivitySensor.Config?)` : Initializes the connectivity sensor with the optional configuration.
+ `start()`: Starts the connectivity sensor with the optional configuration.
+ `stop()`: Stops the service.

### ConnectivitySensor.Config

Class to hold the configuration of the sensor.

#### Fields
+ `sensorObserver: ConnectivityObserver`: Callback for live data updates.
+ `interval: Int` Connectivity check interval in minute (default = `10`)
+ `enabled: Boolean` Sensor is enabled or not. (default = `false`)
+ `debug: Boolean` enable/disable logging to Xcode console. (default = `false`)
+ `label: String` Label for the data. (default = "")
+ `deviceId: String` Id of the device that will be associated with the events and the sensor. (default = "")
+ `dbEncryptionKey` Encryption key for the database. (default = `null`)
+ `dbType: Engine` Which db engine to use for saving data. (default = `Engine.DatabaseType.NONE`)
+ `dbPath: String` Path of the database. (default = "aware_connectivity")
+ `dbHost: String` Host for syncing the database. (default = `null`)

## Broadcasts

### Fired Broadcasts

+ `ConnectivitySensor.ACTION_AWARE_WIFI_ON`: fired when Wi-Fi is activated.
+ `ConnectivitySensor.ACTION_AWARE_WIFI_OFF`: fired when Wi-Fi is deactivated.
+ `ConnectivitySensor.ACTION_AWARE_MOBILE_ON`: fired when mobile network is activated.
+ `ConnectivitySensor.ACTION_AWARE_MOBILE_OFF`: fired when mobile network is deactivated.
+ `ConnectivitySensor.ACTION_AWARE_BLUETOOTH_ON`: fired when Bluetooth is activated.
+ `ConnectivitySensor.ACTION_AWARE_BLUETOOTH_OFF`: fired when Bluetooth is deactivated.
+ `ConnectivitySensor.ACTION_AWARE_GPS_ON`: fired when GPS is activated.
+ `ConnectivitySensor.ACTION_AWARE_GPS_OFF`: fired when GPS is deactivated.
+ `ConnectivitySensor.ACTION_AWARE_INTERNET_AVAILABLE`: fired when the device is connected to the internet. One extra is included to provide the active internet access network:
  + `ConnectivitySensor.EXTRA_ACCESS`: an integer with one of the following constants: 1=Wi-Fi, 4=Mobile
+ `ConnectivitySensor.ACTION_AWARE_INTERNET_UNAVAILABLE`: fired when the device is not connected to the internet.

### Received Broadcasts

+ `ConnectivitySensor.ACTION_AWARE_CONNECTIVITY_START`: received broadcast to start the sensor.
+ `ConnectivitySensor.ACTION_AWARE_CONNECTIVITY_STOP`: received broadcast to stop the sensor.
+ `ConnectivitySensor.ACTION_AWARE_CONNECTIVITY_SYNC`: received broadcast to send sync attempt to the host.
+ `ConnectivitySensor.ACTION_AWARE_CONNECTIVITY_SET_LABEL`: received broadcast to set the data label. Label is expected in the `ConnectivitySensor.EXTRA_LABEL` field of the intent extras.

## Data Representations

### Connectivity Data

Contains the connectivity data.

| Field     | Type   | Description                                                                                         |
| --------- | ------ | --------------------------------------------------------------------------------------------------- |
| type      | Int    | the connectivity type, one of the following: `-1=AIRPLANE, 1=WIFI, 2=BLUETOOTH, 3=GPS, 4=MOBILE, 5=WIMAX, 6=PUSH_NOTIFICATION, 7=LOW_POWER_MODE, 8=BACKGROUND_REFRESH` |
| subtype   | String | the text label of the type, one of the following: `AIRPLANE, WIFI, BLUETOOTH, GPS, MOBILE, WIMAX, PUSH_NOTIFICATION, LOW_POWER_MODE, BACKGROUND_REFRESH`   |
| state     | Int    | the network status `1=ON, 0=OFF`                                                                    |
| deviceId  | String | AWARE device UUID                                                                                   |
| label     | String | Customizable label. Useful for data calibration or traceability                                     |
| timestamp | Long   | unixtime milliseconds since 1970                                                                    |
| timezone  | Int    | Timezone of the device                                                |
| os        | String | Operating system of the device (e.g., ios)                                                        |

NOTE: iOS does not support AIRPLANE(-1) and WIMAX(5).

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

Yuuki Nishiyama, yuuki.nishiyama@oulu.fi

## License

Copyright (c) 2018 AWARE Mobile Context Instrumentation Middleware/Framework (http://www.awareframework.com)

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0 Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
