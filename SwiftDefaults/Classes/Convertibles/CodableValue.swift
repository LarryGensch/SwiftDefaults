//
//  CodableValue.swift
//  Amber3Utils
//
//  Created by Larry Gensch on 3/16/19.
//  Copyright © 2019 Larry Gensch. All rights reserved.
//

import Foundation

public extension SwiftDefaults {
	static var jsonEncoder : JSONEncoder = {
		return JSONEncoder()
	}()
	
	static var jsonDecoder : JSONDecoder = {
		return JSONDecoder()
	}()
	
	static func codableConverter<T>(_ type: T.Type) -> ValueConverter<T, Data>
		where T: Codable {
			return ValueConverter<T, Data>(
				encoder: {
					do {
						return try SwiftDefaults
							.jsonEncoder
							.encode($0)
					} catch {
						assert(false, "Encoding error: \(error)")
					}
			},
				decoder: {
					do {
						return try SwiftDefaults
							.jsonDecoder
							.decode(T.self, from: $0)
					} catch {
						assert(false, "Decoding error: \(error)")
					}
			})
	}
	
	class CodableValue<T> : ConvertibleProtocol
	where T: Codable {
		public typealias ValueType = T
		public typealias InternalType = Data
		
		public var native : Value<InternalType>
		public var converter: ValueConverter<ValueType, InternalType>
		public var observer: ((String, ValueType?) -> Void)?
		
		public init(key: String,
					defaults: SwiftDefaults,
					observer: ((String, T?)->Void)?) {
            native = Value<InternalType>(key: key,
                                         defaults: defaults)
			converter = SwiftDefaults.codableConverter(T.self)
			setupNativeObserver()
		}
	}
	
	func convertible<T>(for type: T.Type,
						key: String,
						observer: ((String, T?)->Void)? = nil) -> CodableValue<T>
		where T: Codable {
			return CodableValue<T>(key: key,
								defaults: self,
								observer: observer)
	}
	
	func codableArray<T>(for type: T.Type,
						 key: String,
						 observer: ((String, Array<T>?)->Void)? = nil) -> ArrayValue<T, Data>
		where T: Codable {
			return ArrayValue<T, Data>(
				key: key,
				defaults: self, 
				eConverter: SwiftDefaults.codableConverter(T.self),
				observer: observer)
	}
}

public func << <T>(lhs: SwiftDefaults.CodableValue<T>,
                   rhs: T) {
	lhs.value = rhs
}
