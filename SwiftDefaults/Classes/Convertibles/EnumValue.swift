//
//  EnumValue.swift
//  Amber3Utils
//
//  Created by Larry Gensch on 3/16/19.
//  Copyright © 2019 Larry Gensch. All rights reserved.
//

import Foundation

public extension SwiftDefaults {
	static func enumConverter<T>(_ type: T.Type) -> ValueConverter<T, T.RawValue>
	where T: RawRepresentable, T.RawValue : NativeType {
		return ValueConverter<T, T.RawValue>(
			encoder: { $0.rawValue },
			decoder: { T(rawValue: $0)! })
	}
	
    /// Maps an enumeration whose `RawValue` conforms to `NativeType`
	class EnumValue<T> : ConvertibleProtocol
	where T: RawRepresentable, T.RawValue : NativeType {
		public typealias ValueType = T
		public typealias InternalType = T.RawValue

		public var native : Value<InternalType>
		public var converter: ValueConverter<ValueType, InternalType>
		public var observer: ((String, ValueType?) -> Void)?
		
		public init(key: String,
					defaults: SwiftDefaults,
					observer: ((String, T?)->Void)?) {
            native = Value<InternalType>(key: key,
                                         defaults: defaults)
			converter = SwiftDefaults.enumConverter(T.self)
			setupNativeObserver()
		}
	}
	
    func convertible<T>(for type: T.Type,
                        key: String,
                        observer: ((String, T?)->Void)? = nil) -> EnumValue<T>
		where T: RawRepresentable, T.RawValue : NativeType {
		return EnumValue<T>(key: key,
							defaults: self,
							observer: observer)
	}
	
	func enumArray<T>(for type: T.Type,
					  key: String,
					  observer: ((String, Array<T>?)->Void)? = nil) -> ArrayValue<T, T.RawValue>
		where T: RawRepresentable, T.RawValue : NativeType {
			return ArrayValue<T, T.RawValue>(
				key: key,
				defaults: self,
				eConverter: SwiftDefaults.enumConverter(T.self),
				observer: observer)
	}
}

public func << <T>(lhs: SwiftDefaults.EnumValue<T>,
                   rhs: T) {
	lhs.value = rhs
}
