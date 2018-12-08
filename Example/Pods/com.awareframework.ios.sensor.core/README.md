# AWARE: Core 

[![CI Status](https://img.shields.io/travis/awareframework/com.awareframework.ios.sensor.core.svg?style=flat)](https://travis-ci.org/awareframework/com.awareframework.ios.sensor.core)
[![Version](https://img.shields.io/cocoapods/v/com.awareframework.ios.sensor.core.svg?style=flat)](https://cocoapods.org/pods/com.awareframework.ios.sensor.core)
[![License](https://img.shields.io/cocoapods/l/com.awareframework.ios.sensor.core.svg?style=flat)](https://cocoapods.org/pods/com.awareframework.ios.sensor.core)
[![Platform](https://img.shields.io/cocoapods/p/com.awareframework.ios.sensor.core.svg?style=flat)](https://cocoapods.org/pods/com.awareframework.ios.sensor.core)

## Overview
com.awareframework.ios.sensor.core provides a basic class for developing your own sensor module on aware framework.

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements
iOS 10 or later.

## Installation

com.aware.ios.sensor.core is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'com.awareframework.ios.sensor.core'
```

### Extending to a new AWARE module
1. Make a subclass of AwareSensor as a sensor module
2. Extende SensorConfig for adding originl parameters 
3. Store data using the provided database engine
4. Sync local-database with remote-database

## Author
Yuuki Nishiyama, yuuki.nishiyama@oulu.fi

## License
Copyright (c) 2014 AWARE Mobile Context Instrumentation Middleware/Framework (http://www.awareframework.com)

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
