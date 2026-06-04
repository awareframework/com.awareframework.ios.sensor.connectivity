import XCTest
import com_awareframework_ios_sensor_connectivity
import com_awareframework_ios_core

class Tests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testObserver() throws {
        #if targetEnvironment(simulator)
        throw XCTSkip("This test requires a real device with Realm.")
        #endif
    }
    
    func testControllers() {
        let sensor = ConnectivitySensor(ConnectivitySensor.Config().apply{config in
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
        XCTAssertEqual(dict["type"] as? Int, 0)
        XCTAssertEqual(dict["subtype"] as? String, "")
        XCTAssertEqual(dict["state"] as? Int, 0)
    }
    
    func testSyncModule() throws {
        #if targetEnvironment(simulator)
        throw XCTSkip("This test requires a real device with Realm.")
        #endif
    }
    
    
    
    
    
    
    
    ///////////////////////////////////////////
    
    
    //////////// storage ///////////
    
    func testSensorModule() throws {
        #if targetEnvironment(simulator)
        throw XCTSkip("This test requires a real device with Realm.")
        #endif
    }

}
