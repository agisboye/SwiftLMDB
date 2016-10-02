//
//  Database.swift
//  SwiftLMDB
//
//  Created by August Heegaard on 30/09/2016.
//  Copyright © 2016 August Heegaard. All rights reserved.
//

import Foundation
import LMDB

public class Database {
    
    public struct Flags: OptionSet {
        public let rawValue: Int32
        public init(rawValue: Int32) { self.rawValue = rawValue}
        
        static let reverseKey = Flags(rawValue: MDB_FIXEDMAP)
        static let duplicateSort = Flags(rawValue: MDB_NOSUBDIR)
        static let integerKey = Flags(rawValue: MDB_NOSYNC)
        static let duplicateFixed = Flags(rawValue: MDB_RDONLY)
        static let integerDuplicate = Flags(rawValue: MDB_NOMETASYNC)
        static let reverseDuplicate = Flags(rawValue: MDB_WRITEMAP)
        static let create = Flags(rawValue: MDB_CREATE)
    }
    
    /// These flags can be passed when putting values into the database.
    public struct PutFlags: OptionSet {
        public let rawValue: Int32
        public init(rawValue: Int32) { self.rawValue = rawValue}
        
        static let noDuplicateData = PutFlags(rawValue: MDB_NODUPDATA)
        static let noOverwrite = PutFlags(rawValue: MDB_NOOVERWRITE)
        static let reserve = PutFlags(rawValue: MDB_RESERVE)
        static let append = PutFlags(rawValue: MDB_APPEND)
        static let appendDuplicate = PutFlags(rawValue: MDB_APPENDDUP)
    }
    
    private var handle = UnsafeMutablePointer<MDB_dbi>.allocate(capacity: 1)
    private let environment: Environment
    
    /// - throws: an error if operation fails. See `LMDBError`.
    internal init(environment: Environment, name: String?, flags: Flags = []) throws {

        self.environment = environment
        
        try Transaction(environment: environment) { transaction -> Transaction.Result in

            let openStatus = mdb_dbi_open(transaction.handle, name?.cString(using: .utf8), UInt32(flags.rawValue), handle)
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
        mdb_dbi_close(environment.handle, handle.pointee)
        
        handle.deallocate(capacity: 1)
        
    }

    /// - throws: an error if operation fails. See `LMDBError`.
    public func get<V: DataConvertible, K: DataConvertible>(type: V.Type, forKey key: K) throws -> V? {

        let keyPointer = key.data.withUnsafeBytes { UnsafeMutableRawPointer(mutating: $0) }
        var keyVal = MDB_val(mv_size: key.data.count, mv_data: keyPointer)

        // The database will manage the memory for the returned value.
        // http://104.237.133.194/doc/group__mdb.html#ga8bf10cd91d3f3a83a34d04ce6b07992d
        let dataPointer = UnsafeMutablePointer<MDB_val>.allocate(capacity: 1)
        var getStatus: Int32 = 0

        try Transaction(environment: environment, flags: .readOnly) { transaction -> Transaction.Result in
            
            getStatus = mdb_get(transaction.handle, handle.pointee, &keyVal, dataPointer)
            return .commit
            
        }
        
        guard getStatus != MDB_NOTFOUND else {
            return nil
        }
        
        guard getStatus == 0 else {
            throw LMDBError(returnCode: getStatus)
        }
        
        let data = Data(bytes: dataPointer.pointee.mv_data, count: dataPointer.pointee.mv_size)
        
        return V(data: data)
        
    }
    
    public func hasValue<K: DataConvertible>(forKey key: K) throws -> Bool {
        return try get(type: Data.self, forKey: key) != nil
    }

    /// - parameter key: The key which the data will be associated with. Passing an empty string will cause an error.
    /// - throws: an error if operation fails. See `LMDBError`.
    public func put<V: DataConvertible, K: DataConvertible>(value: V, forKey key: K, flags: PutFlags = []) throws {

        let keyPointer = key.data.withUnsafeBytes { UnsafeMutableRawPointer(mutating: $0) }
        var keyVal = MDB_val(mv_size: key.data.count, mv_data: keyPointer)

        let valuePointer = value.data.withUnsafeBytes { UnsafeMutableRawPointer(mutating: $0) }
        var valueStructure = MDB_val(mv_size: value.data.count, mv_data: valuePointer)
        
        var putStatus: Int32 = 0
        
        try Transaction(environment: environment) { transaction -> Transaction.Result in
            
            putStatus = mdb_put(transaction.handle, handle.pointee, &keyVal, &valueStructure, UInt32(flags.rawValue))

            return .commit
            
        }
        
        guard putStatus == 0 else {
            throw LMDBError(returnCode: putStatus)
        }
        
    }

    /// - parameter key: The key identifying the database entry to be deleted. Passing an empty string will cause an error.
    /// - throws: an error if operation fails. See `LMDBError`.
    public func deleteValue<K: DataConvertible>(forKey key: K) throws {
        
        let keyPointer = key.data.withUnsafeBytes { UnsafeMutableRawPointer(mutating: $0) }
        var keyVal = MDB_val(mv_size: key.data.count, mv_data: keyPointer)
        
        try Transaction(environment: environment) { transaction -> Transaction.Result in

            mdb_del(transaction.handle, handle.pointee, &keyVal, nil)
            
            return .commit
            
        }

    }
    
//    public func batch(closure: ((Int, Int, Int) -> Transaction.Result)) throws {
//        
//        try Transaction(environment: <#T##Environment#>, closure: <#T##((Transaction) throws -> Transaction.Result)##((Transaction) throws -> Transaction.Result)##(Transaction) throws -> Transaction.Result#>)
//        
//    }
    
    /// Empties the database, removing all key/value pairs.
    /// The database remains open after being emptied and can still be used.
    /// - throws: an error if operation fails. See `LMDBError`.
    public func empty() throws {
        
        var dropStatus: Int32 = 0
        
        try Transaction(environment: environment, closure: { transaction -> Transaction.Result in
            dropStatus = mdb_drop(transaction.handle, handle.pointee, 0)
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
        
        try Transaction(environment: environment, closure: { transaction -> Transaction.Result in
            dropStatus = mdb_drop(transaction.handle, handle.pointee, 1)
            return .commit
        })
        
        guard dropStatus == 0 else {
            throw LMDBError(returnCode: dropStatus)
        }
        
    }

}
