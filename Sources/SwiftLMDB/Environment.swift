//
//  Environment.swift
//  SwiftLMDB
//
//  Created by August Heegaard on 30/09/2016.
//  Copyright © 2016 August Heegaard. All rights reserved.
//

import Foundation
import CLMDB

/// An environment is the base of LMDB.
/// It is opened at a path and may contain 0 or more databases.
public class Environment {
    
    public struct Flags: OptionSet {
        public let rawValue: Int32
        public init(rawValue: Int32) { self.rawValue = rawValue}
      
        public static let fixedMap = Flags(rawValue: MDB_FIXEDMAP)
        public static let noSubDir = Flags(rawValue: MDB_NOSUBDIR)
        public static let noSync = Flags(rawValue: MDB_NOSYNC)
        public static let readOnly = Flags(rawValue: MDB_RDONLY)
        public static let noMetaSync = Flags(rawValue: MDB_NOMETASYNC)
        public static let writeMap = Flags(rawValue: MDB_WRITEMAP)
        public static let mapAsync = Flags(rawValue: MDB_MAPASYNC)
        public static let noTLS = Flags(rawValue: MDB_NOTLS)
        public static let noLock = Flags(rawValue: MDB_NOLOCK)
        public static let noReadahead = Flags(rawValue: MDB_NORDAHEAD)
        public static let noMemoryInit = Flags(rawValue: MDB_NOMEMINIT)
    }
    
    internal private(set) var handle: OpaquePointer?
    
    /// Initializes a new environment instance. An environment may contain 0 or more databases.
    /// - parameter path: The path to the folder in which the environment should be created. The folder must exist and be writeable.
    /// - parameter flags: A set containing flags for the environment. See `Environment.Flags`
    /// - parameter maxDBs: The maximum number of named databases that can be opened in the environment. It is recommended to keep a "moderate amount" and not a "huge number" of databases in a given environment. Default is 0, preventing any named database from being opened.
    /// - parameter maxReaders: The maximum number of threads/reader slots. Default is 126.
    /// - parameter mapSize: The size of the memory map. The value should be a multiple of the OS page size. Default is 10485760 bytes. See http://104.237.133.194/doc/group__mdb.html#gaa2506ec8dab3d969b0e609cd82e619e5 for more.
    /// - throws: an error if operation fails. See `LMDBError`.
    public init(path: String, flags: Flags = [], maxDBs: UInt32? = nil, maxReaders: UInt32? = nil, mapSize: size_t? = nil) throws {

        // Prepare the environment.
        let envCreateStatus = mdb_env_create(&handle)
        
        guard envCreateStatus == 0 else {
            throw LMDBError(returnCode: envCreateStatus)
        }
        
        // Set the maximum number of named databases that can be opened in the environment.
        if let maxDBs = maxDBs {
            let envSetMaxDBsStatus = mdb_env_set_maxdbs(handle, MDB_dbi(maxDBs))
            guard envSetMaxDBsStatus == 0 else {
                throw LMDBError(returnCode: envSetMaxDBsStatus)
            }
        }
        
        // Set the maximum number of threads/reader slots for the environment.
        if let maxReaders = maxReaders {
            let envSetMaxReadersStatus = mdb_env_set_maxreaders(handle, maxReaders)
            guard envSetMaxReadersStatus == 0 else {
                throw LMDBError(returnCode: envSetMaxReadersStatus)
            }
        }
        
        // Set the size of the memory map.
        if let mapSize = mapSize {
            let envSetMapSizeStatus = mdb_env_set_mapsize(handle, mapSize)
            guard envSetMapSizeStatus == 0 else {
                throw LMDBError(returnCode: envSetMapSizeStatus)
            }
        }
        
        // Open the environment.
        let DEFAULT_FILE_MODE: mode_t = S_IRWXU | S_IRGRP | S_IXGRP | S_IROTH | S_IXOTH // 755

        // TODO: Let user specify file mode
        let envOpenStatus = mdb_env_open(handle, path.cString(using: .utf8), UInt32(flags.rawValue), DEFAULT_FILE_MODE)

        guard envOpenStatus == 0 else {
            // Close the environment handle.
            mdb_env_close(handle)
            
            throw LMDBError(returnCode: envOpenStatus)
        }
        
    }
    
    deinit {
        // Close the handle when environment is deallocated.
        mdb_env_close(handle)
    }

    /// Opens a database in the environment.
    /// - parameter name: The name of the database or `nil` if the unnamed/anonymous database in the environment should be used.
    /// - note: The parameter `maxDBs` supplied when instantiating the environment determines how many named databases can be opened inside the environment.
    /// - throws: an error if operation fails. See `LMDBError`.
    public func openDatabase(named name: String? = nil, flags: Database.Flags = []) throws -> Database {
        return try Database(environment: self, name: name, flags: flags)
    }
    
}
