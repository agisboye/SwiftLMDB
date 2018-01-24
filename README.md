
SwiftLMDB is an opinionated wrapper around the [LMDB](https://symas.com/products/lightning-memory-mapped-database/) key/value database.

The wrapper abstracts away the C API and some of its concepts. Instead you get a clean Swift API that makes it easy to store arbitrary values in a fast and embedded database.

The only requirement is that key and value can be converted to `Data`. To assert this, keys and values must conform to the `DataConvertible` protocol. 
Lots of types are supported out of the box, without you having to implement anything.

## Features

- [x] Small and lightweight
- [x] Fast
- [x] Unit tested
- [x] Xcode documentation
- [x] Cross platform

SwiftLMDB has been tested on iOS and macOS, however it should also run on Linux. Feel free to test it out.

## Requirements

- iOS 8.0+ or macOS 10.10+
- Swift 3.0+


## Installation

### Carthage
To integrate LMDB into your Xcode project using [Carthage](https://github.com/Carthage/Carthage), specify it in your `Cartfile`:

```ogdl
github "agisboye/SwiftLMDB"
```

Run `carthage update` to build the framework and drag `SwiftLMDB.framework` into your Xcode project.


## Usage

Start by importing the module.
```swift
import SwiftLMDB
```

### Creating a database
Databases are contained within an environment. An environment may contain multiple databases, each identified by their name.
```swift
let environment: Environment
let database: Database

do {
    // The folder in which the environment is opened must already exist.
    try FileManager.default.createDirectory(at: envURL, withIntermediateDirectories: true, attributes: nil)

    environment = try Environment(path: envURL.path, flags: [], maxDBs: 32)
    database = try environment.openDatabase(named: "db1", flags: [.create])

} catch {
    print(error)
}

```

### Put a value

Any value conforming to `DataConvertible` can be inserted with any key conforming to `DataConvertible`.


```swift
do {
    try database.put(value: "Hello world!", forKey: "key1")
} catch {
    print(error)
}
```

### Get a value

When you need to get back a value from the database, you specify the expected type (the type of the value you put in) and the key.
This returns an optional of the type that you specify.

```swift
do {
    if let value = try database.get(type: String.self, forKey: "key1") { // String?
        // String
    }
} catch {
    print(error)
}
```

### Delete a value


```swift
do {
    try database.deleteValue(forKey: "key1")
} catch {
    print(error)
}
```


## Contributing

Contributions are very welcome. Open an issue or submit a pull request.


## License
SwiftLMDB is available under the MIT license. See the LICENSE file for more info.
LMDB is licensen under the [OpenLDAP Public License](http://www.openldap.org/software/release/license.html).
