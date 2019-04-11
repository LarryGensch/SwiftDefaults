//
//  DefaultedValue.swift
//  SwiftDefaults
//
//  Created by Larry Gensch on 4/6/19.
//  Copyright © 2019 Larry Gensch. All rights reserved.
//

import Foundation

public extension SwiftDefaults {
    class DefaultedValue<T> : TransformedValue<T, T?> {
        init?(proxyClosure: ()->AnyValue<T?>,
              defaultValue: T,
              observer: ((String, T) -> Void)? = nil) {
            super.init(proxyClosure: proxyClosure,
                       encoder: { $0 },
                       decoder: { $0 ?? defaultValue })
        }
    }

    func defaultValue<T: NativeType>(_ defaultValue: T,
                                     for key: String,
                                     observer: ((String, T)->Void)? = nil) -> DefaultedValue<T>? {
        guard let proxy = NativeValue<T>(key: key,
                                         defaults: self) else {
            return nil
        }
        return DefaultedValue<T>(proxyClosure: { return proxy.erased() },
                                 defaultValue: defaultValue,
                                 observer: observer)
    }

    func defaulted<T>(proxy: AnyValue<T?>,
                      defaultValue: T,
                      observer: ((String, T)->Void)? = nil) -> DefaultedValue<T>? {
        return DefaultedValue<T>(proxyClosure: { return proxy },
                                 defaultValue: defaultValue,
                                 observer: observer)

    }
}

public func << <T>(_ lhs: SwiftDefaults.DefaultedValue<T>, _ rhs: T) {
    lhs.value = rhs
}
