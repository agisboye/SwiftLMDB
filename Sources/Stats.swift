//
//  Stats.swift
//  
//
//  Created by August Heegaard on 17/08/2021.
//

import LMDB

/// Provides database statistics
public struct Stats {
    
    public let pageSize: UInt32
    public let depth: UInt32
    public let branchPageCount: Int
    public let leafPageCount: Int
    public let overflowPageCount: Int
    public let entries: Int
    
    internal init(stat: MDB_stat) {
        self.pageSize = stat.ms_psize
        self.depth = stat.ms_depth
        self.branchPageCount = stat.ms_branch_pages
        self.leafPageCount = stat.ms_leaf_pages
        self.overflowPageCount = stat.ms_overflow_pages
        self.entries = stat.ms_entries
    }
    
}
