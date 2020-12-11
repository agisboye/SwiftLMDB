//
//  Database+Sequence.swift
//  SwiftLMDB
//
//  Created by August Heegaard on 25/02/2020.
//

extension Database: Sequence {

    public typealias Iterator = Cursor
    
    public func makeIterator() -> Database.Iterator {
        return try! cursor()
    }
    
    public var underestimatedCount: Int {
        return count
    }
    
}
