//
//  ConvertibleProtocol.swift
//  Amber3Utils
//
//  Created by Larry Gensch on 3/16/19.
//  Copyright © 2019 Larry Gensch. All rights reserved.
//

import Foundation

public protocol _SwiftDefaultsConvertibleProtocol
: _SwiftDefaultsValueProtocol, TextOutputStreamable {
	associatedtype ValueType
	associatedtype InternalType : _SwiftDefaultsNativeType
	
	var native : SwiftDefaults.Value<InternalType> { get set }
	var converter : SwiftDefaults.ValueConverter<ValueType, InternalType> { get }
}

public extension _SwiftDefaultsConvertibleProtocol {
	var key: String {
		return native.key
	}
	var defaults: UserDefaults {
		return native.defaults
	}
	func remove() {
		native.remove()
	}
    func invalidate() {
		observer = nil
	}
	var value: ValueType? {
		get {
			guard let value = native.value else {
				return nil
			}
			return converter.decode(value)
		}
		set {
			guard let newValue = newValue else {
				native.remove()
				return
			}
			native.value = converter.encode(newValue)
		}
	}
    var isInvalid : Bool {
        return native.isInvalid
    }
    
    var defaultDescription: String? {
        get { return native.defaultDescription }
        set { native.defaultDescription = newValue }
    }
	
	func setupNativeObserver() {
		native.observer = { (key, _) in
			self.observer?(key, self.value)
		}
	}
}

public extension _SwiftDefaultsConvertibleProtocol {
    var baseDescription : String {
        let vType = String(describing: ValueType.self)
        let iType = String(describing: InternalType.self)
        
        return "Convertible<\(iType),\(vType)>(key: \"\(key)\")"
    }
    
    func write<Target>(to target: inout Target) where Target : TextOutputStream {
        let desc = defaultDescription ?? baseDescription
        desc.write(to: &target)
    }
}

public extension SwiftDefaults {
	typealias ConvertibleProtocol = _SwiftDefaultsConvertibleProtocol
}
