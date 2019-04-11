//
//  EnumValue.swift
//  Amber3Utils
//
//  Created by Larry Gensch on 3/16/19.
//  Copyright © 2019 Larry Gensch. All rights reserved.
//

import Foundation

public extension SwiftDefaults {
    /// Maps an enumeration whose `RawValue` conforms to `NativeType`
    class EnumValue<T> : TransformedValue<T?, T.RawValue?>
    where T: RawRepresentable, T.RawValue : NativeType {
        init?(key: String,
              defaults: SwiftDefaults,
              observer: ((String, T?)->Void)? = nil) {
            guard let proxy = NativeValue<T.RawValue>(key: key, defaults: defaults) else {
                return nil
            }
            super.init(proxyClosure: { return proxy.erased() },
                       observer: observer,
                       encoder: { (value) in value?.rawValue },
                       decoder: { (value) in
                        guard let value = value else { return nil }
                        return T(rawValue: value)
            })
        }
    }
    
    func enumValue<T>(
        for type: T.Type,
        key: String,
        observer: ((String, T?)->Void)? = nil) -> EnumValue<T>?
        where T: RawRepresentable, T.RawValue : NativeType {
            return EnumValue<T>(key: key,
                                defaults: self,
                                observer: observer)
    }
    
    func enumArray<T>(for type: T.Type,
                      key: String,
                      observer: ((String, Array<T>?)->Void)? = nil) -> ArrayValue<T, T.RawValue>?
        where T: RawRepresentable, T.RawValue : NativeType {
            return ArrayValue<T, T.RawValue>(
                key: key,
                defaults: self,
                observer: observer,
                elementEncoder: {
                    return $0.rawValue
            },
                elementDecoder: {
                    return T(rawValue: $0)!
            })
    }
}

public func << <T>(_ lhs: SwiftDefaults.EnumValue<T>, _ rhs: T)
where T: RawRepresentable, T.RawValue : SwiftDefaults.NativeType {
    lhs.value = rhs
}
