//
//  ArrayValue.swift
//  Amber3Utils
//
//  Created by Larry Gensch on 3/20/19.
//  Copyright © 2019 Larry Gensch. All rights reserved.
//

import Foundation

public extension SwiftDefaults {
	class ArrayValue<V, T> : ConvertibleProtocol
	where T: NativeType {
		public typealias ValueType = Array<V>
		public typealias InternalType = Array<T>
		
		public var native: Value<Array<T>>
		
		public var converter: ValueConverter<Array<V>, Array<T>>
		
		public var observer: ((String, Array<V>?) -> Void)?

		init(key: String,
			 defaults: SwiftDefaults,
			 eConverter : ValueConverter<V, T>,
			 observer: ((String, Array<V>?)->Void)?) {
            native = Value<Array<T>>(key: key,
                                     defaults: defaults)
			converter = ValueConverter<Array<V>, Array<T>>(
				encoder: { (value)  in
					return value.map {eConverter.encode($0)! }
			}, decoder: { (value) in
				return value.map { eConverter.decode($0)! }
			})
			
			self.observer = observer
			setupNativeObserver()
		}
	}
}

public func << <V, T>(lhs: SwiftDefaults.ArrayValue<V, T>,
					  rhs: Array<V>) {
	lhs.value = rhs
}
