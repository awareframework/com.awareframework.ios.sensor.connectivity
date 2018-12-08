//
//  RealmEngine.swift
//  CoreAware
//
//  Created by Yuuki Nishiyama on 2018/03/06.
//

import Foundation
import RealmSwift
import Reachability

open class RealmEngine: Engine {

    var syncHelper:RealmDbSyncHelper?
    
    open override func getAll( ) -> Array<Any>{
        return Array<Any>()
    }
    
    open override func findById(_ id: String) -> Any {
        return Object()
    }
    
    open override func save(_ data: AwareObject, _ tableName: String) {
        self.save([data], tableName)
    }
    
    open override func save(_ data: Array<AwareObject>, _ tableName:String) {
        do{
            let realm = try Realm()
            try realm.write {
                autoreleasepool{
                    realm.add(data)
                }
            }
        }catch{
            print("\(error)")
        }
    }
    
    
    open override func fetch(_ tableName: String, _ objectType: Object.Type?, _ filter: String?) -> Any? {
        do{
            let realm = try Realm()
            if let uwFilter = filter, let uwObjType = objectType  {
                return realm.objects(uwObjType).filter(uwFilter)
            }else if let uwObjType = objectType {
                return realm.objects(uwObjType)
            }
        }catch{
            print("\(error)")
        }
        return nil
    }
    
    open override func remove(_ data:Array<AwareObject>, _ tableName:String){
        do{
            let realm = try Realm()
            try realm.write{
                realm.delete(data)
            }
        }catch{
            print("\(error)")
        }
    }
    
    open override func removeAll(){
        do{
            let realm = try Realm()
            try realm.write {
                realm.deleteAll()
            }
        }catch{
            print("\(error)")
        }
    }
    
    open override func startSync(_ tableName: String, _ syncConfig: DbSyncConfig) {
        self.startSync(tableName, nil, syncConfig)
    }
    
    open override func startSync(_ tableName: String, _ objectType: Object.Type?, _ syncConfig: DbSyncConfig) {
        if let uwHost = self.config.host, let uwObjType = objectType {
            self.syncHelper = RealmDbSyncHelper.init(engine: self, host: uwHost, tableName: tableName,
                                                     objectType: uwObjType, config: syncConfig)
            if let helper = self.syncHelper {
                helper.run()
            }
        }else{
            print("[Error][\(tableName)] 'Host Name' or 'Object Type' is nil. Please check the parapmeters.")
        }
    }
    
    open override func stopSync() {
        // print("Please overwrite -cancelSync()")
        if let uwSyncHelper = self.syncHelper {
            uwSyncHelper.stop()
        }
    }
    
    open override func close() {
        do{
            let realm = try Realm()
            realm.invalidate()
        }catch{
            print("\(error)")
        }
    }
}

