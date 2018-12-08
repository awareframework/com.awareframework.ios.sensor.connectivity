//
//  Engine.swift
//  CoreAware
//
//  Created by Yuuki Nishiyama on 2018/03/02.
//

import Foundation
import RealmSwift

public enum DatabaseType {
    case NONE
    case REALM
    // case SQLite
    // case CSV
}

public protocol EngineProtocal {
    
    func getAll( ) -> Array<Any>
    func findById(_ id: String) -> Any

    func save(_ data:AwareObject, _ tableName:String)
    func save(_ data:Array<AwareObject>, _ tableName:String)
    
    func fetch(_ tableName:String) -> Any?
    func fetch(_ tableName:String, _ filter:String?) -> Any?
    func fetch(_ tableName:String, _ objectType: Object.Type?, _ filter:String?) -> Any?
    
    func remove(_ data:AwareObject, _ tableName:String)
    func remove(_ data:Array<AwareObject>, _ tableName:String)
    func removeAll()
    
    func close()
    
    func startSync(_ tableName:String, _ syncConfig:DbSyncConfig)
    func startSync(_ tableName:String, _ objectType: Object.Type?, _ syncConfig:DbSyncConfig)
    func stopSync()
}

open class Engine: EngineProtocal {

    open var config:EngineConfig = EngineConfig()
    
    private init(){

    }
    
    public init(_ config: EngineConfig){
        self.config = config
    }
    
    open class EngineConfig{
        open var type: DatabaseType = DatabaseType.NONE
        open var encryptionKey:String?
        open var path:String?
        open var host:String?
    }
    
    open class Builder {
        
        var config:EngineConfig
        
        public init() {
            config = EngineConfig()
        }
        
        public func setType(_ type: DatabaseType) -> Builder {
            config.type = type
            return self
        }
        
        public func setEncryptionKey(_ key: String?) -> Builder {
            config.encryptionKey = key
            return self
        }
        
        public func setPath(_ path: String?) -> Builder {
            config.path = path
            return self
        }
        
        public func setHost(_ host: String?) -> Builder {
            config.host = host
            return self
        }
        
        public func build() -> Engine {
            switch config.type {
            case DatabaseType.REALM:
                return RealmEngine.init(self.config)
            case DatabaseType.NONE:
                return Engine.init()
            }
        }
    }
    
    open func getDefaultEngine() -> Engine {
        return Builder().build()
    }
    
    //////////////
    
    open func getAll( ) -> Array<Any>{
        // print("Please orverwrite -getAll()")
        return Array<Any>()
    }
    
    open func findById(_ id: String) -> Any {
        // print("Please orverwrite -findById(id)")
        return Object()
    }
    
    open func save (_ data:AwareObject, _ tableName:String){
        // print("Please orverwrite -save(objects)")
    }
    
    open func save (_ data:Array<AwareObject>, _ tableName:String){
        // print("Please orverwrite -save(objects)")
    }
    
    public func fetch(_ tableName: String) -> Any? {
        // print("Please orverwrite -fetch(tableName)")
        return self.fetch(tableName, nil)
    }
    
    public func fetch(_ tableName: String, _ filter: String?) -> Any? {
        // print("Please orverwrite -fetch(tableName)")
        return self.fetch(tableName, nil, filter)
    }
    
    public func fetch(_ tableName: String, _ objectType: Object.Type?, _ filter: String?) -> Any? {
        // print("Please orverwrite -fetc(type:fileter)")
        return nil
    }

    open func remove(_ data:AwareObject, _ tableName:String) {
        // print("Please orverwrite -remove(data)")
    }
    
    open func remove(_ data:Array<AwareObject>, _ tableName:String) {
        // print("Please orverwrite -remove(data)")
    }
    
    open func removeAll() {
        // print("Please overwrite -removeAll()")
    }
    
    open func startSync(_ tableName:String, _ syncConfig:DbSyncConfig){
        // print("Please orverwirte -startSync(tableName:syncConfig)")
    }
    
    open func startSync(_ tableName:String, _ objectType: Object.Type?, _ syncConfig:DbSyncConfig){
        // print("Please overwrite -startSync(tableName:objectType:syncConfig)")
    }
    
    open func stopSync() {
        // print("Please orverwirte -stopSync()")
    }
    
    open func close() {
        // print("Please orverwirte -close()")
    }
    
}


