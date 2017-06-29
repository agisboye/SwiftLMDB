//
//  Transaction.swift
//  SwiftLMDB
//
//  Created by August Heegaard on 30/09/2016.
//  Copyright © 2016 August Heegaard. All rights reserved.
//

import Foundation
import CLMDB

/// All read and write operations on the database happen inside a Transaction.
public struct Transaction {
    
    public enum Action {
        case abort, commit
    }
    
    public struct Flags: OptionSet {
        public let rawValue: Int32
        public init(rawValue: Int32) { self.rawValue = rawValue}
        
        public static let readOnly = Flags(rawValue: MDB_RDONLY)
    }
    
    internal private(set) var handle: OpaquePointer?
    
    /// Creates a new instance of Transaction and runs the closure provided.
    /// Depending on the result returned from the closure, the transaction will either be comitted or aborted.
    /// If an error is thrown from the transaction closure, the transaction is aborted.
    /// - parameter environment: The environment with which the transaction will be associated.
    /// - parameter parent: Transactions can be nested to unlimited depth. (WARNING: Not yet tested)
    /// - parameter flags: A set containing flags modifying the behavior of the transaction.
    /// - parameter closure: The closure in which database interaction should occur. When the closure returns, the transaction is ended.
    /// - throws: an error if operation fails. See `LMDBError`.
    @discardableResult
    internal init(environment: Environment, parent: Transaction? = nil, flags: Flags = [], closure: ((Transaction) throws -> Transaction.Action)) throws {
        
        // http://lmdb.tech/doc/group__mdb.html#gad7ea55da06b77513609efebd44b26920
        let txnStatus = mdb_txn_begin(environment.handle, parent?.handle, UInt32(flags.rawValue), &handle)
        
        guard txnStatus == 0 else {
            throw LMDBError(returnCode: txnStatus)
        }

        // Run the closure inside a do/catch block, so we can abort the transaction if an error is thrown from the closure.
        do {
            let transactionResult = try closure(self)
            
            switch transactionResult {
            case .abort:
                mdb_txn_abort(handle)
                
            case .commit:
                let commitStatus = mdb_txn_commit(handle)
                guard commitStatus == 0 else {
                    throw LMDBError(returnCode: commitStatus)
                }
                
            }
            
        } catch {
            mdb_txn_abort(handle)
            throw error
        }
        
    }
    
}
