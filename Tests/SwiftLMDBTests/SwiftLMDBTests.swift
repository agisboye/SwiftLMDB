//
//  SwiftLMDBTests.swift
//  SwiftLMDBTests
//
//  Created by August Heegaard on 29/09/2016.
//  Copyright © 2016 August Heegaard. All rights reserved.
//

import XCTest
import Foundation
@testable import SwiftLMDB

class SwiftLMDBTests: XCTestCase {

    static let envPath: String = {

        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
        let envURL = tempURL.appendingPathComponent("SwiftLMDBTests/")
        
        do {
            try FileManager.default.createDirectory(at: envURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            XCTFail("Could not create DB dir: \(error)")
        }
        
        return envURL.path

    }()
    
    var envPath: String { return SwiftLMDBTests.envPath }
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        
    }
    
    override class func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()

        try? FileManager.default.removeItem(atPath: envPath)
        
    }
    
    // MARK: - Helpers
    private func createDatabase(named name: String, envFlags: Environment.Flags = [], dbFlags: Database.Flags = [.create]) -> Database {
        do {
            let environment = try Environment(path: envPath, flags: envFlags, maxDBs: 32)
            return try environment.openDatabase(named: name, flags: dbFlags)
        } catch {
            XCTFail(error.localizedDescription)
            fatalError()
        }
    }
    
    // Inserts a value and reads it back, verifying that the two values match.
    private func putGetValue<T>(value: T, key: String, in database: Database) where T: DataConvertible & Equatable {
        
        do {
            try database.put(value: value, forKey: key)
            let fetchedValue = try database.get(type: type(of: value), forKey: key)
            
            XCTAssertEqual(value, fetchedValue, "The returned value does not match the one that was set.")
            
        } catch {
            XCTFail(error.localizedDescription)
            fatalError()
        }
        
    }
    
    
    // MARK: - Tests
    
    func testGetLMDBVersion() {
        XCTAssert(SwiftLMDB.version != (0, 0, 0), "Unable to get LMDB major version.")
    }
    
    func testCreateEnvironment() {
        
        do {
            _ = try Environment(path: envPath, flags: [], maxDBs: 32, maxReaders: 126, mapSize: 10485760)
        } catch {
            XCTFail(error.localizedDescription)
            return
        }
        
    }
    
    func testCreateUnnamedDatabase() {
        
        do {
            let environment = try Environment(path: envPath, flags: [], maxDBs: 32)
            _ = try environment.openDatabase(named: nil, flags: [.create])
        } catch {
            XCTFail(error.localizedDescription)
            return
        }

    }
    
    func testHasKey() {
        
        let database = createDatabase(named: #function)

        let value = "Hello world!"
        let keyWithValue = "hv1"
        let keyWithoutValue = "hv2"
        
        do {
            try database.put(value: value, forKey: keyWithValue)
            
            let hasValue1 = try database.exists(key: keyWithValue)
            let hasValue2 = try database.exists(key: keyWithoutValue)
            
            XCTAssertEqual(hasValue1, true, "A value has been set for this key. Result should be true.")
            XCTAssertEqual(hasValue2, false, "No value has been set for this key. Result should be false.")
        } catch {
            XCTFail(error.localizedDescription)
        }
        
    }
    
    func testPutGet() {
        
        let database = createDatabase(named: #function)
        
        // Key generating sequence
        var seq = sequence(first: 0, next: { $0 + 1 })
        let nextKey = { "key-\(seq.next()!)" }
        
        // Boolean
        putGetValue(value: true, key: nextKey(), in: database)
        putGetValue(value: false, key: nextKey(), in: database)
        
        // String
        putGetValue(value: "ÆØÅ", key: nextKey(), in: database)
        putGetValue(value: "Hello world! 👋🏼", key: nextKey(), in: database)
        
        // Date
        putGetValue(value: Date(), key: nextKey(), in: database)
        
        // Integers
        putGetValue(value: Int.max, key: nextKey(), in: database)
        putGetValue(value: Int8.max, key: nextKey(), in: database)
        putGetValue(value: Int16.max, key: nextKey(), in: database)
        putGetValue(value: Int32.max, key: nextKey(), in: database)
        putGetValue(value: Int64.max, key: nextKey(), in: database)
        
        putGetValue(value: UInt.max, key: nextKey(), in: database)
        putGetValue(value: UInt8.max, key: nextKey(), in: database)
        putGetValue(value: UInt16.max, key: nextKey(), in: database)
        putGetValue(value: UInt32.max, key: nextKey(), in: database)
        putGetValue(value: UInt64.max, key: nextKey(), in: database)
        
        // Floats
        putGetValue(value: Float.leastNormalMagnitude, key: nextKey(), in: database)
        putGetValue(value: Double.leastNormalMagnitude, key: nextKey(), in: database)
        
    }
    
    func testGetNonExistant() {
        let database = createDatabase(named: #function)
        
        do {
            let value = try database.get(type: Data.self, forKey: "any-key")
            XCTAssertNil(value)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testCount() {
        
        let database = createDatabase(named: #function)

        let count = 10
        
        do {
            
            for i in 0..<count {
                try database.put(value: "value-\(i)", forKey: "key-\(i)")
            }
            
            XCTAssertEqual(count, database.count)
            
        } catch {
            XCTFail(error.localizedDescription)
        }
        
    }
    
    func testEmptyKey() {

        let database = createDatabase(named: #function)
        
        XCTAssertThrowsError(
            try database.put(value: "test", forKey: "")
        )

    }
    
    func testDelete() {
        
        let database = createDatabase(named: #function)
        let key = "deleteTest"
        
        do {
            // Put a value
            try database.put(value: "Hello world!", forKey: key)
            
            // Delete the value.
            try database.deleteValue(forKey: key)
            
            // Get the value
            let retrievedData = try database.get(type: Data.self, forKey: key)
            XCTAssertNil(retrievedData, "Value still present after delete.")
        } catch {
            XCTFail(error.localizedDescription)
        }

    }
    
    func testDropDatabase() {
        
        let environment: Environment
        var database: Database!
        
        // Open a new database, creating it in the process.
        do {
            environment = try Environment(path: envPath, flags: [], maxDBs: 32)
            database = try environment.openDatabase(named: "dropTest", flags: [.create])
        } catch {
            XCTFail(error.localizedDescription)
            return
        }
        
        // Close the database and drop it.
        do {
            
            // Drop the database and get rid of the reference, so that the handle is closed.
            try database.drop()
            database = nil

        } catch {
            XCTFail(error.localizedDescription)
            return
        }
        
        // Attempt to open a database with the same name. We aren't passing in the .create flag, so this action should fail, indicating that the database was dropped successfully.
        do {
            database = try environment.openDatabase(named: #function)
        } catch {

            // The desired outcome is that the database is not found.
            if let lmdbError = error as? LMDBError {
                
                switch lmdbError {
                case .notFound: return
                default: break
                }
                
            }
            
            XCTFail(error.localizedDescription)
            return
            
        }
        
        XCTFail("The database was not dropped.")
        return
        
    }
    
    func testEmptyDatabase() {
        
        let database = createDatabase(named: #function)
        
        let key = "test"
        do {
            // Put a value
            try database.put(value: "Hello world!", forKey: key)

            // Empty the database.
            try database.empty()
            
            // Get the value. We want the result to be nil, because the database was emptied.
            let retrievedData = try database.get(type: Data.self, forKey: key)
            XCTAssertNil(retrievedData, "Value still present after database being emptied.")
            
        } catch {
            XCTFail(error.localizedDescription)
            return
        }
        
    }
    
    func testReadOnlyDatabase() {
        
        let dbName = #function
        let value = "value"
        let key = "test"
        
        // Open database and add a value
        do {
            try autoreleasepool {
                let database = createDatabase(named: dbName)
                try database.put(value: value, forKey: key)
            }
        } catch {
            XCTFail(error.localizedDescription)
            fatalError()
        }
        
        // Open the database again as a read only database.
        do {
            let database = createDatabase(named: dbName, envFlags: [.readOnly])
            let fetchedValue = try database.get(type: type(of: value), forKey: key)
            
            XCTAssertEqual(fetchedValue, value)
            
            // Writing a value to a read-only database should fail.
            XCTAssertThrowsError(try database.put(value: "newValue", forKey: key))
            
        } catch {
            XCTFail(error.localizedDescription)
            fatalError()
        }
        
    }
    
    func testCursor() {
        
        let database = createDatabase(named: #function)

        let values = [
            "A": "1",
            "B": "2",
            "C": "3",
            "D": "4"
        ]
        
        // Insert test data
        do {
            try values.forEach { try database.put(value: $0.1, forKey: $0.0) }
        } catch {
            XCTFail(error.localizedDescription)
            fatalError()
        }
        
        for (k, v) in database {
            let key = String(data: k)!
            let value = String(data: v)!
            XCTAssertEqual(values[key], value)
        }
        
    }
    
    static var allTests : [(String, (SwiftLMDBTests) -> () throws -> Void)] {
        return [
            ("testGetLMDBVersion", testGetLMDBVersion),
            ("testCreateEnvironment", testCreateEnvironment),
            ("testCreateUnnamedDatabase", testCreateUnnamedDatabase),
            ("testHasKey", testHasKey),
            ("testPutGet", testPutGet),
            ("testEmptyKey", testEmptyKey),
            ("testDelete", testDelete),
            ("testDropDatabase", testDropDatabase),
            ("testEmptyDatabase", testEmptyDatabase),
            ("testReadOnlyDatabase", testReadOnlyDatabase)
        ]
    }

    
}
