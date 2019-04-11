//
//  TransformedValueProtocol.swift
//  SwiftDefaults
//
//  Created by Larry Gensch on 4/10/19.
//  Copyright © 2019 Larry Gensch. All rights reserved.
//

import Foundation

public protocol _SwiftDefaultsTransformedValueProtocol : SwiftDefaults.ValueProtocol {
    associatedtype ValueType
    associatedtype ProxyType

    var proxy : SwiftDefaults.AnyValue<ProxyType> { get }
}

public extension _SwiftDefaultsTransformedValueProtocol {
    var key: String {
        return proxy.key
    }
    var swiftDefaults: SwiftDefaults {
        return proxy.swiftDefaults
    }
    var defaults: UserDefaults {
        return proxy.defaults
    }

    var value: ValueType {
        get {
            guard !isDestroyed() else { fatalError("Destroyed!") }
            return _getter()
        }
        set {
            guard !isDestroyed() else { fatalError("Destroyed!") }
            _setter(newValue)
        }
    }
    
    func isDestroyed() -> Bool {
        return proxy.isDestroyed()
    }

    func remove() {
        proxy.remove()
    }

    func invalidate() {
        observer = nil
    }

    func destroy() {
        proxy.destroy()
    }
}

public extension SwiftDefaults {
    typealias TransformedValueProtocol = _SwiftDefaultsTransformedValueProtocol

}
