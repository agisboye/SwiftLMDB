//
//  SwiftLMDBTests.swift
//  SwiftLMDBTests
//
//  Created by August Heegaard on 29/09/2016.
//  Copyright © 2016 August Heegaard. All rights reserved.
//

import XCTest
@testable import SwiftLMDB

class SwiftLMDBTests: XCTestCase {

    static let envPath: String = {
        
        let paths = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)
        let libraryURL = URL(fileURLWithPath: paths[0])
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
        let envURL = tempURL.appendingPathComponent("global/")
        
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
    
    func testGetLMDBVersion() {
        XCTAssert(SwiftLMDB.version != (0,0,0), "Unable to get LMDB version.")
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
        
        let environment: Environment
        let database: Database
        
        do {
            environment = try Environment(path: envPath, flags: [], maxDBs: 32)
            database = try environment.openDatabase(named: "db1", flags: [.create])
        } catch {
            XCTFail(error.localizedDescription)
            return
        }
        
        // Put a value
        let value = "Hello world!"
        let key = "hv1"
        
        do {
            try database.put(value: value, forKey: key)
        } catch {
            XCTFail(error.localizedDescription)
            return
        }
        
        // Get the value
        do {
            
            let hasValue1 = try database.hasValue(forKey: key)
            let hasValue2 = try database.hasValue(forKey: "hv2")
            
            XCTAssert(hasValue1 == true, "A value has been set for this key. Result should be true.")
            XCTAssert(hasValue2 == false, "No value has been set for this key. Result should be false.")
            
        } catch {
            XCTFail(error.localizedDescription)
            return
        }
        
    }
    
    func testPutGetString() {
        
        let environment: Environment
        let database: Database
        
        do {
            environment = try Environment(path: envPath, flags: [], maxDBs: 32)
            database = try environment.openDatabase(named: "db1", flags: [.create])
        } catch {
            XCTFail(error.localizedDescription)
            return
        }
        
        // Put a value
        let value = "Hello world!"
        let key = "hv1"
        
        do {
            try database.put(value: value, forKey: key)
        } catch {
            XCTFail(error.localizedDescription)
            return
        }
        
        // Get the value
        do {
            
            let hasValue1 = try database.hasValue(forKey: key)
            let hasValue2 = try database.hasValue(forKey: "hv2")
            
            XCTAssert(hasValue1 == true, "A value has been set for this key. Result should be true.")
            XCTAssert(hasValue2 == false, "No value has been set for this key. Result should be false.")
            
        } catch {
            XCTFail(error.localizedDescription)
            return
        }
        
    }
    
    func testEmptyKey() {

        let environment: Environment
        let database: Database

        do {
            environment = try Environment(path: envPath, flags: [], maxDBs: 32)
            database = try environment.openDatabase(named: "db1", flags: [.create])
            
            
            
        } catch {
            XCTFail(error.localizedDescription)
            return
        }
        
        // Put a value
        do {
            try database.put(value: "test", forKey: "")
        } catch {
            
            return
        }
        
        XCTFail("The put operation above is expected to fail.")

    }
    
    func testPutGetDouble() {
        
        let environment: Environment
        let database: Database
        
        do {
            environment = try Environment(path: envPath, flags: [], maxDBs: 32)
            database = try environment.openDatabase(named: "db1", flags: [.create])
        } catch {
            XCTFail(error.localizedDescription)
            return
        }
        
        // Put a value
        let value = 3.1415926536
        let key = "float"
        
        do {
            try database.put(value: value, forKey: key)
        } catch {
            XCTFail(error.localizedDescription)
            return
        }
        
        // Get the value
        do {
            guard let retrievedData = try database.get(type: Double.self, forKey: key) else {
                XCTFail("No value was found for the key.")
                return
            }
            
            XCTAssert(retrievedData == value, "The retrieved value is not the one that was set.")
            
        } catch {
            XCTFail(error.localizedDescription)
            return
        }
        
    }
    
    func testPutGetArray() {
        
        let environment: Environment
        let database: Database
        
        do {
            environment = try Environment(path: envPath, flags: [], maxDBs: 32)
            database = try environment.openDatabase(named: "db1", flags: [.create])
        } catch {
            XCTFail(error.localizedDescription)
            return
        }
        
        // Put a value
        let value: [String] = ["A", "BC", "DEF", "GHIJ"]
        let key = "array"
        
        do {
            try database.put(value: value, forKey: key)
        } catch {
            XCTFail(error.localizedDescription)
            return
        }
        
        // Get the value
        do {
            guard let retrievedData = try database.get(type: Array<String>.self, forKey: key) else {
                XCTFail("No value was found for the key.")
                return
            }

            XCTAssert(retrievedData == value, "The retrieved value is not the one that was set.")
            
        } catch {
            XCTFail(error.localizedDescription)
            return
        }
        
    }
    
    func testDelete() {
        
        let environment: Environment
        let database: Database
        
        do {
            environment = try Environment(path: envPath, flags: [], maxDBs: 32)
            database = try environment.openDatabase(named: "db1", flags: [.create])
        } catch {
            XCTFail(error.localizedDescription)
            return
        }
        
        // Put a value
        do {
            try database.put(value: "Hello world!", forKey: "deleteTest")
        } catch {
            XCTFail(error.localizedDescription)
            return
        }
        
        // Delete the value.
        do {
            try database.deleteValue(forKey: "deleteTest")
        } catch {
            XCTFail(error.localizedDescription)
            return
        }
        
        // Get the value
        do {
            let retrievedData = try database.get(type: Data.self, forKey: "deleteTest")
            
            XCTAssert(retrievedData == nil, "Value still present after delete.")

        } catch {
            XCTFail(error.localizedDescription)
            return
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
        
        // Attempt to open a database with the same name. We aren't passing in the .create flag, so this action should ideally fail, because it means that the database was dropped successfully.
        do {
            database = try environment.openDatabase(named: "dropTest")
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
        
        let environment: Environment
        var database: Database!
        
        // Open a new database, creating it in the process.
        do {
            environment = try Environment(path: envPath, flags: [], maxDBs: 32)
            database = try environment.openDatabase(named: "emptyTest", flags: [.create])
        } catch {
            XCTFail(error.localizedDescription)
            return
        }
        
        // Put a value
        let key = "test"
        do {
            try database.put(value: "Hello world!".data(using: .utf8)!, forKey: key)
        } catch {
            XCTFail(error.localizedDescription)
            return
        }
        
        // Empty the database.
        do {
            try database.empty()
        } catch {
            XCTFail(error.localizedDescription)
            return
        }
        
        // Get the value. We want the result to be nil, because the database was emptied.
        do {
            let retrievedData = try database.get(type: Data.self, forKey: key)
            
            XCTAssert(retrievedData == nil, "Value still present after database being emptied.")
            
        } catch {
            XCTFail(error.localizedDescription)
            return
        }
        
        
    }
    
}
