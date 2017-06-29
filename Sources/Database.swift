//
//  Database.swift
//  SwiftLMDB
//
//  Created by August Heegaard on 30/09/2016.
//  Copyright © 2016 August Heegaard. All rights reserved.
//

import Foundation
import CLMDB

/// A database contained in an environment.
/// The database can either be named (if maxDBs > 0 on the environment) or
/// it can be the single anonymous/unnamed database inside the environment.
public class Database {
    
    public struct Flags: OptionSet {
        public let rawValue: Int32
        public init(rawValue: Int32) { self.rawValue = rawValue}
        
        public static let reverseKey = Flags(rawValue: MDB_FIXEDMAP)
        public static let duplicateSort = Flags(rawValue: MDB_NOSUBDIR)
        public static let integerKey = Flags(rawValue: MDB_NOSYNC)
        public static let duplicateFixed = Flags(rawValue: MDB_RDONLY)
        public static let integerDuplicate = Flags(rawValue: MDB_NOMETASYNC)
        public static let reverseDuplicate = Flags(rawValue: MDB_WRITEMAP)
        public static let create = Flags(rawValue: MDB_CREATE)
    }
    
    /// These flags can be passed when putting values into the database.
    public struct PutFlags: OptionSet {
        public let rawValue: Int32
        public init(rawValue: Int32) { self.rawValue = rawValue}
        
        public static let noDuplicateData = PutFlags(rawValue: MDB_NODUPDATA)
        public static let noOverwrite = PutFlags(rawValue: MDB_NOOVERWRITE)
        public static let reserve = PutFlags(rawValue: MDB_RESERVE)
        public static let append = PutFlags(rawValue: MDB_APPEND)
        public static let appendDuplicate = PutFlags(rawValue: MDB_APPENDDUP)
    }
    
    private var handle: MDB_dbi = 0
    private let environment: Environment
    
    /// - throws: an error if operation fails. See `LMDBError`.
    internal init(environment: Environment, name: String?, flags: Flags = []) throws {

        self.environment = environment
        
        try Transaction(environment: environment) { transaction -> Transaction.Action in

            let openStatus = mdb_dbi_open(transaction.handle, name?.cString(using: .utf8), UInt32(flags.rawValue), &handle)
            guard openStatus == 0 else {
                throw LMDBError(returnCode: openStatus)
            }

            // Commit the open transaction.
            return .commit

        }

    }

    deinit {

        // Close the database.
        // http://lmdb.tech/doc/group__mdb.html#ga52dd98d0c542378370cd6b712ff961b5
        mdb_dbi_close(environment.handle, handle)

    }

    /// Returns a value from the database instantiated as type `V` for a key of type `K`.
    /// - parameter type: A type conforming to `DataConvertible` that you want to be instantiated with the value from the database.
    /// - parameter key: A key conforming to `DataConvertible` for which the value will be looked up.
    /// - returns: Returns the value as an instance of type `V` or `nil` if no value exists for the key or the type could not be instatiated with the data.
    /// - note: You can always use `Foundation.Data` as the type. In such case, `nil` will only be returned if there is no value for the key.
    /// - throws: an error if operation fails. See `LMDBError`.
    public func get<V: DataConvertible, K: DataConvertible>(type: V.Type, forKey key: K) throws -> V? {

        let keyPointer = key.data.withUnsafeBytes { UnsafeMutableRawPointer(mutating: $0) }
        var keyVal = MDB_val(mv_size: key.data.count, mv_data: keyPointer)

        // The database will manage the memory for the returned value.
        // http://104.237.133.194/doc/group__mdb.html#ga8bf10cd91d3f3a83a34d04ce6b07992d
        var dataVal = MDB_val()
        
        var getStatus: Int32 = 0

        try Transaction(environment: environment, flags: .readOnly) { transaction -> Transaction.Action in
            
            getStatus = mdb_get(transaction.handle, handle, &keyVal, &dataVal)
            return .commit
            
        }
        
        guard getStatus != MDB_NOTFOUND else {
            return nil
        }
        
        guard getStatus == 0 else {
            throw LMDBError(returnCode: getStatus)
        }
        
        let data = Data(bytes: dataVal.mv_data, count: dataVal.mv_size)

        return V(data: data)
        
    }
    
    /// Check if a value exists for the given key.
    /// - parameter key: The key to check for.
    /// - returns: `true` if the database contains a value for the key. `false` otherwise.
    /// - throws: an error if operation fails. See `LMDBError`.
    public func hasValue<K: DataConvertible>(forKey key: K) throws -> Bool {
        return try get(type: Data.self, forKey: key) != nil
    }

    /// Inserts a value into the database.
    /// - parameter value: The value to be put into the database. The value must conform to `DataConvertible`.
    /// - parameter key: The key which the data will be associated with. The key must conform to `DataConvertible`. Passing an empty key will cause an error to be thrown.
    /// - parameter flags: An optional set of flags that modify the behavior if the put operation. Default is [] (empty set).
    /// - throws: an error if operation fails. See `LMDBError`.
    public func put<V: DataConvertible, K: DataConvertible>(value: V, forKey key: K, flags: PutFlags = []) throws {

        let keyPointer = key.data.withUnsafeBytes { UnsafeMutableRawPointer(mutating: $0) }
        var keyVal = MDB_val(mv_size: key.data.count, mv_data: keyPointer)

        let valuePointer = value.data.withUnsafeBytes { UnsafeMutableRawPointer(mutating: $0) }
        var valueStructure = MDB_val(mv_size: value.data.count, mv_data: valuePointer)
        
        var putStatus: Int32 = 0
        
        try Transaction(environment: environment) { transaction -> Transaction.Action in
            
            putStatus = mdb_put(transaction.handle, handle, &keyVal, &valueStructure, UInt32(flags.rawValue))

            return .commit
            
        }
        
        guard putStatus == 0 else {
            throw LMDBError(returnCode: putStatus)
        }
        
    }

    /// Deletes a value from the database.
    /// - parameter key: The key identifying the database entry to be deleted. The key must conform to `DataConvertible`. Passing an empty key will cause an error to be thrown.
    /// - throws: an error if operation fails. See `LMDBError`.
    public func deleteValue<K: DataConvertible>(forKey key: K) throws {
        
        let keyPointer = key.data.withUnsafeBytes { UnsafeMutableRawPointer(mutating: $0) }
        var keyVal = MDB_val(mv_size: key.data.count, mv_data: keyPointer)
        
        try Transaction(environment: environment) { transaction -> Transaction.Action in

            mdb_del(transaction.handle, handle, &keyVal, nil)
            
            return .commit
            
        }

    }
    
    /// Empties the database, removing all key/value pairs.
    /// The database remains open after being emptied and can still be used.
    /// - throws: an error if operation fails. See `LMDBError`.
    public func empty() throws {
        
        var dropStatus: Int32 = 0
        
        try Transaction(environment: environment, closure: { transaction -> Transaction.Action in
            dropStatus = mdb_drop(transaction.handle, handle, 0)
            return .commit
        })
        
        guard dropStatus == 0 else {
            throw LMDBError(returnCode: dropStatus)
        }
        
    }

    /// Drops the database, deleting it (along with all it's contents) from the environment.
    /// - warning: Dropping a database also closes it. You may no longer use the database after dropping it.
    /// - seealso: `empty()`
    /// - throws: an error if operation fails. See `LMDBError`.
    public func drop() throws {
        
        var dropStatus: Int32 = 0
        
        try Transaction(environment: environment, closure: { transaction -> Transaction.Action in
            dropStatus = mdb_drop(transaction.handle, handle, 1)
            return .commit
        })
        
        guard dropStatus == 0 else {
            throw LMDBError(returnCode: dropStatus)
        }
        
    }

}
