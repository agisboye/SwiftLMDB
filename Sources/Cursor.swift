//
//  Cursor.swift
//  SwiftLMDB
//
//  Created by August Heegaard on 25/02/2020.
//

import Foundation
import LMDB

public class Cursor {
    
    internal private(set) var handle: OpaquePointer?
    
    private let database: Database
    private let transaction: Transaction
    private var first = true
    
    internal init(database: Database, transaction: Transaction) {
        self.database = database
        self.transaction = transaction
        mdb_cursor_open(transaction.handle, database.handle, &handle)
    }
    
    deinit {
        if let transactionHandle = mdb_cursor_txn(handle) {
            mdb_txn_commit(transactionHandle)
        }
        
        mdb_cursor_close(handle)
    }
    
}

extension Cursor: IteratorProtocol {
    
    public typealias Element = (key: Data, value: Data)

    public func next() -> Element? {
        
        guard handle != nil else { return nil }
        
        var keyVal = MDB_val()
        var dataVal = MDB_val()
        let operation: MDB_cursor_op = first ? MDB_FIRST : MDB_NEXT
        
        defer {
            first = false
        }

        let status = mdb_cursor_get(handle, &keyVal, &dataVal, operation)
        
        guard status == 0 else {
            return nil
        }
        
        let key = Data(bytes: keyVal.mv_data, count: keyVal.mv_size)
        let value = Data(bytes: dataVal.mv_data, count: dataVal.mv_size)
        
        return (key, value)

    }
    
}
