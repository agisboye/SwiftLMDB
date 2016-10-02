//
//  Transaction.swift
//  SwiftLMDB
//
//  Created by August Heegaard on 30/09/2016.
//  Copyright © 2016 August Heegaard. All rights reserved.
//

import Foundation
import LMDB

public struct Transaction {
    
    public enum Result {
        case abort, commit
    }
    
    public struct Flags: OptionSet {
        public let rawValue: Int32
        public init(rawValue: Int32) { self.rawValue = rawValue}
        
        static let readOnly = Flags(rawValue: MDB_RDONLY)
    }
    
    internal private(set) var handle: OpaquePointer?
    
    @discardableResult
    internal init(environment: Environment, parent: Transaction? = nil, flags: Flags = [], closure: ((Transaction) throws -> Transaction.Result)) throws {
        
        // http://lmdb.tech/doc/group__mdb.html#gad7ea55da06b77513609efebd44b26920
        let txnStatus = mdb_txn_begin(environment.handle, parent?.handle, UInt32(flags.rawValue), &handle)
        
        guard txnStatus == 0 else {
            throw LMDBError(returnCode: txnStatus)
        }

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
