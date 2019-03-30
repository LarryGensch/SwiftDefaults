//
//  Value.swift
//  Amber3Utils
//
//  Created by Larry Gensch on 3/12/19.
//  Copyright © 2019 Larry Gensch. All rights reserved.
//

import Foundation

/// All SwiftDefaults.Value<T> and SwiftDefaults.ValueConverters<T>
/// conform to this generic protocol
public protocol _SwiftDefaultsValueProtocol
: AnyObject {
	associatedtype ValueType
	
	/// Signature for an observer to be called if/when the value is changed
	typealias Observer = (String, ValueType?)->Void
	
	/// The key used for storing the value in UserDefaults
	var key : String { get }
	
	/// The value associated with this class
	var value : ValueType? { get set }
	
    /// A description to use for debugging. If set, overrides
    /// default description used by eg. `print`.
    var defaultDescription : String? { get set }

	/// The observer to be notified if/when the `value` is changed
	var observer : Observer? { get set }
	
	/// Remove the value from UserDefaults (equivalent to setting
	/// the value to nil)
	func remove()
	
	/// Remove all references to the `observer`. After calling,
	/// no observer will be called if/when the value changes
	/// until a new `observer` is set for this object.
	func invalidate()
}

public extension _SwiftDefaultsValueProtocol {
    var baseDescription : String {
        let type = String(describing: ValueType.self)
        return "Value<\(type)>(key: \"\(key)\")"
    }
}

private var _context = UInt8(0)

public extension SwiftDefaults {
	typealias ValueProtocol = _SwiftDefaultsValueProtocol

	/// ValueProtocol implementation for UserDefaults keys with
	/// values that UserDefaults natively supports.
	class Value<T> : NSObject, ValueProtocol, TextOutputStreamable
    where T: NativeType {
		public typealias ValueType = T
		
		/// Key for value in UserDefaults
		public let key: String
		
		/// The value, get/set in UserDefaults
		public var value : ValueType? {
			get {
                guard !destroyed else {
                    fatalError("Attempt to use Value after destruction")
                }
				return defaults.value(forKey: key) as? T
			}
			set {
                guard !destroyed else {
                    fatalError("Attempt to use Value after destruction")
                }
				guard let newValue = newValue else {
					remove()
					return
				}
				defaults.set(newValue, forKey: key)
			}
		}

		/// The instance of UserDefaults to use
        public var defaults: UserDefaults {
            return swiftDefaults.defaults
        }
        private let swiftDefaults : SwiftDefaults
		
		/// An observer to call when changes are made to the value
        public var observer: Observer? {
            didSet {
                if isInvalid && (observer != nil) {
                    observer = nil
                }
            }
        }
        
        /// A description to use for debugging. If set, overrides
        /// default description used by eg. `print`.
        public var defaultDescription: String?
        
        /// Only used for testing
        public var isInvalid: Bool
        
        /// An optional description useful for debugging
		
		/// Initializer
		///
		/// - Parameters:
		///   - key: The UserDefaults key to use
		///   - defaults: The UserDefaults instance to use
		///   - observer: An optional observer to be called
		/// if/when the value changes
		public init(key: String,
					defaults: SwiftDefaults,
					observer: ((String, T?)->Void)? = nil) {
			self.key = key
			self.swiftDefaults = defaults
			self.observer = observer
            isInvalid = false
			super.init()
            do {
                try swiftDefaults.addValue(self)
            } catch {
                guard SwiftDefaults.isTesting else {
                    fatalError("\(error)")
                }
                print("NOT VALID: \(error)")
                isInvalid = true
                remove()
            }

			self.defaults.addObserver(self,
								 forKeyPath: key,
								 options: [.new],
								 context: &_context)
		}

		deinit {
			defaults.removeObserver(self,
									forKeyPath: key,
									context: &_context)
            swiftDefaults.removeValue(self)
		}
		
		public override func observeValue(
			forKeyPath keyPath: String?,
			of object: Any?,
			change: [NSKeyValueChangeKey : Any]?,
			context: UnsafeMutableRawPointer?) {
			guard keyPath == key,
				context == context else {
					super
						.observeValue(forKeyPath: key,
									  of: object,
									  change: change,
									  context: context)
					return
			}
			valueChanged()
		}
		
		private var _context = 0
		
		/// Remove the value from UserDefaults
		///
		/// Equivalent to setting the value to `nil`
		public func remove() {
			defaults.removeObject(forKey: key)
		}
		
		/// Invalid the observer
		public func invalidate() {
			observer = nil
		}
		
		func valueChanged() {
			observer?(key, value)
		}
        
        public func write<Target>(to target: inout Target) where Target : TextOutputStream {
            let desc = defaultDescription ?? baseDescription
            desc.write(to: &target)
        }
        
        private var destroyed = false
        
        func makeDestroyed() {
            defaultDescription = "** DESTROYED **"
            remove()
            invalidate()
            destroyed = true
            isInvalid = true
        }
        
        public func destroy() {
            swiftDefaults.destroyValue(self)
        }
    }
    
	func value<T: NativeType>(for type: T.Type,
							  key: String,
							  observer: Value<T>.Observer? = nil) -> Value<T> {
        return Value<T>(key: key,
                        defaults: self,
                        observer: observer)
	}
}

/// << overload for assigning values to Value<T> and ValueConverter<T>
///
/// - Parameters:
///   - lhs: The Value<T> or ValueConverter<T> whose value will be changed
///   - rhs: The new value to be assigned
public func << <T>(lhs: SwiftDefaults.Value<T>, rhs: T?) {
	lhs.value = rhs
}
