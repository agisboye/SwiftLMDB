//
//  LMDB.swift
//  SwiftLMDB
//
//  Created by August Heegaard on 02/10/2016.
//  Copyright © 2016 August Heegaard. All rights reserved.
//

import Foundation
import CLMDB


public struct SwiftLMDB {
    
    /// The version of LMDB being used.
    public static var version: (major: Int, minor: Int, patch: Int) {
        
        var major: Int32 = 0
        var minor: Int32 = 0
        var patch: Int32 = 0
        
        _ = mdb_version(&major, &minor, &patch)
        
        return (Int(major), Int(minor), Int(patch))
        
    }
    
    private init() {}
    
}
