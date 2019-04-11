//
//  NativeValue.swift
//  SwiftDefaults
//
//  Created by Larry Gensch on 4/6/19.
//  Copyright © 2019 Larry Gensch. All rights reserved.
//

import Foundation

public extension SwiftDefaults {
    class NativeValue<T: SwiftDefaults.NativeType> : BaseValue<T?> {
        public override func remove() {
            defaults.removeObject(forKey: key)
        }
        
        public override func invalidate() {
            observer = nil
        }

        public override var observer: ((String, T?) -> Void)? {
            didSet {
                let name = (observer == nil) ? "nil" : "something"
            }
        }
        public var _isDestroyed = false
        
        public override func isDestroyed() -> Bool {
            return _isDestroyed
        }
        
        internal func markAsDestroyed() {
            defaultDescription = "** DESTROYED **"
            remove()
            invalidate()
            _isDestroyed = true
        }
        
        public override func destroy() {
            markAsDestroyed()
            swiftDefaults.destroyValue(self)
        }

        public init?(key: String,
                     defaults: SwiftDefaults,
                     observer: ((String, T?)->Void)? = nil) {
            super.init(key: key, defaults: defaults)
            self.observer = observer
            if !swiftDefaults.addValue(self) {
                return nil
            }
            _getter = {
                return defaults.defaults.object(forKey: key) as? T
            }
            _setter = { (value) in
                if let value = value {
                    defaults.defaults.set(value, forKey: key)
                } else {
                    self.remove()
                }
            }
            self.defaults.addObserver(self,
                                      forKeyPath: key,
                                      options: [.new],
                                      context: &context)
            kvoAdded = true
        }

        private var count = 0
        public override func observeValue(forKeyPath keyPath: String?,
                                          of object: Any?,
                                          change: [NSKeyValueChangeKey : Any]?,
                                          context: UnsafeMutableRawPointer?) {
            guard context == &self.context,
                keyPath == key else {
                    super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
                    return
            }
//            observer?(key, value)
            if let observer = observer {
                let key = self.key
                let value = self.value
                count += 1
                let myCount = count
                observerQueue.async {
                    observer(key, value)
                }
            }
        }

        deinit {
            if kvoAdded {
                defaults.removeObserver(self, forKeyPath: key, context: &context)
                kvoAdded = false
            }
        }

    }

    func value<T: NativeType>(for type: T.Type,
                              key: String,
                              observer: ((String, T?)->Void)? = nil) -> NativeValue<T>? {
        return NativeValue<T>(key: key,
                              defaults: self,
                              observer: observer)
    }

}

public func << <T: SwiftDefaults.NativeType>(_ lhs: SwiftDefaults.NativeValue<T>, _ rhs: T) {
    lhs.value = rhs
}
