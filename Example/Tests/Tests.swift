import XCTest
import RealmSwift
import com_awareframework_ios_sensor_connectivity
import com_awareframework_ios_sensor_core

class Tests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        Realm.Configuration.defaultConfiguration.inMemoryIdentifier = self.name
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testObserver(){
        
//        #if targetEnvironment(simulator)
//        print("This test requires a real device.")
//
//        #else
        
        class Observer:ConnectivityObserver{
            weak var connectivityExpectation: XCTestExpectation?
            var callback:(()->Void)? = nil
            
            func onInternetON() {
                print(#function)
                self.connectivityExpectation?.fulfill()
                if let cb = callback {
                    cb()
                }
            }
            
            func onInternetOFF() {
                print(#function)
                self.connectivityExpectation?.fulfill()
                if let cb = callback {
                    cb()
                }
            }
            
            func onGPSON() {
                print(#function)
            }
            
            func onGPSOFF() {
                print(#function)
            }
            
            func onBluetoothON() {
                print(#function)
            }
            
            func onBluetoothOFF() {
                print(#function)
            }
            
            func onBackgroundRefreshON() {
                print(#function)
            }
            
            func onBackgroundRefreshOFF() {
                print(#function)
            }
            
            func onLowPowerModeON() {
                print(#function)
            }
            
            func onLowPowerModeOFF() {
                print(#function)
            }
            
            func onPushNotificationOn() {
                print(#function)
            }
            
            func onPushNotificationOff() {
                print(#function)
            }
            
            func onWiFiON() {
                print(#function)
            }
            
            func onWiFiOFF() {
                print(#function)
            }
            
        }
        
        let connectivityObserverExpect = expectation(description: "Connectivity observer")
        let observer = Observer()
        observer.connectivityExpectation = connectivityObserverExpect
        let sensor = ConnectivitySensor.init(ConnectivitySensor.Config().apply{ config in
            config.sensorObserver = observer
            config.dbType = .REALM
            config.interval = 1
        })
        observer.callback = {
            if let engine = sensor.dbEngine {
                engine.fetch(ConnectivityData.self, nil){ (resultsObject, error) in
                    if let results = resultsObject as? Results<Object>{
                        XCTAssertGreaterThanOrEqual(results.count, 1)
                    }else{
                        XCTFail()
                    }

                }
            }
        }
        
        sensor.start()
        sensor.checkConnectivity(force: true)
        
        wait(for: [connectivityObserverExpect], timeout: 10)
        sensor.stop()
        
//        #endif
    }
    
    func testControllers() {
        let sensor = ConnectivitySensor(ConnectivitySensor.Config().apply{config in
            config.dbType = .REALM
        })
        
        /// test set label action ///
        let expectSetLabel = expectation(description: "set label")
        let newLabel = "hello"
        let labelObserver = NotificationCenter.default.addObserver(forName: .actionAwareConnectivitySetLabel, object: nil, queue: .main) { (notification) in
            let dict = notification.userInfo;
            if let d = dict as? Dictionary<String,String>{
                XCTAssertEqual(d[ConnectivitySensor.EXTRA_LABEL], newLabel)
            }else{
                XCTFail()
            }
            expectSetLabel.fulfill()
        }
        sensor.set(label:newLabel)
        
        wait(for: [expectSetLabel], timeout: 5)
        NotificationCenter.default.removeObserver(labelObserver)
        
        /// test sync action ////
        let expectSync = expectation(description: "sync")
        let syncObserver = NotificationCenter.default.addObserver(forName: Notification.Name.actionAwareConnectivitySync , object: nil, queue: .main) { (notification) in
            expectSync.fulfill()
            print("sync")
        }
        sensor.sync()
        wait(for: [expectSync], timeout: 5)
        NotificationCenter.default.removeObserver(syncObserver)
        
        
//        #if targetEnvironment(simulator)
//        print("This test requires a real device.")
//
//        #else
        
        //// test start action ////
        let expectStart = expectation(description: "start")
        let observer = NotificationCenter.default.addObserver(forName: .actionAwareConnectivityStart,
                                                              object: nil,
                                                              queue: .main) { (notification) in
                                                                expectStart.fulfill()
                                                                print("start")
        }
        sensor.start()
        wait(for: [expectStart], timeout: 5)
        NotificationCenter.default.removeObserver(observer)
        
        
        /// test stop action ////
        let expectStop = expectation(description: "stop")
        let stopObserver = NotificationCenter.default.addObserver(forName: .actionAwareConnectivityStop, object: nil, queue: .main) { (notification) in
            expectStop.fulfill()
            print("stop")
        }
        sensor.stop()
        wait(for: [expectStop], timeout: 5)
        NotificationCenter.default.removeObserver(stopObserver)
        
//        #endif
    }
    
    func testConnectivityData() {
        let dict = ConnectivityData().toDictionary()
        XCTAssertEqual(dict["type"] as? Int, -1)
        XCTAssertEqual(dict["subtype"] as? String, "")
        XCTAssertEqual(dict["state"] as? Int, 0)
    }
    
    func testSyncModule(){
        #if targetEnvironment(simulator)
        
        print("This test requires a real device.")
        
        #else
        // success //
        let sensor = ConnectivitySensor.init(ConnectivitySensor.Config().apply{ config in
            config.debug = true
            config.dbType = .REALM
            config.dbHost = "node.awareframework.com:1001"
            config.dbPath = "sync_db"
        })
        if let engine = sensor.dbEngine as? RealmEngine {
            engine.removeAll(ConnectivityData.self)
            for _ in 0..<100 {
                engine.save(ConnectivityData())
            }
        }
        let successExpectation = XCTestExpectation(description: "success sync")
        let observer = NotificationCenter.default.addObserver(forName: Notification.Name.actionAwareConnectivitySyncCompletion,
                                                              object: sensor, queue: .main) { (notification) in
                                                                if let userInfo = notification.userInfo{
                                                                    if let status = userInfo["status"] as? Bool {
                                                                        if status == true {
                                                                            successExpectation.fulfill()
                                                                        }
                                                                    }
                                                                }
        }
        sensor.sync(force: true)
        wait(for: [successExpectation], timeout: 20)
        NotificationCenter.default.removeObserver(observer)
        
        ////////////////////////////////////
        
        // failure //
        let sensor2 = ConnectivitySensor.init(ConnectivitySensor.Config().apply{ config in
            config.debug = true
            config.dbType = .REALM
            config.dbHost = "node.awareframework.com.com" // wrong url
            config.dbPath = "sync_db"
        })
        let failureExpectation = XCTestExpectation(description: "failure sync")
        let failureObserver = NotificationCenter.default.addObserver(forName: Notification.Name.actionAwareConnectivitySyncCompletion,
                                                                     object: sensor2, queue: .main) { (notification) in
                                                                        if let userInfo = notification.userInfo{
                                                                            if let status = userInfo["status"] as? Bool {
                                                                                if status == false {
                                                                                    failureExpectation.fulfill()
                                                                                }
                                                                            }
                                                                        }
        }
        if let engine = sensor2.dbEngine as? RealmEngine {
            engine.removeAll(ConnectivityData.self)
            for _ in 0..<100 {
                engine.save(ConnectivityData())
            }
        }
        sensor2.sync(force: true)
        wait(for: [failureExpectation], timeout: 20)
        NotificationCenter.default.removeObserver(failureObserver)
        
        #endif
    }
    
    
    
    
    
    
    
    ///////////////////////////////////////////
    
    
    //////////// storage ///////////
    
    var realmToken:NotificationToken? = nil
    
    func testSensorModule(){
        
        #if targetEnvironment(simulator)
        
        print("This test requires a real device.")
        
        #else
        
        let sensor = ConnectivitySensor.init(ConnectivitySensor.Config().apply{ config in
            config.debug = true
            config.dbType = .REALM
            config.dbPath = "sensor_module"
        })
        let expect = expectation(description: "sensor module")
        if let realmEngine = sensor.dbEngine as? RealmEngine {
            // remove old data
            realmEngine.removeAll(ConnectivityData.self)
            // get a RealmEngine Instance
            if let realm = realmEngine.getRealmInstance() {
                // set Realm DB observer
                realmToken = realm.observe { (notification, realm) in
                    switch notification {
                    case .didChange:
                        // check database size
                        let results = realm.objects(ConnectivityData.self)
                        print(results.count)
                        XCTAssertGreaterThanOrEqual(results.count, 1)
                        realm.invalidate()
                        expect.fulfill()
                        self.realmToken = nil
                        break;
                    case .refreshRequired:
                        break;
                    }
                }
            }
        }
        
        var storageExpect:XCTestExpectation? = expectation(description: "sensor storage notification")
        var token: NSObjectProtocol?
        token = NotificationCenter.default.addObserver(forName: Notification.Name.actionAwareConnectivity,
                                                       object: sensor,
                                                       queue: .main) { (notification) in
                                                        if let exp = storageExpect {
                                                            exp.fulfill()
                                                            storageExpect = nil
                                                            NotificationCenter.default.removeObserver(token!)
                                                        }
                                                        
        }
        
        sensor.start() // start sensor
        
        wait(for: [expect,storageExpect!], timeout: 10)
        sensor.stop()
        #endif
    }

}
