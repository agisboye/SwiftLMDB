//
//  DataConvertible.swift
//  SwiftLMDB
//
//  Created by August Heegaard on 02/10/2016.
//  Copyright © 2016 August Heegaard. All rights reserved.
//

import Foundation

public protocol DataConvertible {
    init?(data: Data)
    var data: Data { get }
}

public extension DataConvertible {
    
    init?(data: Data) {
        guard data.count == MemoryLayout<Self>.size else { return nil }
        self = data.withUnsafeBytes { $0.pointee }
    }
    
    var data: Data {
        var value = self
        return Data(buffer: UnsafeBufferPointer(start: &value, count: 1))
    }
}

extension Data: DataConvertible {
    
    public init?(data: Data) {
        self = data
    }
    
    public var data: Data {
        return self
    }
    
}

extension String: DataConvertible {
    
    public init?(data: Data) {
        self.init(data: data, encoding: .utf8)
    }
    
    public var data: Data {
        return self.data(using: .utf8)!
    }
    
}

extension Array: DataConvertible {

    public init?(data: Data) {
        self = data.withUnsafeBytes {
            [Element](UnsafeBufferPointer(start: $0, count: data.count/MemoryLayout<Element>.stride))
        }
    }
    
    public var data: Data {
        var values = self
        return Data(buffer: UnsafeBufferPointer(start: &values, count: values.count))
    }

}

extension Bool: DataConvertible {}
extension Int: DataConvertible {}
extension Int8: DataConvertible {}
extension Int16: DataConvertible {}
extension Int32: DataConvertible {}
extension Int64: DataConvertible {}
extension UInt: DataConvertible {}
extension UInt8: DataConvertible {}
extension UInt16: DataConvertible {}
extension UInt32: DataConvertible {}
extension UInt64: DataConvertible {}
extension Float: DataConvertible {}
extension Double: DataConvertible {}
extension Date: DataConvertible {}
extension URL: DataConvertible {}
