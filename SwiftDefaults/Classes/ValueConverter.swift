//
//  ValueConverter.swift
//  Amber3Utils
//
//  Created by Larry Gensch on 3/16/19.
//  Copyright © 2019 Larry Gensch. All rights reserved.
//

import Foundation

public extension SwiftDefaults {
	class ValueConverter<T, V>
	where V: NativeType {
		public var encoder: (ValueType) -> InternalType?
		public var decoder: (InternalType) -> ValueType?
		
		func encode(_ value: ValueType)->InternalType? {
			return encoder(value)
		}
		
		func decode(_ value: InternalType)->ValueType? {
			return decoder(value)
		}

		public typealias ValueType = T
		public typealias InternalType = V
		
		init(encoder: @escaping (ValueType) -> InternalType?,
			 decoder: @escaping (InternalType) -> ValueType?) {
			self.encoder = encoder
			self.decoder = decoder
		}
	}
}
