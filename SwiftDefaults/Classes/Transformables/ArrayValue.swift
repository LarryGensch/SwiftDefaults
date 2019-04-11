//
//  ArrayValue.swift
//  Amber3Utils
//
//  Created by Larry Gensch on 3/20/19.
//  Copyright © 2019 Larry Gensch. All rights reserved.
//

import Foundation

public extension SwiftDefaults {
    class ArrayValue<V, T> : TransformedValue<Array<V>?, Array<T>?>
    where T: NativeType {
        init?(key: String,
              defaults: SwiftDefaults,
              observer: ((String, Array<V>?)->Void)? = nil,
              elementEncoder : @escaping (V)->T?,
              elementDecoder : @escaping (T)->V?) {
            guard let proxy = NativeValue<Array<T>>(key: key, defaults: defaults) else {
                return nil
            }
            super.init(proxyClosure: { return proxy.erased() },
                       encoder: { (array) in array?.compactMap { (elem) in elementEncoder(elem) } },
                       decoder: { (array) in array?.compactMap { (elem) in elementDecoder(elem) } })
            self.observer = observer
            setupProxyObserver()
        }

        private func setupProxyObserver() {
            if let observer = observer {
                let value = self.value
                proxy.observer = { [weak self] (key, _) in
                    guard let self = self else { return }
                    observer(key, value)
                }
            } else {
                proxy.invalidate()
            }
        }
    }

}

public func << <V, T>(_ lhs: SwiftDefaults.ArrayValue<V, T>, _ rhs: [V])
    where T: SwiftDefaults.NativeType {
    lhs.value = rhs
}
