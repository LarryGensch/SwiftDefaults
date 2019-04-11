//
//  CodableValue.swift
//  Amber3Utils
//
//  Created by Larry Gensch on 3/16/19.
//  Copyright © 2019 Larry Gensch. All rights reserved.
//

import Foundation

/// For creating custom coders (like JSONEncoder, JSONDecoder, etc.)
public protocol _SwiftDefaultsCoder {
    func encode<T: Codable>(_ value: T) throws -> Data
    func decode<T: Codable>(_ type: T.Type, from data: Data) throws -> T
}

public extension SwiftDefaults {
    typealias Coder = _SwiftDefaultsCoder

    /// Future: Will be used to allow users to create their own customer encoder
    typealias Encoder<T:Codable> = (_ value: T) throws -> Data
    /// Future: Will be used to allow users to create their own customer decoder
    typealias Decoder<T:Codable> = (_ type: T.Type, _ data: Data) throws -> T

    /// The default JSON encoder used by `CodableValue`
    /// This value is publically accessible in case any customization
    /// needs to be done for JSON encoding
	static var jsonEncoder : JSONEncoder = {
		return JSONEncoder()
	}()
	
    /// The default JSON decoder used by `CodableValue`
    /// This value is publically accessible in case any customization
    /// needs to be done for JSON decoding
	static var jsonDecoder : JSONDecoder = {
		return JSONDecoder()
	}()

    /// The default property list decoder used by `CodableValue`
    /// This value is publically accessible in case any customization
    /// needs to be done for property list encoding
    static var pListEncoder : PropertyListEncoder = {
        return PropertyListEncoder()
    }()

    /// The default property list decoder used by `CodableValue`
    /// This value is publically accessible in case any customization
    /// needs to be done for property list decoding
    static var pListDecoder : PropertyListDecoder = {
        return PropertyListDecoder()
    }()


    /// Type of coding for serializing `Codable` into `UserDefaults`
    ///
    /// - json: Use the Swift JSON encoder
    /// - pList: Use the Swift Property List encoder
    /// - other: Use a user-supplied coder (that conforms to `Coder`)
    /// - custom: Supply closures
    enum CoderType<T: Codable> {
        case json, pList
        // Following are untested...
//        case custom(encoder: Encoder<T>, decoder: Decoder<T>)
//        case other(coder: Coder)

        /// - Returns: The encoder associated with this coder type
        var encode : Encoder<T> {
            switch self {
            case .json:
                return SwiftDefaults.jsonEncoder.encode
            case .pList:
                return SwiftDefaults.pListEncoder.encode
//            case .custom(let encoder, _):
//                return encoder
//            case .other(let coder):
//                return coder.encode
            }
        }

        /// - Returns: The decoder associated with this coder type
        var decode : Decoder<T> {
            switch self {
            case .json:
                return SwiftDefaults.jsonDecoder.decode
            case .pList:
                return SwiftDefaults.pListDecoder.decode
//            case .custom(_, let decoder):
//                return decoder
//            case .other(let coder):
//                return coder.decode
            }
        }
    }

    /// A `Value` type that transforms a `Codable` value to `Data` that can be stored
    /// in `UserDefaults`
    class CodableValue<T: Codable> : TransformedValue<T?, Data?> {
        /// The type of coder to use to serialize to/from the Codable
        public let coderType : CoderType<T>


        /// Initializer
        ///
        /// - Parameters:
        ///   - key: The key associated with the `UserDefaults` value to be stored
        ///   - defaults: The `SwiftDefaults` instance to use
        ///   - coderType: The type of coder to use to serialize between Codable and Data.
        /// Defaults to .json
        ///   - observer: An observer to call when the value associated with the key changes
        init?(key: String,
              defaults: SwiftDefaults,
              coderType: CoderType<T> = .json,
              observer: ((String, T?)->Void)? = nil) {
            self.coderType = coderType
            guard let proxy = NativeValue<Data>(key: key, defaults: defaults) else {
                return nil
            }
            super.init(proxyClosure: {
                return proxy.erased()
            }, encoder: { (codable) in
                guard let codable = codable else { return nil }
                return try? coderType
                    .encode(codable)
            }, decoder: { (data) in
                guard let data = data else { return nil }
                return try? coderType
                    .decode(T.self, data)
            })
        }
	}
	
    func codableValue<T>(for type: T.Type,
                         key: String,
                         coderType: CoderType<T> = .json,
                         observer: ((String, T?)->Void)? = nil) -> CodableValue<T>?
		where T: Codable {
            return CodableValue<T>(key: key,
                                   defaults: self,
                                   coderType: coderType,
                                   observer: observer)
	}
	
	func codableArray<T>(for type: T.Type,
						 key: String,
                         coderType: CoderType<T> = .json,
						 observer: ((String, Array<T>?)->Void)? = nil) -> ArrayValue<T, Data>?
		where T: Codable {
			return ArrayValue<T, Data>(
				key: key,
				defaults: self,
                observer: observer,
                elementEncoder: { (codable) in
                    return try! coderType
                        .encode(codable)
            },
                elementDecoder: { (data) in
                    return try! coderType
                        .decode(T.self, data)
            })
	}
}

public func << <T: Codable>(_ lhs: SwiftDefaults.CodableValue<T>, _ rhs: T) {
    lhs.value = rhs
}
