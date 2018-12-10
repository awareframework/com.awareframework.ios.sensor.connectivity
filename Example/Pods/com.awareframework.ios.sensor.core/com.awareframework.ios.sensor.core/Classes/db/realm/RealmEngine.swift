//
//  RealmEngine.swift
//  CoreAware
//
//  Created by Yuuki Nishiyama on 2018/03/06.
//

import Foundation
import RealmSwift
import Reachability
import CommonCrypto

open class RealmEngine: Engine {

    var syncHelpers = Array<RealmDbSyncHelper>()
    var realmConfig = Realm.Configuration()
    
    public override init(_ config: EngineConfig) {
        super.init(config)
        if let path = config.path {
            // set RealmDB config
            // var realmConfig = Realm.Configuration()
            // set RealmDB location
            let documentDirFileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
            realmConfig.fileURL = documentDirFileURL.appendingPathComponent(path+".realm")
            
            // Show the local-Realm DB path
            // print(realmConfig.fileURL!)
            
            // set the encryption key
            if let encryptionKey = config.encryptionKey {
                //
                // Realm needs 64-byte text as an encryption key.
                // So then, the given key has to be converted a 64-byte text using sha256.
                //
                // Realm supports encrypting the database file on disk with AES-256+SHA2
                // by supplying a 64-byte encryption key when creating a Realm.
                // There is a small performance hit (typically less than 10% slower)
                // when using encrypted Realms.
                // https://realm.io/docs/swift/latest/#encryption
                //
                let bytesKey = encryptionKey.sha256.data(using: .utf8, allowLossyConversion: false)!
                // print(encryptionKey.sha256)
                realmConfig.encryptionKey = bytesKey
            }
            do {
                var _ = try Realm(configuration: realmConfig)
                // TODO: Set Realm DB observer
                // https://realm.io/docs/swift/latest/#notifications
//                let token = realm.observe { (notification, realm) in
//                    switch notification {
//                    case .didChange:
//                        break;
//                    case .refreshRequired:
//                        break;
//                    }
//                }
//                realm.invalidate()
            }catch let error as NSError{
                print("[Error][\(path)]",error)
            }
        }else{
            print("[Error] The database path is `nil`. RealmEngine could not generate RealmEngine instance.")
        }
    }
    
    
    /// Provide a new Realm instance
    /// 
    /// - Returns: A Realm instance
    public func getRealmInstance() -> Realm? {
        do {
            let realm = try Realm(configuration: realmConfig)
            return realm
        }catch let error as NSError{
            print("[Error][\(self.config.type)]",error)
        }
        return nil
    }
    
    open override func save(_ data: AwareObject, completion:((Error?)->Void)?) {
        self.save([data], completion:completion)
    }
    
    open override func save(_ data: Array<AwareObject>, completion:((Error?)->Void)?){
        do{
            let realm = try Realm(configuration: self.realmConfig)
            realm.beginWrite()
            autoreleasepool{
                realm.add(data)
            }
            try realm.commitWrite()
            if let callback = completion {
                callback(nil)
            }
        }catch{
            print("\(error)")
            if let callback = completion {
                callback(error)
            }
        }
    }
    
    /// Fetch stored data from Realm database.
    /// By using this method you can fetch stored data from Realm databasee with a filter.
    /// You can convert the return value (`Any?`) to Results<Object> by if-let statement.
    ///
    /// - Parameters:
    ///   - objectType: An object type of Realm database.
    ///   - filter: A filter for this search query. (https://realm.io/docs/javascript/latest/#filtering)
    /// - Returns: A Realm `Results<Object>` or `nil`.
    public override func fetch(_ objectType: Object.Type?, _ filter: String?) -> Any? {
    
        do {
            let realm = try Realm(configuration: realmConfig)
            if let uwFilter = filter, let uwObjType = objectType  {
                return realm.objects(uwObjType).filter(uwFilter)
            }else if let uwObjType = objectType {
                return realm.objects(uwObjType)
            }
        } catch {
            print("\(error)")
        }
        return nil
    }
    
    public override func fetch(_ objectType: Object.Type?, _ filter: String?, completion: ((Any?, Error?) -> Void)?) {
        self.fetch(objectType, filter) { (results:Results<Object>?, error:Error?) in
            if let callback = completion {
                callback(results,error)
            }
        }
    }
    
    open func fetch(_ objectType: Object.Type?, _ filter: String?, completion: ((Results<Object>?, Error?) -> Void)?) {
        if let callback = completion {
            do {
                let realm = try Realm(configuration: realmConfig)
                if let uwFilter = filter, let uwObjType = objectType  {
                    callback(realm.objects(uwObjType).filter(uwFilter), nil)
                }else if let uwObjType = objectType {
                    callback(realm.objects(uwObjType), nil)
                }
            } catch {
                callback(nil, error)
            }
        }
    }
    
    open func fetch(_ objectType: Object.Type?, _ filter: String?, completion:(Results<Object>?, Realm?, Error?) -> Void){
        do {
            let realm = try Realm(configuration: realmConfig)
            if let uwFilter = filter, let uwObjType = objectType  {
                completion(realm.objects(uwObjType).filter(uwFilter), realm, nil)
            }else if let uwObjType = objectType {
                 completion(realm.objects(uwObjType), realm, nil)
            }
        } catch {
            print(error)
            completion(nil, nil, error)
        }
    }
    
    open func remove(_ data:Array<Object>, in realm:Realm){
        self.remove(data, in: realm, completion: nil)
    }
    
    open func remove(_ data:Array<Object>, in realm:Realm, completion:((Error?)->Void)?){
        do {
            realm.beginWrite()
            realm.delete(data)
            try realm.commitWrite()
            if let callback = completion {
                callback(nil)
            }
        } catch {
            if let callback = completion {
                callback(error)
            }
        }
    }
    
    open override func removeAll(_ objectType: Object.Type?, completion:((Error?)->Void)?){
        do{
            let realm = try Realm(configuration: realmConfig)
            try realm.write {
                realm.deleteAll()
            }
            if let callback = completion {
                callback(nil)
            }
        }catch{
            if let callback = completion {
                callback(error)
            }
        }
    }
    
    open override func remove(_ objectType: Object.Type?, _ filter: String?, completion:((Error?)->Void)?){
        if let realm = self.getRealmInstance(),
          let uwType = objectType {
            do {
                var results = realm.objects(uwType)
                if let uwFilter = filter {
                    results = results.filter(uwFilter)
                }
                realm.beginWrite()
                realm.delete(results)
                try realm.commitWrite()
                if let callback = completion {
                    callback(nil)
                }
            } catch {
                if let callback = completion {
                    callback(error)
                }
            }
        }else{
            print("[Error] Realm instance is `nil`")
        }
    }
    
    open override func startSync(_ tableName:String, _ objectType: Object.Type?, _ syncConfig: DbSyncConfig) {
        if let uwHost = self.config.host, let uwObjType = objectType {
            
            for helper in self.syncHelpers {
                if let index = syncHelpers.index(of: helper) {
                    if helper.tableName == tableName {
                        helper.cancel()
                        self.syncHelpers.remove(at: index)
                    }
                }
            }
            let syncHelper = RealmDbSyncHelper.init(engine: self,
                                                    host:   uwHost,
                                                    tableName:  tableName,
                                                    objectType: uwObjType,
                                                    config: syncConfig)
            self.syncHelpers.append(syncHelper)
            
            if let queue = syncConfig.dispatchQueue {
                queue.async {
                    syncHelper.run(completion: syncConfig.completionHandler)
                }
            }else{
                syncHelper.run(completion: syncConfig.completionHandler)
            }

        }else{
            print("[Error][\(tableName)] 'Host Name' or 'Object Type' is nil. Please check the parapmeters.")
        }
    }
    
    open override func stopSync() {
        // print("Please overwrite -cancelSync()")
        for syncHelper in self.syncHelpers {
            syncHelper.stop()
        }
    }
    
    open override func close() {
        do{
            let realm = try Realm(configuration: realmConfig)
            realm.invalidate()
        }catch{
            print(error)
        }
    }
}

enum CryptoAlgorithm {
    case MD5, SHA1, SHA224, SHA256, SHA384, SHA512
    
    var digestLength: Int {
        var result: Int32 = 0
        switch self {
        case .MD5:      result = CC_MD5_DIGEST_LENGTH
        case .SHA1:     result = CC_SHA1_DIGEST_LENGTH
        case .SHA224:   result = CC_SHA224_DIGEST_LENGTH
        case .SHA256:   result = CC_SHA256_DIGEST_LENGTH
        case .SHA384:   result = CC_SHA384_DIGEST_LENGTH
        case .SHA512:   result = CC_SHA512_DIGEST_LENGTH
        }
        return Int(result)
    }
}

extension String {
    var md5:    String { return digest(string: self, algorithm: .MD5) }
    var sha1:   String { return digest(string: self, algorithm: .SHA1) }
    var sha224: String { return digest(string: self, algorithm: .SHA224) }
    var sha256: String { return digest(string: self, algorithm: .SHA256) }
    var sha384: String { return digest(string: self, algorithm: .SHA384) }
    var sha512: String { return digest(string: self, algorithm: .SHA512) }
    
    func digest(string: String, algorithm: CryptoAlgorithm) -> String {
        var result: [CUnsignedChar]
        let digestLength = Int(algorithm.digestLength)
        if let cdata = string.cString(using: String.Encoding.utf8) {
            result = Array(repeating: 0, count: digestLength)
            switch algorithm {
            case .MD5:      CC_MD5(cdata, CC_LONG(cdata.count-1), &result)
            case .SHA1:     CC_SHA1(cdata, CC_LONG(cdata.count-1), &result)
            case .SHA224:   CC_SHA224(cdata, CC_LONG(cdata.count-1), &result)
            case .SHA256:   CC_SHA256(cdata, CC_LONG(cdata.count-1), &result)
            case .SHA384:   CC_SHA384(cdata, CC_LONG(cdata.count-1), &result)
            case .SHA512:   CC_SHA512(cdata, CC_LONG(cdata.count-1), &result)
            }
        } else {
            fatalError("Nil returned when processing input strings as UTF8")
        }
        return (0..<digestLength).reduce("") { $0 + String(format: "%02hhx", result[$1])}
    }
}

