//
//  ConnectivitySensor.swift
//  com.aware.ios.sensor.connectivity
//
//  Created by Yuuki Nishiyama on 2018/11/06.
//

import UIKit
import com_awareframework_ios_sensor_core
import SwiftyJSON
import Reachability
import CoreLocation
import UserNotifications
import CoreBluetooth

public protocol ConnectivityObserver {
    func onInternetON()
    func onInternetOFF()
    
    func onGPSON()
    func onGPSOFF()
    
    func onBluetoothON()
    func onBluetoothOFF()
    
    func onBackgroundRefreshON()
    func onBackgroundRefreshOFF()
    
    func onLowPowerModeON()
    func onLowPowerModeOFF()
    
    func onPushNotificationOn()
    func onPushNotificationOff()
    
    // func onWimaxON()
    // func onWimaxOFF()
    
    // func onNetworkDataON()
    // func onNetworkDataOFF()
    
    func onWiFiON()
    func onWiFiOFF()
    
    // func onAirplaneON()
    // func onAirplaneOFF()
    
    // func onNetworkTraffic(data: TrafficData)
    // func onWiFiTraffic(data: TrafficData)
    // func onIdleTraffic()
}

public class ConnectivitySensor: AwareSensor, CLLocationManagerDelegate {

    public var CONFIG = Config()
    
    // location
    var locationManager = CLLocationManager()
    
    // bluetooth
    let bluetoothManager = CBCentralManager()
    var LAST_BLUETOOTH_STATE:CBManagerState = .unknown
    
    // network
    let reachability = Reachability()!
    
    // notification
    var LAST_NOTIFICATION_STATE:UNAuthorizationStatus = .notDetermined
    
    var timer:Timer? = nil
    
    public class Config:SensorConfig{
        
        public var sensorObserver:ConnectivityObserver?
        
        public var interval:Int = 10 // min
        {
            didSet{
                if self.interval <= 0 {
                    print("[Connectivity][Illegal Parameter]",
                          "The 'interval' parameter has to be more than 0.",
                          "This parameter ('\(self.interval)') is ignored.")
                    self.interval = oldValue
                }
            }
        }
        
        public override init(){
            super.init()
            dbPath = "aware_connectivity"
        }
        
        public convenience init(_ config:Dictionary<String,Any>){
            self.init()
            if let interval = config["interval"] as? Int {
                self.interval = interval
            }
        }
        
        public func apply(closure:(_ config: ConnectivitySensor.Config) -> Void) -> Self {
            closure(self)
            return self
        }
    }
    
    public override convenience init(){
        self.init(ConnectivitySensor.Config())
    }
    
    public init(_ config:ConnectivitySensor.Config){
        super.init()
        CONFIG = config
        initializeDbEngine(config: config)
        
        /// reachability ///
        reachability.whenReachable = { reachability in
            if reachability.connection == .wifi {
                if self.CONFIG.debug { print(ConnectivitySensor.TAG, "Reachable via WiFi") }
                if let observer = self.CONFIG.sensorObserver{
                    observer.onInternetON()
                }
                self.saveConnectivityEvent(.wifi, .wifi, .on )
                self.notificationCenter.post(name: .actionAwareInternetAvailable , object: [ConnectivitySensor.EXTRA_ACCESS: ConnectivityEventType.wifi.rawValue])
            } else {
                if self.CONFIG.debug { print(ConnectivitySensor.TAG, "Reachable via Cellular") }
                if let observer = self.CONFIG.sensorObserver{
                    observer.onInternetON()
                }
                self.saveConnectivityEvent(.mobile, .mobile, .on )
                self.notificationCenter.post(name: .actionAwareInternetAvailable , object: [ConnectivitySensor.EXTRA_ACCESS: ConnectivityEventType.mobile.rawValue])
            }
        }
        reachability.whenUnreachable = { _ in
            if self.CONFIG.debug { print(ConnectivitySensor.TAG, "Not reachable") }
            if let observer = self.CONFIG.sensorObserver{
                observer.onInternetOFF()
            }
            self.saveConnectivityEvent(.mobile, .mobile, .off )
            self.saveConnectivityEvent(.wifi, .wifi, .off )
            self.notificationCenter.post(name: .actionAwareInternetUnavailable , object: nil)
        }
        
        // low battery mode
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(changedLowBatteryMode(_:)),
                                               name: Notification.Name.NSProcessInfoPowerStateDidChange,
                                               object: nil)
        
        // background refresh
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(changedBackgroundRefreshState(_:)),
                                               name: UIApplication.backgroundRefreshStatusDidChangeNotification,
                                               object: nil)
        

        
    }
    
    deinit {
         NotificationCenter.default.removeObserver(self,
                                                   name: Notification.Name.NSProcessInfoPowerStateDidChange,
                                                   object: nil)
        NotificationCenter.default.removeObserver(self,
                                                  name: UIApplication.backgroundRefreshStatusDidChangeNotification,
                                                  object: nil)
        
    }
    
    var LAST_WIFI_STATUS:Bool = !NetworkManager.wifiEnabled()
    
    public override func start() {
        
        // Network
        do {
            try reachability.startNotifier()
        } catch {
            if self.CONFIG.debug{ print("Unable to start notifier") }
        }
        
        locationManager.delegate = self
        
        // WiFi Module
        if timer == nil {
            timer = Timer.scheduledTimer(withTimeInterval: Double(self.CONFIG.interval), repeats: true, block: { t in
                self.checkConnectivity(force: false)
            })
        }else{
            self.checkConnectivity(force: true)
            self.changedLowBatteryMode(Notification.init(name: Notification.Name.NSProcessInfoPowerStateDidChange))
            self.changedBackgroundRefreshState(Notification.init(name: UIApplication.backgroundRefreshStatusDidChangeNotification))
        }
        
        self.notificationCenter.post(name: .actionAwareConnectivityStart , object: self)
    }
    
    public override func stop() {
        reachability.stopNotifier()
        locationManager.delegate = nil
        if let uwTimer = self.timer {
            uwTimer.invalidate()
            self.timer = nil
        }
        self.notificationCenter.post(name: .actionAwareConnectivityStop , object: self)
    }
    
    public override func sync(force: Bool = false) {
        if let engine = self.dbEngine{
            engine.startSync(ConnectivityData.TABLE_NAME, ConnectivityData.self, DbSyncConfig().apply{config in
                config.debug = self.CONFIG.debug
                config.dispatchQueue = DispatchQueue(label: "com.awareframework.ios.sensor.connectivity.sync.queue")
                config.completionHandler = { (status, error) in
                    var userInfo: Dictionary<String,Any> = [ConnectivitySensor.EXTRA_STATUS: status]
                    if let e = error {
                        userInfo[ConnectivitySensor.EXTRA_ERROR] = e
                    }
                    self.notificationCenter.post(name: .actionAwareConnectivitySyncCompletion ,
                                                 object: self,
                                                 userInfo:userInfo)
                }
            })
            self.notificationCenter.post(name: .actionAwareConnectivitySync , object: self)
        }
    }
    
    public override func set(label:String){
        self.CONFIG.label = label
        self.notificationCenter.post(name: .actionAwareConnectivitySetLabel,
                                     object: self,
                                     userInfo: [ConnectivitySensor.EXTRA_LABEL:label])
    }
    
    public func checkConnectivity(force:Bool = false){
        // WiFi
        if (self.LAST_WIFI_STATUS != NetworkManager.wifiEnabled()) || force == true {
            if NetworkManager.wifiEnabled(){
                if self.CONFIG.debug { print(ConnectivitySensor.TAG, "WiFi On") }
                if let observer = self.CONFIG.sensorObserver {
                    observer.onWiFiON()
                }
                self.saveConnectivityEvent(.wifi, .wifi, .on)
                self.notificationCenter.post(name: .actionAwareWifiOn , object: self)
            }else{
                if self.CONFIG.debug { print(ConnectivitySensor.TAG, "WiFi Off") }
                if let observer = self.CONFIG.sensorObserver {
                    observer.onWiFiOFF()
                }
                self.saveConnectivityEvent(.wifi, .wifi, .off)
                self.notificationCenter.post(name: .actionAwareWifiOff , object: self)
            }
            self.LAST_WIFI_STATUS = NetworkManager.wifiEnabled()
        }
        
        // Notification
        UNUserNotificationCenter.current().getNotificationSettings( completionHandler: { settings in
            if (self.LAST_NOTIFICATION_STATE != settings.authorizationStatus) || force == true {
                switch settings.authorizationStatus {
                case .authorized:
                    if self.CONFIG.debug { print(ConnectivitySensor.TAG, "Push Notification On") }
                    if let observer = self.CONFIG.sensorObserver{
                        observer.onPushNotificationOn()
                    }
                    self.saveConnectivityEvent(.pushNotification, .pushNotification, .on)
                    self.notificationCenter.post(name: .actionAwarePushNotificationOn , object: self)
                    break
                case .denied, .notDetermined, .provisional: // iOS 12
                    if self.CONFIG.debug { print(ConnectivitySensor.TAG, "Push Notification Off") }
                    if let observer = self.CONFIG.sensorObserver{
                        observer.onPushNotificationOff()
                    }
                    self.saveConnectivityEvent(.pushNotification, .pushNotification, .off)
                    self.notificationCenter.post(name: .actionAwarePushNotificationOff , object: self)
                    break
                }
                self.LAST_NOTIFICATION_STATE = settings.authorizationStatus
            }
        })
        
        if (self.LAST_BLUETOOTH_STATE != self.bluetoothManager.state) || force == true  {
            switch self.bluetoothManager.state {
            case .poweredOn:
                if self.CONFIG.debug { print(ConnectivitySensor.TAG, "Bluetooth On") }
                if let observer = self.CONFIG.sensorObserver{
                    observer.onBluetoothON()
                }
                self.saveConnectivityEvent(.bluetooth, .bluetooth , .on)
                self.notificationCenter.post(name: .actionAwareBluetoothOn , object: self)
                break
            case .poweredOff, .resetting, .unauthorized, .unknown, .unsupported:
                if self.CONFIG.debug { print(ConnectivitySensor.TAG, "Bluetooth Off") }
                if let observer = self.CONFIG.sensorObserver{
                    observer.onBluetoothOFF()
                }
                self.saveConnectivityEvent(.bluetooth, .bluetooth , .off)
                self.notificationCenter.post(name: .actionAwareBluetoothOff , object: self)
                break
            }
            self.LAST_BLUETOOTH_STATE = self.bluetoothManager.state
        }
    }
    
    
    
    /// handler for low-power mode events.
    /// Low-Power
    @objc func changedLowBatteryMode(_ notification: Notification) {
        let lowPowerModeEnabled = ProcessInfo.processInfo.isLowPowerModeEnabled
        
        if lowPowerModeEnabled {
            if self.CONFIG.debug { print(ConnectivitySensor.TAG, "Low-Power Mode On") }
            if let observer = self.CONFIG.sensorObserver {
                observer.onLowPowerModeON()
            }
            self.saveConnectivityEvent(.lowPowerMode, .lowPowerMode , .on)
            self.notificationCenter.post(name: .actionAwareLowPowerModeOn , object: self)
        } else {
            if self.CONFIG.debug { print(ConnectivitySensor.TAG, "Low-Power Mode Off") }
            if let observer = self.CONFIG.sensorObserver{
                observer.onLowPowerModeOFF()
            }
            self.saveConnectivityEvent(.lowPowerMode, .lowPowerMode , .off)
            self.notificationCenter.post(name: .actionAwareLowPowerModeOff , object: self)
        }
    }
    
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways:
            if self.CONFIG.debug { print(ConnectivitySensor.TAG, "GPS ON") }
            if let observer = self.CONFIG.sensorObserver{
                observer.onGPSON()
            }
            self.saveConnectivityEvent(.gps, .gps, .on)
            self.notificationCenter.post(name: .actionAwareGPSOn , object: self)
            break
        case .authorizedWhenInUse, .denied, .notDetermined, .restricted:
            if self.CONFIG.debug { print(ConnectivitySensor.TAG, "GPS OFF") }
            if let observer = self.CONFIG.sensorObserver{
                observer.onGPSOFF()
            }
            self.saveConnectivityEvent(.gps, .gps, .off)
            self.notificationCenter.post(name: .actionAwareGPSOff , object: self)
            break
        }
    }
    
    /// background refresh handler
    @objc func changedBackgroundRefreshState(_ notification: Notification) {
        let backgroundRefreshStatus = UIApplication.shared.backgroundRefreshStatus
        switch backgroundRefreshStatus {
        case .available:
            if self.CONFIG.debug { print(ConnectivitySensor.TAG, "Background Refresh On") }
            if let observer = self.CONFIG.sensorObserver {
                observer.onBackgroundRefreshON()
            }
            self.saveConnectivityEvent(.backgroundRefresh, .backgroundRefresh, .on)
            self.notificationCenter.post(name: .actionAwareBackgroundRefreshOn , object: self)
            break
        case .denied,.restricted:
            if self.CONFIG.debug { print(ConnectivitySensor.TAG, "Background Refresh Off") }
            if let observer = self.CONFIG.sensorObserver {
                observer.onBackgroundRefreshOFF()
            }
            self.saveConnectivityEvent(.backgroundRefresh, .backgroundRefresh, .off)
            self.notificationCenter.post(name: .actionAwareBackgroundRefreshOff , object: self)
        }
    }
    
    private func saveConnectivityEvent(_ type:ConnectivityEventType, _ subType:ConnectivityEventSubType, _ state:ConnectivityEventState ){
        if let engine = self.dbEngine{
            let data     = ConnectivityData()
            data.type    = type.rawValue
            data.subtype = subType.rawValue
            data.state   = state.rawValue
            data.label   = self.CONFIG.label
            engine.save(data)
            self.notificationCenter.post(name: .actionAwareConnectivity, object: self)
        }
    }
    
}

extension Notification.Name{
    
    public static let actionAwareConnectivity = Notification.Name(ConnectivitySensor.ACTION_AWARE_CONNECTIVITY)
    
    public static let actionAwareConnectivityStart = Notification.Name(ConnectivitySensor.ACTION_AWARE_CONNECTIVITY_START)
    public static let actionAwareConnectivityStop  = Notification.Name(ConnectivitySensor.ACTION_AWARE_CONNECTIVITY_STOP)
    public static let actionAwareConnectivitySetLabel = Notification.Name(ConnectivitySensor.ACTION_AWARE_CONNECTIVITY_SET_LABEL)
    public static let actionAwareConnectivitySync  = Notification.Name(ConnectivitySensor.ACTION_AWARE_CONNECTIVITY_SYNC)
    public static let actionAwareConnectivitySyncCompletion  = Notification.Name(ConnectivitySensor.ACTION_AWARE_CONNECTIVITY_SYNC_COMPLETION)
    
    public static let actionAwareInternetAvailable = Notification.Name(ConnectivitySensor.ACTION_AWARE_INTERNET_AVAILABLE)
    public static let actionAwareInternetUnavailable = Notification.Name(ConnectivitySensor.ACTION_AWARE_INTERNET_UNAVAILABLE)
    
    public static let actionAwareWifiOn = Notification.Name(ConnectivitySensor.ACTION_AWARE_WIFI_ON)
    public static let actionAwareWifiOff = Notification.Name(ConnectivitySensor.ACTION_AWARE_WIFI_OFF)

    public static let actionAwareGPSOn  = Notification.Name(ConnectivitySensor.ACTION_AWARE_GPS_ON)
    public static let actionAwareGPSOff = Notification.Name(ConnectivitySensor.ACTION_AWARE_GPS_OFF)
    
    public static let actionAwareBluetoothOn  = Notification.Name(ConnectivitySensor.ACTION_AWARE_BLUETOOTH_ON)
    public static let actionAwareBluetoothOff = Notification.Name(ConnectivitySensor.ACTION_AWARE_BLUETOOTH_OFF)
    
    public static let actionAwarePushNotificationOn = Notification.Name(ConnectivitySensor.ACTION_AWARE_PUSH_NOTIFICATION_ON)
    public static let actionAwarePushNotificationOff = Notification.Name(ConnectivitySensor.ACTION_AWARE_PUSH_NOTIFICATION_OFF)
    
    public static let actionAwareLowPowerModeOn = Notification.Name(ConnectivitySensor.ACTION_AWARE_LOW_POWER_MODE_ON)
    public static let actionAwareLowPowerModeOff = Notification.Name(ConnectivitySensor.ACTION_AWARE_LOW_POWER_MODE_OFF)
    
    public static let actionAwareBackgroundRefreshOn = Notification.Name(ConnectivitySensor.ACTION_AWARE_BACKGROUND_REFRESH_ON)
    public static let actionAwareBackgroundRefreshOff = Notification.Name(ConnectivitySensor.ACTION_AWARE_BACKGROUND_REFRESH_OFF)
}

public enum ConnectivityEventType:Int {
    case airplane = -1
    case wifi   = 1
    case bluetooth = 2
    case gps    = 3
    case mobile = 4
    case wimax  = 5
    case pushNotification = 6
    case lowPowerMode = 7
    case backgroundRefresh = 8
}

public enum ConnectivityEventSubType:String {
    public typealias RawValue = String
    case airplane = "AIRPLANE"
    case wifi     = "WIFI"
    case bluetooth = "BLUETOOTH"
    case gps    = "GPS"
    case mobile = "MOBILE"
    case wimax  = "WIMAX"
    case pushNotification = "PUSH_NOTIFICATION"
    case lowPowerMode = "LOW_POWER_MODE"
    case backgroundRefresh = "BACKGROUND_REFRESH"
}

public enum ConnectivityEventState:Int {
    case on = 1
    case off = 0
}

extension ConnectivitySensor{
    public static let TAG = "AWARE::Connectivity"
    
    /**
     * Fired event: airplane is active
     */
    public static let ACTION_AWARE_AIRPLANE_ON = "ACTION_AWARE_AIRPLANE_ON"
    
    /**
     * Fired event: airplane is inactive
     */
    public static let ACTION_AWARE_AIRPLANE_OFF = "ACTION_AWARE_AIRPLANE_OFF"
    
    /**
     * Fired event: wifi is active
     */
    public static let ACTION_AWARE_WIFI_ON = "ACTION_AWARE_WIFI_ON"
    
    /**
     * Fired event: wifi is inactive
     */
    public static let ACTION_AWARE_WIFI_OFF = "ACTION_AWARE_WIFI_OFF"
    
    /**
     * Fired event: mobile is active
     */
    public static let ACTION_AWARE_MOBILE_ON = "ACTION_AWARE_MOBILE_ON"
    
    /**
     * Fired event: mobile is inactive
     */
    public static let ACTION_AWARE_MOBILE_OFF = "ACTION_AWARE_MOBILE_OFF"
    
    /**
     * Fired event: wimax is active
     */
    public static let ACTION_AWARE_WIMAX_ON = "ACTION_AWARE_WIMAX_ON"
    
    /**
     * Fired event: wimax is inactive
     */
    public static let ACTION_AWARE_WIMAX_OFF = "ACTION_AWARE_WIMAX_OFF"
    
    /**
     * Fired event: bluetooth is active
     */
    public static let ACTION_AWARE_BLUETOOTH_ON = "ACTION_AWARE_BLUETOOTH_ON"
    
    /**
     * Fired event: bluetooth is inactive
     */
    public static let ACTION_AWARE_BLUETOOTH_OFF = "ACTION_AWARE_BLUETOOTH_OFF"
    
    /**
     * Fired event: GPS is active
     */
    public static let ACTION_AWARE_GPS_ON = "ACTION_AWARE_GPS_ON"
    
    /**
     * Fired event: GPS is inactive
     */
    public static let ACTION_AWARE_GPS_OFF = "ACTION_AWARE_GPS_OFF"
    
    /**
     * Fired event: internet access is available
     */
    public static let ACTION_AWARE_INTERNET_AVAILABLE = "ACTION_AWARE_INTERNET_AVAILABLE"
    
    /**
     * Fired event: internet access is unavailable
     */
    public static let ACTION_AWARE_INTERNET_UNAVAILABLE = "ACTION_AWARE_INTERNET_UNAVAILABLE"
    
    public static let ACTION_AWARE_BACKGROUND_REFRESH_ON  = "ACTION_AWARE_BACKGROUND_REFRESH_ON"
    public static let ACTION_AWARE_BACKGROUND_REFRESH_OFF = "ACTION_AWARE_BACKGROUND_REFRESH_OFF"
    
    public static let ACTION_AWARE_LOW_POWER_MODE_ON  = "ACTION_AWARE_LOW_POWER_MODE_ON"
    public static let ACTION_AWARE_LOW_POWER_MODE_OFF = "ACTION_AWARE_LOW_POWER_MODE_OFF"
    
    public static let ACTION_AWARE_PUSH_NOTIFICATION_ON  = "ACTION_AWARE_PUSH_NOTIFICATION_ON"
    public static let ACTION_AWARE_PUSH_NOTIFICATION_OFF = "ACTION_AWARE_PUSH_NOTIFICATION_OFF"

    /**
     * Extra for ACTION_AWARE_INTERNET_AVAILABLE
     * String "internet_access"
     */
    public static let EXTRA_ACCESS = "internet_access"
    
    /**
     * Fired event: updated traffic information is available
     */
    public static let ACTION_AWARE_CONNECTIVITY = "com.awareframework.ios.sensor.connectivity"
    
    public static let ACTION_AWARE_CONNECTIVITY_START = "com.awareframework.ios.sensor.connectivity.SENSOR_START"
    public static let ACTION_AWARE_CONNECTIVITY_STOP = "com.awareframework.ios.sensor.connectivity.SENSOR_STOP"
    
    public static let ACTION_AWARE_CONNECTIVITY_SET_LABEL = "com.awareframework.ios.sensor.connectivity.SET_LABEL"
    public static let EXTRA_LABEL = "label"
    
    public static let ACTION_AWARE_CONNECTIVITY_SYNC = "com.awareframework.ios.sensor.connectivity.SENSOR_SYNC"
    public static let ACTION_AWARE_CONNECTIVITY_SYNC_COMPLETION = "com.awareframework.ios.sensor.connectivity.SENSOR_SYNC_COMPLETION"
    public static let EXTRA_STATUS = "status"
    public static let EXTRA_ERROR = "error"
    
}
