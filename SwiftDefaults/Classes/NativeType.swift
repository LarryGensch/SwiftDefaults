//
//  NativeType.swift
//  Amber3Utils
//
//  Created by Larry Gensch on 3/9/19.
//  Copyright © 2019 Larry Gensch. All rights reserved.
//

import Foundation

/// Values that can be stored in UserDefaults:
public protocol _SwiftDefaultsNativeType { }

public extension SwiftDefaults {
	/// Values that can be stored natively in UserDefaults:
	typealias NativeType = _SwiftDefaultsNativeType
}

// NSNumber
extension Bool: SwiftDefaults.NativeType {}
extension CGFloat: SwiftDefaults.NativeType {}
extension Decimal: SwiftDefaults.NativeType {}
extension Double: SwiftDefaults.NativeType {}
extension Float: SwiftDefaults.NativeType {}
extension Float80: SwiftDefaults.NativeType {}
extension Int16: SwiftDefaults.NativeType {}
extension Int32: SwiftDefaults.NativeType {}
extension Int64: SwiftDefaults.NativeType {}
extension Int8: SwiftDefaults.NativeType {}
extension Int: SwiftDefaults.NativeType {}
extension NSNumber: SwiftDefaults.NativeType {}
extension ObjCBool: SwiftDefaults.NativeType {}
extension UInt16: SwiftDefaults.NativeType {}
extension UInt32: SwiftDefaults.NativeType {}
extension UInt64: SwiftDefaults.NativeType {}
extension UInt8: SwiftDefaults.NativeType {}
extension UInt: SwiftDefaults.NativeType {}

// NSString
extension NSString: SwiftDefaults.NativeType {}
extension String: SwiftDefaults.NativeType {}
extension Substring: SwiftDefaults.NativeType {}

// NSData
extension NSData: SwiftDefaults.NativeType {}
extension Data: SwiftDefaults.NativeType {}

// NSDate
extension NSDate: SwiftDefaults.NativeType {}
extension Date: SwiftDefaults.NativeType {}

// NSURL
extension NSURL: SwiftDefaults.NativeType {}
extension URL: SwiftDefaults.NativeType {}

#if swift(>=4.1)
// NSArray
extension Array: SwiftDefaults.NativeType
where Element: SwiftDefaults.NativeType {}

// NSDictionary
extension Dictionary: SwiftDefaults.NativeType
	where Key: SwiftDefaults.NativeType,
Value: SwiftDefaults.NativeType {}

// Optionals
extension Optional: SwiftDefaults.NativeType
where Wrapped: SwiftDefaults.NativeType {}

#endif

// Here Be Dragons...
// Technically, NSArray and NSDictionary are supported natively
// But only if their elements are all of the types listed below:
// * NSData
// * NSDate
// * NSNumber
// * NSString
// * NSNull (??)
//
// For completeness' sake, we mark these classes as _Amber3DefaultsNative
// but the programmer is responsible to ensure that this will work.
//
// For better support, use Swift's Array or Dictionary types instead
// (and use Swift 4.2 or higher)

extension NSArray : SwiftDefaults.NativeType {}
extension NSDictionary : SwiftDefaults.NativeType {}
