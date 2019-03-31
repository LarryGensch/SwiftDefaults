//
//  DefaultedValue.swift
//  SwiftDefaults
//
//  Created by Larry Gensch on 3/30/19.
//  Copyright © 2019 Larry Gensch. All rights reserved.
//

import Foundation

public extension SwiftDefaults {
    class DefaultedValue<T: NativeType> : DefaultValueProtocol {
        public typealias ValueType = T
        
        public var key: String {
            return proxyValue.key
        }
        
        public var value: T {
            set {
                proxyValue.value = newValue
            }
            get {
                return proxyValue.value ?? defaultValue
            }
        }
        
        public var defaults : UserDefaults {
            return proxyValue.defaults
        }
        
        public var defaultDescription: String?
        
        public var observer: ObserverCallback? {
            didSet {
                setupProxyObserver()
            }
        }
        
        public func invalidate() {
            observer = nil
            proxyValue.remove()
            proxyValue.invalidate()
        }

        public func destroy() {
            invalidate()
            proxyValue.destroy()
        }

        let defaultValue : T
        var proxyValue : Value<T>
        
        func proxyObserver(_ key: String, _ value: T?) {
            observer?(key, value ?? defaultValue)
        }
        
        func setupProxyObserver() {
            if observer == nil {
                proxyValue.remove()
            } else {
                proxyValue.observer = proxyObserver
            }
        }
            
        init(value: Value<T>, defaultValue: T) {
            self.defaultValue = defaultValue
            self.proxyValue = value
            self.observer = nil
            
            proxyValue.remove()
        }
    }
    
    func defaultValue<T: NativeType>(_ defaultValue: T,
                                     for key: String) -> DefaultedValue<T> {
        let value = Value<T>(key: key, defaults: self)
        return DefaultedValue(value: value, defaultValue: defaultValue)
    }
}

public func << <T>(lhs: SwiftDefaults.DefaultedValue<T>,
                   rhs: T) {
    lhs.value = rhs
}

