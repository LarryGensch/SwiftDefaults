//
//  TransformedValue.swift
//  SwiftDefaults
//
//  Created by Larry Gensch on 4/6/19.
//  Copyright © 2019 Larry Gensch. All rights reserved.
//

import Foundation

public extension SwiftDefaults {
    class TransformedValue<Transformed, Proxy> : BaseValue<Transformed>, TransformedValueProtocol {
        public typealias ValueType = Transformed
        public typealias ProxyType = Proxy

        public override var observer: ((String, ValueType)->Void)? {
            didSet {
                setupProxyObserver()
            }
        }

        public override var observerQueue: DispatchQueue {
            didSet {
                proxy.observerQueue = observerQueue
            }
        }

        init?(proxyClosure: ()->AnyValue<ProxyType>,
              observer: ((String, Transformed)->Void)? = nil,
              encoder: @escaping ((ValueType)->ProxyType),
              decoder: @escaping ((ProxyType)->ValueType)) {

            let proxy = proxyClosure()
            self.proxy = proxy
            super.init(key: proxy.key, defaults: proxy.swiftDefaults)
            self._getter = { return decoder(proxy.value) }
            self._setter = { proxy.value = encoder($0) }
            self.observer = observer
            self.baseDescription = { ()->String in
                let name = String(describing: type(of: self))
                let vType = String(describing: ValueType.self)
                let pType = String(describing: ProxyType.self)
                return "\(name)<\(vType),\(pType)>"
            }()
            setupProxyObserver()
        }
        
        public let proxy : AnyValue<Proxy>
        
        private func setupProxyObserver() {
            if let observer = observer {
                let value = self.value
                proxy.observer = { (key, _) in
                    observer(key, value)
                }
            } else {
                proxy.invalidate()
            }
        }
    }
}
