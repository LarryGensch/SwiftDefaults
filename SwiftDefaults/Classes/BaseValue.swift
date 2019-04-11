//
//  BaseValue.swift
//  SwiftDefaults
//
//  Created by Larry Gensch on 4/6/19.
//  Copyright © 2019 Larry Gensch. All rights reserved.
//

import Foundation

public extension SwiftDefaults {
    class BaseValue<T> : NSObject, ValueProtocol {
        public typealias ValueType = T
        
        public internal(set) var _getter: () -> T = { fatalError("_getter unimplemented") }
        public internal(set) var _setter: (T) -> Void = { (_) in fatalError("_getter unimplemented") }
        
        public let key: String
        public let swiftDefaults: SwiftDefaults
        public var defaultDescription: String?
        public var observer: ((String, T) -> Void)?
        public internal(set) var baseDescription = "UNKNOWN"
        public var observerQueue = DispatchQueue.main

        internal var kvoAdded = false
        internal var context = UInt8(0)

        public var value: T {
            get {
                return _getter()
            }
            set {
                _setter(newValue)
            }
        }
        
        public func remove() {
            fatalError("remove() unimplemented")
        }
        
        public func invalidate() {
            observer = nil
        }
        
        public func destroy() {
            fatalError("destroy() unimplemented")
        }
        
        public func isDestroyed() -> Bool {
            fatalError("isDestroyed() unimplemented")
        }


        init?(key: String,
              defaults: SwiftDefaults,
              observer: ((String, T?)->Void)? = nil) {
            self.key = key
            self.swiftDefaults = defaults
            self.observer = observer
            super.init()
            self.baseDescription = { ()->String in
                let name = String(describing: type(of: self))
                let valueType = String(describing: ValueType.self)
                return "\(name)<\(valueType)>"
            }()
        }
    }
}
