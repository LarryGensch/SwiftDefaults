//
//  AnyValue.swift
//  SwiftDefaults
//
//  Created by Larry Gensch on 4/7/19.
//  Copyright © 2019 Larry Gensch. All rights reserved.
//

import Foundation

public extension SwiftDefaults {
    class AnyValue<VType> : BaseValue<VType> {
        public typealias ValueType = VType
        public typealias Callback = (String, VType)->Void

        public override func isDestroyed() -> Bool {
            return _isDestroyed()
        }
        
        public override var defaultDescription: String? {
            get { return descGetter() }
            set { descSetter(newValue) }
        }
        
        public override var observer: ((String, VType)->Void)? {
            get { return observerGetter() }
            set { observerSetter(newValue) }
        }

        public override var observerQueue: DispatchQueue {
            get { return queueGetter() }
            set { queueSetter(newValue) }
        }
        
        public override func remove() {
            _remove()
        }
        
        public override func invalidate() {
            _invalidate()
        }
        
        public override func destroy() {
            _destroy()
        }
        
        private var observerSetter : (((String, VType)->Void)?)->Void
        private var observerGetter : ()->((String, VType)->Void)?
        private var descSetter : (String?)->Void
        private var descGetter : ()->String?
        private var queueGetter : ()->DispatchQueue
        private var queueSetter : (DispatchQueue)->Void
        private var _isDestroyed : ()->Bool
        private var _invalidate : ()->Void
        private var _destroy : ()->Void
        private var _remove : ()->Void
        
        init<V: ValueProtocol>(_ base: V)
            where V.ValueType == VType {
                self.observerSetter = { base.observer = $0 }
                self.observerGetter = { return base.observer }
                self.descSetter = { base.defaultDescription = $0 }
                self.descGetter = { return base.defaultDescription }
                self.queueGetter = { return base.observerQueue }
                self.queueSetter = { base.observerQueue = $0 }
                self._invalidate = { base.invalidate() }
                self._destroy = { base.destroy() }
                self._remove = { base.remove() }
                self._isDestroyed = { return base.isDestroyed() }
                super.init(key: base.key, defaults: base.swiftDefaults)!
                self._getter = base._getter
                self._setter = base._setter
        }

//        public static func << <T>(_ lhs: AnyValue<T>, _ rhs: T) {
//            lhs.value = rhs
//        }
   }
}

public extension SwiftDefaults.ValueProtocol {
    func erased() -> SwiftDefaults.AnyValue<ValueType> {
        return SwiftDefaults.AnyValue<ValueType>(self)
    }
}
