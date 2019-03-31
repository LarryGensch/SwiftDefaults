# SwiftDefaults

A collection of classes and methods for Swift programs to access values in
`UserDefaults` using generics.

This framework supports `UserDefaults`'s "native" types (e.g., `Int`, `Double`, `UInt`, `Bool`, `String`, `Data`, `Date`, etc.) as allows converters to map between a given Swift value and these native types. Sample converters for enumerations, `Codable` values, and as well as `Array`s of such convertible values are supplied.

The benefits of using this framework:

* The use of generics ensures type safety... once you define a `Value` type and
give it a type, only (optional) values of the supplied type may be stored in a particular
value object.
* Proper KVO implementation ensures **all** changes to an object within a given
`UserDefaults` instance can call an optional closure so that the change can be
processed.

As this framework uses Swift generics, there is no bridging between this framework
and Objective C.

# Usage

## Instantiation

To use `SwiftDefaults`, you must first create an instance of the class, supplying an
instance of `UserDefaults` that you will be using for the setting and retrieval of values:

    let swiftDefaults = SwiftDefaults(.standard)

I chose to use this initializer rather than make the class a singleton. (Hooray for
anti-pattern nitpickers!) The class seems lightweight enough that having a bunch of
`SwiftDefaults` objects around shouldn't be a memory issue.

## Native types

There are certain types supported natively by `UserDefaults`. These are specified in
the documentation for `UserDefaults.set(_:forKey:)` as: `NSData`, `NSString`,
`NSNumber`, `NSDate`, `NSArray`, or `NSDictionary`. For `NSArray` and
`NSDictionary` objects, their contents must be property list objects. In addition, the
Swift values that are bridged to these types are also supported natively.

This framework defines the `SwiftDefauls.NativeType` protocol for those types that
are listed in the above paragraph.

For these native types, you can  instantiate the `SwiftDefaults.Value` with its type,
the `UserDefaults` instance to use,  the  `UserDefaults` key, and the observer (use
`nil` for no observer, or to set it afterward):

    let myValue = SwiftDefaults.Value<Int>(key: key,
                                           defaults: defaults,
                                           observer: nil)

Alternatively, you may use the `value(for:key:observer)` method in
`SwiftDefaults` as follows:

    // No observer:
    let  myValue = swiftDefaults.value(for: Int.self, key: "key")

    // With observer:
    let myValue = swiftDefaults.value(for: Int.self, key: "key") {
        print("Value changed for \($0): \(String(describing: $1))")
    }

Observers will be described in more detail in a subsequent section.

## Accessing and modifying the values

The `value` property of a `Value` object is used to access and set the `UserDefaults`
value for the associated `key`. You may also remove the key/value pair from
`UserDefaults` by setting the value to `nil` or calling the `remove()` method:

    myValue.value = 3   // Sets the UserDefaults "key" to Int(3)
    mvValue.value = nil // Removes the "key" from UserDefaults
    myValue.remove()    // Same as previous line
    myValue.value = "foo"   // Should not compile!

In addition, a C++-like `<<` overload is defined for all `Value` objects to set/reset
the values:

    myValue << 3        // Sets the UserDefaults "key" to Int(3)
    myValue << nil      // Removes the "key" from UserDefaults
    myValue << "foo"    // Should not compile!

As mentioned before, the `value` of a `Value` object is an optional value of the given
type. If the type of value stored in `UserDefaults` does not conform to the type of
the associated `Value` object, or if there is no `UserDefaults` value for the associated
key, its `value` will be nil.

### Shadow Values

It is simple to create two `Value` objects with the same `key`:

    let value1 = swiftDefaults.value(for: Int.self, key: "key")
    let value2 = swiftDefaults.value(for: Int.self, key: "key")

All `Value` objects for the same `key` must be created with the same `NativeType`.

    // This crashes at runtime
    let value3 = swiftDefaults.value(for: String.self, key: "key")

There is no way to change a `Value` object's type once it has been created.
However, you may call `destroy()` on that object to tell the framework to forget
its mapping of its `key` to its `ValueType`. Once a `Value` object is destroyed,
any access to that `Value` object, or any other existing object for the same `key`
will be invalidated (fatal error at runtime). If you create a new `Value` with the same
`key` as a destroyed value, the type of that `Value` will be associated with that key
until the next call to `destroy`.

    let value1 = swiftDefaults.value(for: Int.self, key: "key")
    
    // The next line fails with a runtime fatal error:
    // let value2 = swiftDefaults.value(for: UInt.self, key: "key")
    
    // The next line is valid, as it matches the type of value1:
    let value3 = swiftDefaults.value(for: Int.self, key: "key")
    
    // Forgets assignment, invalidates value1 AND value3:
    value3.destroy()
    
    // The next line fails; destroying value3 also destroys value1:
    value1.value = 3
    
    // Succeeds, and now maps "key" to UInt:
    let value4 = swiftDefaults.value(for: UInt.self, key: "key")
    
    // Fails, as "key" must now be UInt:
    // let value5 = swiftDefaults.value(for: Int.self, key: "key")

## Observers

Each `Value` may be linked to an optional observer closure that will be called whenever
the value changes within `UserDefaults` (no natter how the modification happens).

A value may change for any of the following reasons:

* The program may have modified the value, through any `Value` object associated
with that key
* The program modifies the value through calls to `UserDefaults.setValue(for:)`
* An external event caused the `UserDefaults` value to be modified or removed for
the associated key (eg., extensions, iOS settings app, etc.)

An observer may be attached to the `Value` object when it is created, or at any time
afterward by setting the `observer` value for the object:

    let myValue = swiftDefaults.value(for: Int.self,
                                      key: "key") {
        print("Value changed for \($0): \(String(describing: $1))")
    }
    myValue.observer = nil
    myValue.observer = { print("\($0) -> \($1)" }

Note that the `Value` object retains a strong reference to its observer which is released
at the following times:

* The `observer` value is set to `nil`
* The `observer` value is set to a new observer (an the object retains a strong reference to the new observer and releases the old observer)
* The `invalidate()` method is called
* When the object is deallocated

A reference cycle may prevent the object from deallocating properly, so it is usually
best to call the `invalidate` method to ensure that the strong reference to the
`observer` property doesn't prevent the `Value` object fro deallocating properly.

    myValue.observer = nil  // removes the observer
    myValue.invalidate()    // Same as previous statement

## Default Values

Since `UserDefaults` values are, by deinition, optional, the values themselves are
optional (if the value stored within `UserDefaults` is not found or a type that does not
match the type expected, the value is set to `nil`).

It is sometimes useful to "prime" `UserDefaults` with a default value, especially for
the first time your app is run. It also makes it easy for type safety not to have to
continuously unwrap the value as an optional.

The `SwiftDefaults.DefaultedValue` class can be used in those cases where
a `nil` value is just not wanted. The value can be created by specifying the default
value to be used in case the underlying `Value` type is nil:

    myDefaultValue = swiftDefaults.defaultValue("My string",
                                                for: "key")

This example will assign `myDefaultValue` as the `String` `UserDefaults` value
for the key "key". If there is no underlying value, or if the value stored in `UserDefaults`
is not a `String` property, the value "My string" will be used.

A `DefaultValue.value` is not optional; it will always have a value, and thus does
not need to be unwrapped.

    let foo = myDefaultValue.value // String, not String?

## Debugging

Simply printing the `Value` object will result in getting a string that describes the
`Value`:

    let myValue = swiftDefaults.value(for: Int.self, key: "key")
    print(myValue)  // Value<Int>(key: "key")

You can customize the debug description by using the `defaultDescription` variable:

    myValue.defaultDescription = "myValue<Int>"
    print(myValue)  // myValue<Int>

You can also get information from the `Value` object:

    print(myValue.key)  // prints the key associated with the object
    print(myValue.ValueType.self)   // The type of object being stored

# Converters/ConvertibleValues

A `Converter` is used to convert between some Swift type and a type natively
supported by `UserDefaults`. This needs to conform to the
`SwiftDefaults.Converter` protocol. A `ConvertibleValue` is a `Value`-like
object that uses an associated `Converter` as a proxy between the custom type and
the native type. There are three custom converters supplied directly by this framework:

## SwiftDefaults.enumConverter

This converter converts between an enumeration of whose `RawValue` maps to
a `NativeType`.

    enum Foo : String {
        case foo, bar
    }
    let myValue = swiftDefaults.convertible(for: Foo.self,
                                            key: "key")
    myValue << .bar
    print(myValue.value!)   // bar

    enum Bar {
        case foo, bar
    }
    // Next line doesn't compile, as the rawValue is unknown
    let myValue = swiftDefaults.convertible(for: Bar.self,
                                            key: "key1")
}

## SwiftDefaults.codableConverter

This converter converts between an object that conforms to the `Codable` protocol
and a `Data` object containing a JSON representation of the codable object.

    struct Foo : Codable, CustomStringConvertible {
        let a : Int
        let b: String
        var description : String {
            return "a:\(a), b:\(b)"
        }
    }
    let myValue = swiftDefaults.convertible(for: Foo.self,
                                            key: "key")
    myValue = Foo(a: 2, b: "Two!")
    print(myValue.value!)   // a:2, b:Two!

## SwiftDefaults.ArrayConverter

This converter can be used to convert an array of custom objects into an array of
types that are natively supported by `UserDefaults`. The mappings for `enumArray`
and `codableArray` are supplied directly by this framework.

    enum Foo : String {
        case foo, bar
        var description : String {
            return self.rawValue
        }
    }
    let myValue = swiftDefaults.arrayEnum(for: Foo.self,
                                          key: "key")
    myValue.value = [.bar, .foo]
    print(myValue.value!)   // [bar, foo]

## Custom converters

To create your own custom converter, simply create a static method in `SwiftDefaults`
that conforms to `SwiftDefaults.ValueConverter`:

    public extension SwiftDefaults {
        static func myCustomConverter<T>(_ type: T.Type) -> ValueConverter<T, N>
        where T: MyCustomType, N: NativeType {
            return ValueConverter<T, T.RawValue>(
                encoder: { /* convert $0 to N */ },
                decoder: { /* convert $0 to T */ }
            )
        }

You will need to code the actual conversion code into the `encoder` and `decoder`
closures.

* The `encoder` closure converts from your custom type to the native type to be stored
in `UserDefaults`
* The `decoder` closure converts from the native type stored in `UserDefaults` to
your custom type

## Creating a ConvertibleValue

Once you have the `ValueConverter` defined, you can add a new class within
`SwiftDefaults` to do the actual mapping:

    class MyCustomValue<T> : ConvertibleProtocol
    where T: MyCustomType {
        public typealias ValueType = T
        public typealias InternalType = N

        public var native : Value<InternalType>
        public var converter: ValueConverter<ValueType, InternalType>
        public var observer: ((String, ValueType?) -> Void)?

        public init(key: String,
                    defaults: defaults,
                    observer: ((String, T?)->Void)?) {
            native = Value<InternalType>(key: key,
                                         defaults: defaults)
            converter = SwiftDefaults.myCustomConverter(T.self)
            self.observer = observer
            setupNativeObserver()
        }
    }

In the example above, we need to instantiate the three variables used by `ConvertibleProtocol` and supply the `init` to give those variables their initial
values.

At the end of `init` call `setupNativeObserver` to provide the proxy mapping
between the native `Value` (which will receive the KVO events when the value changes)
and any observer supplied during initialization.

To make things just a bit easier, you can also create a factory method to create your
converter:

    extension SwiftDefaults {
        func convertible<T>(for type: T.Type,
                            key: String,
                            observer: ((String, T?)->Void)? = nil) -> MyCustomValue<T>
        where T: MyCustomType {
            return MyCustomValue<T>(key: key,
                                    defaults: defaults,
                                    observer: observer)
        }
    }

This allows you to simply create a `Value` type object for your custom type:

    let myCustomValue = swiftDefaults.convertible(
        for: MyCustomType.self,
        key: "myKey")

If you also wish to support the `<<` operator for directly assigning values, add the following (at the top level):

    public func << <T>(lhs: SwiftDefaults.MyCustomValue<T>, rhs: T) {
        lhs.value = rhs
    }
    myCustomValue << MyCustomType()

In addition, you can also allow support for arrays of your custom type, if desired:

    func myCustomTypeArray<T>(for type: T.Type,
                              key: String,
                              observer: ((String, Array<T>?)->Void)? = nil) -> ArrayValue<T, TheNativeType>
    where T: MyCustomType {
        return ArrayValue<T, TheNativeType>(
        key: key,
        defaults: defaults,
        eConverter: SwiftDefaults.myCustomConverter(T.self),
        observer: observer)
    }

In the examples above, replace `TheNativeType` with the actual type that will be stored
in `UserDefaults` (e.g., `String`, `Int`, `Data`, etc.).

# UserDefaults versus SwiftDefaults

When I originally created this code, I was adding classes within the `UserDefaults`
classes. I decided that polluting the namespace within `UserDefaults` wasn't a
great idea, especially as I added `Converters` and `ConvertibleValues`, so I created
the `SwiftDefaults` base class for this framework and put all the code within there.

# Future Directions (ideas)

* Add support for allowing multiple observers.
# Installation

This was never intended to be a standalone framework, but it currently works as such.
With a little effort, this could be improved to create "fat" frameworks instead of requiring
separate frameworks for each build configuration.

You can simply clone this `git` repository and use the framework generated in your
projects as you would any other framework.

An alternative way to use this code would be to simply copy the `Classes` folder
within the `SwiftDefaults` into your project, and not have to worry about including a
framework. (You might also want to include the `UserDefaults+Tests.swift` file in
your unit test suite as well...!)

# Credits

This framework was written by Larry Gensch and is provided to others to use and
possible improve. Specically, if you create and converters that would be useful for
others, please create a pull request!

# License

This code and tool is under the MIT License. See `LICENSE` file in this repository.

Any ideas and contributions welcome!
