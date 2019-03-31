//
//  SwiftDefaults.swift
//  SwiftDefaults
//
//  Created by Larry Gensch on 3/22/19.
//  Copyright © 2019 Larry Gensch. All rights reserved.
//

import Foundation

/// Base class for all SwiftDefaults code
public class SwiftDefaults {
    public let defaults : UserDefaults
    
    public init(_ defaults: UserDefaults) {
        self.defaults = defaults
    }
    
    /// Clear all SwiftDefaults, optionally allowing exceptions
    ///
    /// - Parameter except: Array containing keys that will not be removed.
    /// Pass `nil` if you want all keys removed.
    public func destroyAll(except: [String]? = nil) {
        let except = Set(except ?? [String]())
        objc_sync_enter(keyValueSync)
        defer { objc_sync_exit(keyValueSync) }
        Set(keyValueTypes.keys)
            .subtracting(except)
            .forEach {
                defaults.removeObject(forKey: $0)
                keyValueTypes.removeValue(forKey: $0)
        }
        Set(keyValues.keys)
            .subtracting(except)
            .forEach {
                defaults.removeObject(forKey: $0)
                keyValues.removeValue(forKey: $0)
        }
    }

    enum Error : LocalizedError {
        case existingTypeForKey(NativeType.Type)
        
        var localizedDescription: String {
            switch self {
            case .existingTypeForKey(let type):
                return "Different type (\(type)) already exists for key"
            }
        }
    }

    var keyValueTypes = [String:NativeType.Type]()
    var keyValueSync = NSObject()
    var keyValues = [String:NSHashTable<AnyObject>]()
    
    func addValue<T: NativeType>(_ value: Value<T>) throws {
        let type = T.self
        let key = value.key
        objc_sync_enter(keyValueSync)
        defer { objc_sync_exit(keyValueSync) }
        if let existingType = keyValueTypes[key],
            existingType != type {
            throw Error.existingTypeForKey(existingType)
        }
        keyValueTypes[key] = type
        
        if let hash = keyValues[key] {
            hash.add(value)
        } else {
            let hash = NSHashTable<AnyObject>.weakObjects()
            hash.add(value)
            keyValues[key] = hash
        }
    }
    
    func removeValue<T: NativeType>(_ value: Value<T>) {
        let key = value.key
        let type = T.self
        objc_sync_enter(keyValueSync)
        defer { objc_sync_exit(keyValueSync) }
        keyValueTypes.removeValue(forKey: key)
        guard let hash = keyValues[key] else { return }
        hash.remove(value)
    }
    
    func destroyValue<T: NativeType>(_ value: Value<T>)
    where T: NativeType {
        let key = value.key
        let type = T.self
        objc_sync_enter(keyValueSync)
        defer { objc_sync_exit(keyValueSync) }
        keyValueTypes.removeValue(forKey: key)
        guard let hash = keyValues[key] else { return }
        for value in hash.allObjects {
            if let value = value as? Value<T> {
                value.makeDestroyed()
            }
        }
    }
    
    /// Only used for testing
    public static var isTesting = false
}
