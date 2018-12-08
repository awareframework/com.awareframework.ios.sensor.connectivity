//
//  DataSyncHelper.swift
//  com.aware.ios.sensor.core
//
//  Created by Yuuki Nishiyama on 2018/10/18.
//

import UIKit
import Foundation
import RealmSwift
import SwiftyJSON


open class RealmDbSyncHelper:URLSessionDataTask, URLSessionDelegate, URLSessionDataDelegate, URLSessionTaskDelegate {

    // https://developer.apple.com/documentation/foundation/url_loading_system/downloading_files_in_the_background?language=objc
    // https://qiita.com/yimajo/items/a591cf1b47d45db2b6ca
    
    var uploadingObjects = Array<AwareObject>()
    var receivedData = Data()
    var urlSession:URLSession?
    
    var endFlag = false
    
    var engine:Engine
    var host:String
    var objectType:Object.Type
    var tableName:String
    var config:DbSyncConfig
    
    public init(engine:Engine, host:String, tableName:String, objectType:Object.Type, config:DbSyncConfig){
        self.engine     = engine
        self.host       = host
        self.tableName  = tableName
        self.objectType = objectType
        self.config     = config
    }
    
    open func run(){
        
        self.urlSession = {
            let sessionConfig = URLSessionConfiguration.background(withIdentifier: "aware.sync.task.identifier.\(tableName)")
            sessionConfig.allowsCellularAccess = true
            sessionConfig.sharedContainerIdentifier = "aware.sync.task.shared.container.identifier"
            return URLSession(configuration: sessionConfig, delegate: self, delegateQueue: nil)
        }()
        
        urlSession?.getAllTasks(completionHandler: { (tasks) in
            if tasks.count == 0 {
                DispatchQueue.main.sync {
                    if let unwrappedCandidates = self.engine.fetch(self.tableName, self.objectType, nil) as? Results<Object> {
                        print(unwrappedCandidates.count)
                        var dataArray = Array<Dictionary<String, Any>>()
                        self.uploadingObjects.removeAll()
                        let objects = unwrappedCandidates.prefix(self.config.batchSize)
                        if objects.count < self.config.batchSize {
                            self.endFlag = true
                        }
                        for object in objects{
                            let castResult = object as? AwareObject
                            if let unwrappedCastResult = castResult{
                                self.uploadingObjects.append(unwrappedCastResult)
                                dataArray.append(unwrappedCastResult.toDictionary())
                            }
                        }
                        
                        
                        //// Set a HTTP Body
                        let timestamp = Int64(Date().timeIntervalSince1970/1000.0)
                        let device_id = AwareUtils.getCommonDeviceId()
                        var requestStr = ""
                        let requestParams: Dictionary<String, Any>
                            = ["timestamp":timestamp,
                               "deviceId":device_id,
                               "data":dataArray,
                               "tableName":self.tableName]
                        do{
                            let requestObject = try JSONSerialization.data(withJSONObject:requestParams)
                            requestStr = String.init(data: requestObject, encoding: .utf8)!
                            // requestStr = requestStr.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlUserAllowed)!
                        }catch{
                            print(error)
                        }
                        
                        if self.config.debug {
                            print(requestStr)
                        }
                        
                        let hostName = AwareUtils.cleanHostName(self.host)
                        
                        let url = URL.init(string: "https://"+hostName+"/insert/")
                        if let unwrappedUrl = url, let session = self.urlSession {
                            var request = URLRequest.init(url: unwrappedUrl)
                            request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
                            request.httpBody = requestStr.data(using: .utf8)
                            request.timeoutInterval = 30
                            request.httpMethod = "POST"
                            request.allowsCellularAccess = true
                            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                            request.setValue("application/json", forHTTPHeaderField: "Accept")
                            let task = session.dataTask(with: request) // dataTask(with: request)
                            task.resume()
                        }
                    }
                }
            }
        })
    }
    
    //////////
    
    open func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        
        if let httpResponse = response as? HTTPURLResponse{
            if(httpResponse.statusCode >= 200 && httpResponse.statusCode < 300){
                completionHandler(URLSession.ResponseDisposition.allow);
            }else{
                completionHandler(URLSession.ResponseDisposition.cancel);
                if config.debug { print("\( tableName )=>\(response)") }
                // print("\( config.table! )=>\(httpResponse.statusCode)")
            }
        }
    }
    
    open func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        if let e = error {
            print(#function)
            print(e)
        }
    }
    
    open func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        // print(#function)
        var responseState = false
        
        if let unwrappedError = error {
            if config.debug { print("failed: \(unwrappedError)") }
        }else{
            /**
             * TODO: this is an error handler
             * aware-server-node ( https://github.com/awareframework/aware-server-node/blob/master/handlers/errorHandlers.js )
             * generates 201 even if the query is wrong ...
             * {"status":404,"message":"Not found"} with error code 201
             *
             * The value should be as follows:
             *{"status":false,"message":"Not found"} with error code 404
             */
            do {
                let json = try JSON.init(data: receivedData)
                if json["status"] == 404 {
                    responseState = false
                }else{
                    // normal condition
                    responseState = true
                }
            }catch {
                if ( config.debug ) {
                    print("[\(tableName)]: Error: A JSON convert error: \(error)")
                }
                // An upload task is done correctly.
                responseState = true
            }
        }
        
        let response = String.init(data: receivedData, encoding: .utf8)
        if let unwrappedResponse = response{
            print(unwrappedResponse)
        }
        
        if (responseState){
            if config.debug { print("[\(tableName)] Success: A sync task is done correctly.") }
            session.finishTasksAndInvalidate()
            DispatchQueue.main.sync {
                engine.remove(uploadingObjects, "")
            }
        }else{
            session.invalidateAndCancel()
        }
        
        receivedData = Data()
        
        if responseState {
            // A sync process is succeed
            if endFlag {
                if config.debug { print("[\(tableName)] All sync tasks is done!!!") }
            }else{
                if config.debug { print("[\(tableName)] A sync task is done. Execute a next sync task.") }
                DispatchQueue.main.asyncAfter( deadline: DispatchTime.now() + 1 ) {
                    self.run()
                }
            }
        }else{
            //A sync process is failed
            if config.debug { print("[\(tableName)] A sync task is faild.") }
        }
    }
    
    
    open func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        /// show progress of an upload process
        if config.debug {
            print("\(task.taskIdentifier): \( NSString(format: "%.2f",Double(totalBytesSent)/Double(totalBytesExpectedToSend)*100.0))%")
        }
    }
    
    open func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        if config.debug{
            print("\(#function):\(dataTask.taskIdentifier)")
        }
        self.receivedData.append(data)
    }
    
    public func stop() {
        print("stop()")
    }
}

