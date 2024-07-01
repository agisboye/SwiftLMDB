//
//  LMDBVersion.swift
//
//
//  Created by Vitor Travain on 2/7/2024.
//

import Foundation
import LMDB

struct LMDBVersion {
    var major: Int
    var minor: Int
    var patch: Int

    private init(major: Int, minor: Int, patch: Int) {
        self.major = major
        self.minor = minor
        self.patch = patch
    }

    static let current: LMDBVersion = {
        var major: Int32 = 0
        var minor: Int32 = 0
        var patch: Int32 = 0

        _ = mdb_version(&major, &minor, &patch)

        return LMDBVersion(major: Int(major), minor: Int(minor), patch: Int(patch))
    }()
}
