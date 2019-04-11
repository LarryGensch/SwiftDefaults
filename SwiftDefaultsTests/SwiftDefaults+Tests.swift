//
//  SwiftDefaults+Tests.swift
//  Amber3UtilsTests
//
//  Created by Larry Gensch on 3/5/19.
//  Copyright © 2019 Larry Gensch. All rights reserved.
//

import XCTest
import SwiftDefaults

private var saveKeyFound : Bool?
private var saveKeyRun = 0
private var swiftDefaults = SwiftDefaults(.standard)

class SwiftDefaults_Tests: XCTestCase {
    let ourKey = "###%%%@@@ test @@@%%%###"
    let saveKey = "Save This Key"
    let saveKeyValue = 2.0
    let defaults = swiftDefaults.defaults
    
    // Ensure tests start up with clean UserDefaults
    override func setUp() {
        print("SETUP()")
        swiftDefaults.destroyAll(except: [saveKey])
        SwiftDefaults.isTesting = true
    }
    
    override func tearDown() {
        print("TEARDOWN()")
        swiftDefaults.destroyAll(except: [saveKey])
    }
    
    func testAutoReset1() {
        guard let value = swiftDefaults.value(for: Int.self, key: ourKey) else {
            XCTFail()
            return
        }
        XCTAssertNil(value.value)
        value << 20
    }
    
    func testAutoReset2() {
        guard let value = swiftDefaults.value(for: String.self, key: ourKey) else {
            XCTFail()
            return
        }
        XCTAssertNil(value.value)
        value << "Foo"
    }
    
    /// Checks the "exceptions" argument to resetToDefault(except:)
    ///
    /// Note: Running this test multiple times should test whether the
    /// defaults are saved between runs
    func resetExceptTest() -> (Bool, String?) {
        saveKeyRun += 1
        if let value = defaults.value(forKey: saveKey) as? Double {
            if value == saveKeyValue {
                saveKeyFound = true
                print("Found saveKey on run #\(saveKeyRun)")
            }
            if value != saveKeyValue {
                return (false, "saveKeyValue \(value) != expected \(value)")
            }
        } else {
            defaults.set(saveKeyValue, forKey: saveKey)
        }
        if saveKeyRun == 3 {
            guard let _ = saveKeyFound else {
                return (false, "\(saveKey) not found after three runs!")
            }
            if arc4random_uniform(numericCast(2)) == 1 {
                defaults.removeObject(forKey: saveKey)
            }
        }
        return (true, nil)
    }
    
    func testResetExcept1() {
        let (rc, message) = resetExceptTest()
        XCTAssertTrue(rc, message ?? "No message!")
    }
    
    func testResetExcept2() {
        let (rc, message) = resetExceptTest()
        XCTAssertTrue(rc, message ?? "No message!")
    }
    
    func testResetExcept3() {
        let (rc, message) = resetExceptTest()
        XCTAssertTrue(rc, message ?? "No message!")
    }
    
    func nativeTest<T>(value: SwiftDefaults.NativeValue<T>,
                       value1: T,
                       value2: T,
                       value3: T)
        where T: Equatable {
            var count = 0
            let observer : (Any,Any)->Void = { (_, _) in
            XCTAssert(Thread.current.isMainThread)
                count += 1
            }
            XCTAssertEqual(value.key, ourKey)
            XCTAssertEqual(value.defaults, .standard)
            value.observer = observer
            value.value = value1
            XCTAssertEqual(value.value, value1)
            value.remove()
            XCTAssertNil(value.value)
            value << value2
            XCTAssertEqual(value.value, value2)
            value.invalidate()
            value << value3
            XCTAssertEqual(value.value, value3)
            waitForTimeout(1)
            XCTAssertEqual(count, 3)
    }
    
    func testUInt8() {
        guard let value = SwiftDefaults.NativeValue<UInt8>(
            key: ourKey,
            defaults: swiftDefaults,
            observer: nil) else {
                XCTFail()
                return
        }
        nativeTest(value: value,
                   value1: 0,
                   value2: 4,
                   value3: 200)
    }
    
    func testInt8() {
        guard let value = swiftDefaults
            .value(for: Int8.self,
                   key: ourKey) else {
                    XCTFail()
                    return
        }
        
        nativeTest(value: value,
                   value1: 0,
                   value2: -4,
                   value3: 120)
    }
    
    func testString() {
        guard let value = swiftDefaults
            .value(for: String.self,
                   key: ourKey) else {
                    XCTFail()
                    return
        }
        nativeTest(value: value,
                   value1: "This is a test",
                   value2: "Dang it!",
                   value3: "What the 😀😃😅")
    }
    
    func testDate() {
        guard let value = swiftDefaults
            .value(for: Date.self,
                   key: ourKey) else {
                    XCTFail()
                    return
        }
        nativeTest(value: value,
                   value1: Date(),
                   value2: Date(timeIntervalSince1970: 2000),
                   value3: Date(timeIntervalSince1970: 20000))
    }
    
    func testArray1() {
        let array1 = [ 1, 2, 3, 4, 5 ]
        let array2 = [ 1, 3, 5 ]
        let array3 = [ -2, -4 ]
        XCTAssertTrue(array1 is SwiftDefaults.NativeType)
        guard let value = swiftDefaults
            .value(for: type(of: array1),
                   key: ourKey) else {
                    XCTFail()
                    return
        }
        nativeTest(value: value,
                   value1: array1,
                   value2: array2,
                   value3: array3)
    }
    
    func testDict1() {
        let dict1 = [ "1" : 1, "2" : 2, "3" : 3 ]
        let dict2 = [ "key" : 4 ]
        let dict3 = [String:Int]()
        XCTAssertTrue(dict1 is SwiftDefaults.NativeType)
        guard let value = swiftDefaults
            .value(for: type(of: dict1),
                   key: ourKey) else {
                    XCTFail()
                    return
        }
        nativeTest(value: value,
                   value1: dict1,
                   value2: dict2,
                   value3: dict3)
    }
    
    func testStruct() {
        struct Foo : Equatable, Codable {
            var a : Int
            var b : String
        }
        let value1 = Foo(a: 1, b: "one")
        let value2 = Foo(a: 2, b: "two")
        let value3 = Foo(a: -5, b: "minus five")
        
        XCTAssertFalse(value1 is SwiftDefaults.NativeType)
        guard let value = swiftDefaults
            .codableValue(for: Foo.self, key: ourKey) else {
                XCTFail()
                return
        }
        var count = 0
        let observer : (Any,Any)->Void = { (_, _) in
            XCTAssert(Thread.current.isMainThread)
            count += 1
        }
        value.observer = observer
        XCTAssertEqual(value.key, ourKey)
        XCTAssertEqual(value.defaults, .standard)
        value.value = value1
        XCTAssertEqual(value.value, value1)
        value.value = nil
        XCTAssertNil(value.value)
        value << value2
        XCTAssertEqual(value.value, value2)
        value.invalidate()
        value << value3
        XCTAssertEqual(value.value, value3)
        waitForTimeout(1)
        XCTAssertEqual(count, 3)
    }
    
    func testEnum1() {
        enum Foo1 : String {
            case foo, bar
        }
        guard let value = swiftDefaults
            .enumValue(for: Foo1.self, key: ourKey) else {
                XCTFail()
                return
        }
        
        var count = 0
        let observer : (Any,Any)->Void = { (_, _) in
            XCTAssert(Thread.current.isMainThread)
            count += 1
        }
        value.observer = observer
        XCTAssertEqual(value.key, ourKey)
        XCTAssertEqual(value.defaults, .standard)
        value.value = .foo
        XCTAssertEqual(value.value, .foo)
        value.value = nil
        XCTAssertNil(value.value)
        value << .bar
        XCTAssertEqual(value.value, .bar)
        value.invalidate()
        value << .foo
        XCTAssertEqual(value.value, .foo)
        waitForTimeout(1)
        XCTAssertEqual(count, 3)
    }
    
    func testEnum2() {
        enum Foo1 : Int {
            case foo, bar
        }
        guard let value = swiftDefaults
            .enumValue(for: Foo1.self, key: ourKey) else {
                XCTFail()
                return
        }
        var count = 0
        let observer : (Any,Any)->Void = { (_, _) in
            XCTAssert(Thread.current.isMainThread)
            count += 1
        }
        value.observer = observer
        XCTAssertEqual(value.key, ourKey)
        XCTAssertEqual(value.defaults, .standard)
        value.value = .foo
        XCTAssertEqual(value.value, .foo)
        value.value = nil
        XCTAssertNil(value.value)
        value << .bar
        XCTAssertEqual(value.value, .bar)
        value.invalidate()
        value << .foo
        XCTAssertEqual(value.value, .foo)
        waitForTimeout(1)
        XCTAssertEqual(count, 3)
    }
    
    func testCodable1() {
        struct Foo : Codable, Equatable {
            var a: Int
            var b: String
        }
        guard let value = swiftDefaults
            .codableValue(for: Foo.self,
                          key: ourKey) else {
                            XCTFail()
                            return
        }
        var count = 0
        let observer : (Any,Any)->Void = { (_, _) in
            XCTAssert(Thread.current.isMainThread)
            count += 1
        }
        value.observer = observer
        XCTAssertEqual(value.key, ourKey)
        XCTAssertEqual(value.defaults, .standard)
        let value1 = Foo(a: 1, b: "one")
        value.value = value1
        XCTAssertEqual(value.value, value1)
        value.value = nil
        XCTAssertNil(value.value)
        let value2 = Foo(a: 2, b: "two")
        value << value2
        XCTAssertEqual(value.value, value2)
        value.invalidate()
        let value3 = Foo(a: -5, b: "minus five")
        value << value3
        XCTAssertEqual(value.value, value3)
        waitForTimeout(1)
        XCTAssertEqual(count, 3)
    }
    
    func testShadow() {
        guard let value = swiftDefaults
            .value(for: String.self, key: ourKey) else {
                XCTFail()
                return
        }
        guard let shadow = swiftDefaults
            .value(for: String.self, key: ourKey) else {
                XCTFail()
                return
        }
        let badShadow = swiftDefaults
            .value(for: Int.self, key: ourKey)
        XCTAssertNil(badShadow)
        badShadow?.observer = { (_,_) in  }
        XCTAssertNil(badShadow?.observer)
        
        var vCount = 0
        var sCount = 0
        value.observer = { (key, value) in
            vCount += 1
        }
        shadow.observer = { (key, value) in
            sCount += 1
        }
        XCTAssertEqual(value.key, ourKey)
        XCTAssertEqual(value.defaults, .standard)
        XCTAssertEqual(shadow.key, ourKey)
        XCTAssertEqual(shadow.defaults, .standard)
        value << "foo"
        XCTAssertEqual(value.value, "foo")
        XCTAssertEqual(shadow.value, "foo")
        shadow.remove()
        XCTAssertNil(value.value)
        shadow << "Bar"
        XCTAssertEqual(value.value, "Bar")
        XCTAssertEqual(shadow.value, "Bar")
        XCTAssertEqual(vCount, sCount)
        waitForTimeout(1)
        XCTAssertEqual(vCount, 3)
        shadow.destroy()
        XCTAssertTrue(shadow.isDestroyed())
        XCTAssertTrue(value.isDestroyed())
    }
    
    func testArrayEnumString() {
        enum Foo : String, CustomStringConvertible {
            case a, b, c, d, e
            var description: String {
                return self.rawValue
            }
        }
        var count = 0
        let observer : (Any,Any)->Void = { (_, _) in
            XCTAssert(Thread.current.isMainThread)
            count += 1
            print("Count is now \(count)")
        }
        
        let value1 : [Foo] = [ .a, .c, .e ]
        let value2 : [Foo] = [ .b, .d ]
        let value3 : [Foo] = [ .a, .b, .c, .d, .e ]
        
        guard let value = swiftDefaults
            .enumArray(for: Foo.self,
                       key: ourKey,
                       observer: observer) else {
                        XCTFail()
                        return
        }
        
        XCTAssertEqual(value.key, ourKey)
        XCTAssertEqual(value.defaults, .standard)
        value.value = value1
        XCTAssertEqual(value.value, value1)
        value.value = nil
        XCTAssertNil(value.value)
        value << value2
        XCTAssertEqual(value.value, value2)
        value.invalidate()
        value << value3
        XCTAssertEqual(value.value, value3)
        waitForTimeout(1)
        XCTAssertEqual(count, 3)
    }
    
    func testArrayEnumInt() {
        enum Foo : Int {
            case a, b, c, d, e
        }
        var count = 0
        let observer : (Any,Any)->Void = { (_, _) in
            XCTAssert(Thread.current.isMainThread)
            count += 1
        }
        
        let value1 : [Foo] = [ .a, .c, .e ]
        let value2 : [Foo] = [ .b, .d ]
        let value3 : [Foo] = [ .a, .b, .c, .d, .e ]
        
        guard let value = swiftDefaults
            .enumArray(for: Foo.self,
                       key: ourKey,
                       observer: observer) else {
                        XCTFail()
                        return
        }
        
        XCTAssertEqual(value.key, ourKey)
        XCTAssertEqual(value.defaults, .standard)
        value.value = value1
        XCTAssertEqual(value.value, value1)
        value.value = nil
        XCTAssertNil(value.value)
        value << value2
        XCTAssertEqual(value.value, value2)
        value.invalidate()
        value << value3
        XCTAssertEqual(value.value, value3)
        waitForTimeout(1)
        XCTAssertEqual(count, 3)
    }
    
    func testCodable() {
        struct Foo : Codable, Equatable {
            var a: Int
            var b: String
        }
        guard let value = swiftDefaults
            .codableArray(for: Foo.self,
                          key: ourKey) else {
                            XCTFail()
                            return
        }
        var count = 0
        let observer : (Any,Any)->Void = { (_, _) in
            XCTAssert(Thread.current.isMainThread)
            count += 1
        }
        value.observer = observer
        
        let value1 = [Foo(a: 1, b: "one"), Foo(a: 2, b: "two")]
        let value2 = [Foo(a: -1, b: "-1"), Foo(a: -2, b: "-2")]
        let value3 = [Foo(a: 200, b: "two hundred")]
        
        XCTAssertEqual(value.key, ourKey)
        XCTAssertEqual(value.defaults, .standard)
        value.value = value1
        XCTAssertEqual(value.value, value1)
        value.value = nil
        XCTAssertNil(value.value)
        value << value2
        XCTAssertEqual(value.value, value2)
        value.invalidate()
        value << value3
        XCTAssertEqual(value.value, value3)
        waitForTimeout(1)
        XCTAssertEqual(count, 3)
    }
    
    func testDefaultDescription1() {
        guard let value = swiftDefaults
            .value(for: Int.self, key: ourKey) else {
                XCTFail()
                return
        }
        
        let base1 = value.baseDescription
        let base2 = "\(value)"
        XCTAssertEqual(base1, base2)
        
        let override1 = "Value for \"\(ourKey)\""
        value.defaultDescription = override1
        let override2 = "\(value)"
        
        waitForTimeout(1)
        XCTAssertEqual(override1, override2)
    }
    
    func testDefaultDescription2() {
        enum Foo : String {
            case foo, bar
        }
        guard let value = swiftDefaults
            .enumValue(for: Foo.self, key: ourKey) else {
                XCTFail()
                return
        }
        
        let base1 = value.baseDescription
        let base2 = "\(value)"
        XCTAssertEqual(base1, base2)
        
        let override1 = "Convertible for \"\(ourKey)\""
        value.defaultDescription = override1
        let override2 = "\(value)"
        
        waitForTimeout(1)
        XCTAssertEqual(override1, override2)
    }

    func waitForTimeout(_ timeout: TimeInterval) {
        let timeExpectation = expectation(description: "Time!")
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
            timeExpectation.fulfill()
        }
        wait(for: [timeExpectation], timeout: timeout + 0.5)
    }

    func testDefaultedValue() {
        guard let value = swiftDefaults
            .defaultValue(Int(16), for: ourKey) else {
                XCTFail()
                return
        }
        var count = 0
        let observer : (Any,Any)->Void = { (_, _) in
            XCTAssert(Thread.current.isMainThread)
            count += 1
        }
        value.observer = observer
        let value1 = -20
        let value2 = 30
        let value3 = Int.max
        XCTAssertEqual(value.key, ourKey)
        XCTAssertEqual(value.defaults, .standard)
        value.value = value1
        XCTAssertEqual(value.value, value1)
        value << value2
        XCTAssertEqual(value.value, value2)
        value.invalidate()
        value << value3
        XCTAssertEqual(value.value, value3)
        waitForTimeout(1)
        XCTAssertEqual(count, 2)
    }

    /// Three levels of indirection:
    /// - NativeValue : String?
    /// - EnumValue : Foo?
    /// - DefaultedValue : Foo
    /// The observer must be called on the main thread
    func testObserverOnMainThread() {
        enum Foo : String {
            case foo, bar, zot
        }
        guard let proxy = swiftDefaults
            .enumValue(for: Foo.self, key: ourKey) else {
                XCTFail()
                return
        }
        var count = 0
        let observer : (Any,Any)->Void = { (_, _) in
            XCTAssert(Thread.current.isMainThread)
            count += 1
        }
        guard let value = swiftDefaults.defaulted(proxy: proxy.erased(), defaultValue: .zot) else {
            XCTFail()
            return
        }
        value.observer = observer
        let bgExpectation = expectation(description: "Background Thread")

        DispatchQueue.global(qos: .background).async {
            let value1 = Foo.bar
            let value2 = Foo.foo
            let value3 = Foo.zot
            XCTAssertEqual(value.key, self.ourKey)
            XCTAssertEqual(value.defaults, .standard)
            value.observer = observer
            value.value = value1
            XCTAssertEqual(value.value, value1)
            value << value2
            XCTAssertEqual(value.value, value2)
            value.invalidate()
            value << value3
            XCTAssertEqual(value.value, value3)
            bgExpectation.fulfill()
        }
        wait(for: [bgExpectation], timeout: 60)
        XCTAssertEqual(count, 2)
    }

    /// Three levels of indirection:
    /// - NativeValue : String?
    /// - EnumValue : Foo?
    /// - DefaultedValue : Foo
    /// The observer must be called on the main thread
    func testObserverOnBGThread() {
        enum Foo : String {
            case foo, bar, zot
        }
        guard let proxy = swiftDefaults
            .enumValue(for: Foo.self, key: ourKey) else {
                XCTFail()
                return
        }
        let bgQueue = DispatchQueue.global(qos: .background)

        var count = 0
        let observer : (Any,Any)->Void = { (_, _) in
            XCTAssertFalse(Thread.current.isMainThread)
            count += 1
        }
        guard let value = swiftDefaults.defaulted(proxy: proxy.erased(), defaultValue: .zot) else {
            XCTFail()
            return
        }
        value.observer = observer
        value.observerQueue = bgQueue
        let bgExpectation = expectation(description: "Background Thread")

        bgQueue.async {
            let value1 = Foo.bar
            let value2 = Foo.foo
            let value3 = Foo.zot
            XCTAssertEqual(value.key, self.ourKey)
            XCTAssertEqual(value.defaults, .standard)
            value.observer = observer
            value.value = value1
            XCTAssertEqual(value.value, value1)
            value << value2
            XCTAssertEqual(value.value, value2)
            value.invalidate()
            value << value3
            XCTAssertEqual(value.value, value3)
            bgExpectation.fulfill()
        }
        wait(for: [bgExpectation], timeout: 5)
        XCTAssertEqual(count, 2)
    }

    class MyCoder : SwiftDefaults.Coder {
        func encode<T>(_ value: T) throws -> Data where T : Encodable {
            // ...
        }

        func decode<T>(_ type: T.Type, from data: Data) throws -> T where T : Decodable {
            // ...
        }
    }

    func other() {
        struct Foo : Codable {
            var a: Int
            var b: String
        }
        let coderType = SwiftDefaults.CoderType.custom(encoder: { (value) -> Data in
            // ...
            return Data()
        },
                                                       decoder: { (type, data) -> Foo in
            // ...
            return Foo(a: 1, b: "")
        })
        let value = swiftDefaults
            .codableValue(for: Foo.self,
                          key: "key",
                          coderType: coderType)
    }
}
