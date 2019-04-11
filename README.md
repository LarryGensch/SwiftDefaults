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

    let swiftDefaults = SwiftDefaults.defaults(for: .standard)

There is also a public initializer to create an instance of `SwiftDefaults` for a particular
`UserDefaults` instance.

    let swiftDefaults = SwiftDefaults(.standard)

Note, however, that separate `SwiftDefaults` instances
will not be aware of any others that are accessed, which means that if they
use the same `UserDefaults` instance, they may or may not react to changes
made in other `SwiftDefaults` instances. It is therefore strongly suggested to
use the `SwiftDefaults(for:)` method except for test purposes.

## ValueProtocol

All values in `SwiftDefaults` conform to the protocol `SwiftDefaults.ValueProtocol`.
There are specialized instances that can be used for various reasons:

* `NativeValue` - A value that can be natively stored in `UserDefaults`
* `TransformedValue` - A value that can be transformed into a type that can be natively
stored in `UserDefaults`
* `DefaultedValue` - A non-optional value that has a default value in case its value
is not found in `UserDefaults`

There are other specialized instances as well, and they will be described later.

Instances of objects conforming to `ValueProtocol` are referred to in this documentation
as `Value` objects (although there is no actual type called `Value` in this framework).

## NativeValue

There are certain data types supported natively by `UserDefaults`. These are specified in
the documentation for `UserDefaults.set(_:forKey:)` as: `NSData`, `NSString`,
`NSNumber`, `NSDate`, `NSArray`, or `NSDictionary`. For `NSArray` and
`NSDictionary` objects, their contents must be property list objects. In addition, the
Swift values that are bridged to these types are also supported natively.

This framework defines the `SwiftDefauls.NativeType` protocol for those types that
are listed in the above paragraph.

For these native types, you can  instantiate the `SwiftDefaults.Value` with its type,
the `SwiftDefaults` instance to use,  the  `UserDefaults` key, and the observer (use
`nil` for no observer, or to set it later):

    let myValue = SwiftDefaults.NativeValue<Int>(key: key,
                                                 defaults: defaults,
                                                 observer: nil)

Alternatively, you may use the `nativeValue(for:key:observer)` method using an
existing `SwiftDefaults` instance as follows:

    // No observer:
    let  myValue = swiftDefaults.nativeValue(for: Int.self, key: "key")

    // With observer:
    let myValue = swiftDefaults.nativeValue(for: Int.self, key: "key") {
        print("Value changed for \($0): \(String(describing: $1))")
    }

Observers will be described in more detail in a subsequent section.

All values for `NativeValue` objects are considered optional. If set to `nil`, the value is
removed from `UserDefaults`.

## Accessing and modifying the Value objects

The `value` property of a `Value` object is an optional that can be assigned
or retrieved. It is implemented using the `UserDefaults` methods to set and retrieve
values.

If you set a `value` property to `nil`, the effect will be to remove the value from
`UserDefaults`. The `remove()` method also will remove the object from
`UserDefaults`.

    myValue.value = 3   // Sets the UserDefaults "key" to Int(3)
    mvValue.value = nil // Removes the "key" from UserDefaults
    myValue.remove()    // Same as previous line
    myValue.value = "foo"   // Should not compile!

In addition, a C++-like `<<` overload is defined for all `Value` objects to set/reset
the values in a simpler way:

    myValue << 3        // Sets the UserDefaults "key" to Int(3)
    myValue << nil      // Removes the "key" from UserDefaults
    myValue << "foo"    // Should not compile!

As mentioned before, the `value` of a `Value` object is usually an optional value of the given
type, since the value may not actually exist in `UserDefaults`. The main exception to this
is in the case of `DefaultedValue` described later.

If the type of value stored in `UserDefaults` does not conform to the type of
the associated `Value` object, or if there is no `UserDefaults` value for the associated
key, its `value` will be nil.

### Shadow Values

It is simple to create two `Value` objects with the same `key`:

    let value1 = swiftDefaults.nativeValue(for: Int.self, key: "key")
    let value2 = swiftDefaults.nativeValue(for: Int.self, key: "key")

All `Value` objects for the same `key` within a given `SwiftDefaults` instance must be created with the
same `NativeType`. If a subsequent creation of a `Value` object is attempted with a different type,
the framework will generate a runtime exception.

    // This will crash at runtime
    let value3 = swiftDefaults.nativeValue(for: String.self, key: "key")

Generally, you should not change the value types of your `UserDefaults` objects. However, if you feel
that you really, really need to do so, there is a mechanism for doing just that.

Calling `destroy()` on a `Value` object to tell the `SwiftDefaults` instance to forget
its mapping of its `key` to its `ValueType`. Once a `Value` object is destroyed,
any access to that `Value` object, or any other existing object for the same `key`
will be invalidated (fatal error at runtime if you attempt to access its value).
If you create a new `Value` with the same `key` as a recently destroyed value, the type of that `Value` 
will be associated with that key until the next call to `destroy`.

    let value1 = swiftDefaults.value(for: Int.self, key: "key")
    
    // The next line will fail with a runtime fatal error if uncommented:
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

It is recommended to use the `destroy()` facility sparingly, if at all.

## Observers

Each `Value` may be linked to an optional observer closure that will be called whenever
the value changes within `UserDefaults` (no natter how the modification happens).

A value may change for any of the following reasons:

* The program may have modified the value, through any `Value` object associated
with that key
* The program modifies the value through calls to `UserDefaults.setValue(for:)`
whether through `SwiftDefaults` or any other code.
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
* The `observer` value is set to a new observer (the `Value` object retains a strong reference to the new observer
and releases the old observer)
* The `invalidate()` method is called
* When the object is deallocated, if no other strong references to the `observer` are held

A reference cycle may prevent the object from deallocating properly, so it is usually
best to call the `invalidate` method to ensure that the strong reference to the
`observer` property doesn't prevent the `Value` object fro deallocating properly.

    myValue.observer = nil  // removes the observer
    myValue.invalidate()    // Same as previous statement

Observers, by default, are scheduled on the main (UI) queue.

There may be some circumstances when observers should be scheduled on a different
thread. In that case, set the `observerQueue` on the `Value` object  to the desired
dispatch queue to use.

## DefaultedValue

Since `UserDefaults` values are, by deinition, optional, the values themselves are
optional (if the value stored within `UserDefaults` is not found or a type that does not
match the type expected, the value is set to `nil`).

It is sometimes useful to "prime" `UserDefaults` with a default value, especially for
the first time your app is run. It also makes it easy for type safety not to have to
unwrap the value as an optional.

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

## AnyValue

A special class `AnyValue` is available that takes a single generic parameter identifying the
`ValueType` associated with that `Value`. This can easily be created using the `erased()`
method of any `Value` object. This is especially useful when using `TransformedValue` objects
(see next section).

## TransformedValue

A `TransformedValue` is used to map between one type and another possibly-related type
for which a `Value` exists (such as a `NativeValue`). The `DefaultedValue` object uses this
very mechanism to supply a default value.

To create a `TransformedValue` you need to create a "proxy" object, which is an existing
`Value` object. The initializer for `TransformedValue` is as follows:

    init?<Transformed, ProxyType>(proxyClosure: ()->AnyValue<ProxyType>,
                                  observer: ((String, Transformed)->Void)? = nil,
                                  encoder: @escaping ((ValueType)->ProxyType),
                                  decoder: @escaping ((ProxyType)->ValueType))

The generic parameters are:
* Transformed - The `ValueType` for this `Value` object (visible to users of this `Value`)
* ProxyType - The `ValueType` of the proxy used by this object

The parameters in the initializer are:
* proxyClosure - A closure that returns the proxy object as an `AnyObject<T>` (use `Value.erased()`)
* observer: An optional observer to be notified of changes in the underlying `UserDefaults` value for the key
* encoder: A closure that will transform the `Transformed` value into the value associated with the proxy object
* decoder: A closure that will transform the `ProxyType` value from the proxy into the `Transformed` value for this object

## EnumValue

Built into the `SwiftDefaults` framework is a special `TransformedValue` that will transform a simple enumeration
that uses a `rawValue` that is natively supported by `UserDefaults` (such as `Integer` or `String`). The value of
this `Value` object is always `Optional` unless itself is transformed using `DefaultValue`.

Example:

    enum Foo : String {
        case foo, bar
    }
    guard let value = swiftDefaults.enumValue(for: Foo.self, key: "Foo") else {
        fatalError()
    }
    value << .foo
    print(value.value)      // "Optional(.foo)"
    value.value = .bar
    let b = value.value     // Equivalent: let b: Foo? = .bar
    value.value = nil
    guard let defaulted = SwiftDefaults.DefaultedValue(
        proxyClosure: { return value.erased() },
        defaultValue: .bar)
    print(defaulted.value)  // ".bar"
    defaulted << .foo
    print(defaulted.value)  // ".foo""

In the example above, the `value` is an `EnumValue` object that maps to the "key" value in `UserDefaults`.
It's value is optional, and so must be unwrapped in order to be used (in the example using variable b).
The value object is then transformed into a `DefaultedValue` using the value object as its proxy.
The value of defaulted is no longer optional. When the defaulted variable is created, the `value` proxy has
just been made nil, so the value is the default value, Since `value` is nil, the value reported is the non-optional
.bar value.

Note that since `defaulted.value` is not optional, it cannot be set to `nil`. To set the underlying `UserDefaults`
value to `nil` (removing it from `UserDefaults`), use `defaulted.remove()`. The resulting value for the `DefaultedValue`
object will be the default value after the `remove()` call.

## CodableValue

Since `Data` is a value natively supported by `UserDefaults`, the framework provides `CodableValue` which is used
to transform any object conforming to `Codable` into a value supported by `UserDefaults`.

    struct Foo : Equatable, Codable {
        var a : Int
        var b : String
    }

    let value = swiftDefaults.codableValue(for: Foo.self, key: "key"") 

    value << Foo(a: 1, b: "one")

The encoder/decoder used by `CodeableValue` transforms the object into a `Data` object using JSON (by default).

If you would prefer that the data stored in `UserDefaults` be stored as a property
list instead of a JSON object, you can use the `CoderType` enum:

    let value = swiftDefaults.codableValue(for: Foo.self,
                                           key: "key",
                                           coderType: .pList)

The `CoderType` enum allows you to specify JSON or Property List.
Hopefully, there will be support for user-supplied encoders and decoders.
The code has been written, but has not been tested, so it's currently commented
out until I have time to ensure the code actually works as designed.

## ArrayValue

The `ArrayValue` is a speial-purpose transformer that is used to map an array of values of a given type
to a corresponding array of values of a type natively supported by `UserDefaults`.
`SwiftDefaults` has methods to map enumerations and codable arrays in a manner
similar to that of `EnumValue` and `CodableValue`.

To create your own `ArrayValue` type, you would need to supply an `elementEncoder` and `elemewntDecoder`
closure to provide the mapping between the Swift values and the native values supported by `UserDefaults`.
An example of using `ArrayValue` is shown below, which is taken from the method `enumArray`:

    func enumArray<T>(for type: T.Type,
                      key: String,
                      observer: ((String, Array<T>?)->Void)? = nil) -> ArrayValue<T, T.RawValue>?
    where T: RawRepresentable, T.RawValue : NativeType {
        return ArrayValue<T, T.RawValue>(
            key: key,
            defaults: self,
            observer: observer,
            elementEncoder: {
                return $0.rawValue
            },
            elementDecoder: {
                return T(rawValue: $0)!
            })
    }

# Design Decisions

## UserDefaults versus SwiftDefaults

When I originally created this code, I was adding classes within the `UserDefaults`
classes. I decided that polluting the namespace within `UserDefaults` wasn't a
great idea, especially as I added more support for useful transformed values.

## Failable Initializers

When I initially wrote this framework, I used runtime errors when a `Value` object failed
to initialize properly. The only actual issue was that a `Value` would be created
that shadowed a previously created `Value` object with a different type. That was the
only failure mode. Addressing this with an `assert()` could bring up any issues in
development and allow clients to not worry about possible runtime errors happening
within the framework, or having to unwrap or attempt to catch exceptions when this
happened.

Truth be told, if you design your app properly, you shouldn't have to worry about this
except during development time, in which case you can trace the runtime exception
and fix the code before moving it into production.

However, this didn't seem like a "correct" thing to do.

The "right" thing would to indicate to the client that something went wrong, and
allow the client to decide how to handle the error.

There are two approaches to handling this from a framework's point of view:

1. Throw an exception indicating precisely what the error is so it can be reported
to the person that needs to know how to fix it
2. Make the initializer failable, and let the client know that _for some reason_, the
`Value` object could not be intantiated

The problem with the first approach is that each time you create a value, you need
to take into consideration that an exception may be thrown. That leads to verbose
code as the following:

    do {
        let myValue = try SwiftDefaults.NativeValue<Int>(key: key,
                                                         defaults: defaults,
                                                         observer: nil)
    } catch {
        // handle the exception
    }

That seems terribly verbose. However, that could be shortened to:

    let myValue = try! SwiftDefaults.NativeValue<Int>(key: key,
                                                      defaults: defaults,
                                                      observer: nil)

And we once again, have a runtime error.

Of course, changing the `try!` to a `try?` in the above example would allow us to use
optional chaining to, perhaps put the `let` statement into a `guard` or `if let`
clause.

I thought about this, and actually started to implement a rewrite using exceptions,
but I considered this overkill. Why? Because there was only one condition that would
cause the exception to be thrown: When a shadow `Value` object for a key was
associated with a differing type than the existing `Value` object for the same key.

Since there was only one failure mode, it made sense to me that instead of having
an initializer that throws an exception, simply use a failable initializer, which would
be equivalent to the `try?` for optional chaining:

    let myValue = SwiftDefaults.NativeValue<Int>(key: key,
                                                 defaults: defaults,
                                                 observer: nil)

Now, `myValue` is an optional `Value` object, and using `if let` or `guard let`, we
can handle the error, usually at development/test time. This simplifies the general
case.

Of course, if a future version of this framework presents a second failure option,
it might be a good idea to reconsider redesigning the framework to use exceptions
instead.

I'm willing to entertain other people's thoughts on the current design.

# Future Directions (ideas)

* Add support for allowing multiple observers for a single `Value` object
* Add test cases and enable user-defined coders for `CodableValue` when the code is ready
# Installation

This was never intended to be a standalone framework, but it currently works as such.
With a little effort, this could be improved to create "fat" frameworks instead of requiring
separate frameworks for each build configuration.

To use this framework with an existing project, here are the steps required:

1. Add `SwiftDefaults` as a submodule with:

        $ git submodule add <this-repository-url>

2. Open the `SwiftDefaults` folder, and drag the `.xcodeproj` file into your app's project. This needs to be added
somewhere within your target project to allow it to be accessible in your dependencies.

3. In your target's `Build Phases` panel, add the `SwifDefaults.framework` to the `Target Dependencies`

4. Add a `New Copy Files Phase` to your build phases, setting the `Destination` to "Frameworks" and add `SwiftDefaults.framework`

Alternatively, copy the `Classes` folder from this project into your sources, and rename it to `SwiftDefaults`
and build it from source as part of your target.

# Credits

This framework was written by Larry Gensch and is provided to others to use and
possible improve. Specically, if you create and converters that would be useful for
others, please create a pull request!

# License

This code and tool is under the MIT License. See `LICENSE` file in this repository.

Any ideas and contributions welcome!
