//
//  ValueProtocol.swift
//  SwiftDefaults
//
//  Created by Larry Gensch on 4/6/19.
//  Copyright © 2019 Larry Gensch. All rights reserved.
//

import Foundation

public protocol _SwiftDefaultsValueProtocol : class, TextOutputStreamable {
    associatedtype ValueType
    
    var key: String { get }
    var swiftDefaults: SwiftDefaults { get }
    
    var defaultDescription: String? { get set }
    var baseDescription: String { get }
    var observer: ((String, ValueType)->Void)? { get set }
    var observerQueue : DispatchQueue { get set }
    var value: ValueType { get set }
    
    var _getter : ()->ValueType { get }
    var _setter : (ValueType)->Void { get }
    
    func remove()
    func invalidate()
    func destroy()
    func isDestroyed() -> Bool
}

extension _SwiftDefaultsValueProtocol {
    public var defaults : UserDefaults {
        return swiftDefaults.defaults
    }
    
    public func write<Target>(to target: inout Target) where Target : TextOutputStream {
        let desc = defaultDescription ?? baseDescription
        desc.write(to: &target)
        
    }
    
    public var value : ValueType {
        get { return _getter() }
        set { _setter(newValue) }
    }
}

public extension SwiftDefaults {
    typealias ValueProtocol = _SwiftDefaultsValueProtocol
}

