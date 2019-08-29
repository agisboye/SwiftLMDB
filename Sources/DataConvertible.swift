//
//  DataConvertible.swift
//  SwiftLMDB
//
//  Created by August Heegaard on 02/10/2016.
//  Copyright © 2016 August Heegaard. All rights reserved.
//

import Foundation

/// Any type conforming to the DataConvertible protocol can be used as both key and value in LMDB.
/// The protocol provides a default implementation, which will work for most Swift value types.
/// For other types, including reference counted ones, you may want to implement the conversion yourself.
public protocol DataConvertible {
    init?(data: Data)
    var asData: Data { get }
}

extension Data: DataConvertible {
    
    public init?(data: Data) {
        self = data
    }
    
    public var asData: Data {
        return self
    }
    
}

extension String: DataConvertible {
    
    public init?(data: Data) {
        self.init(data: data, encoding: .utf8)
    }
    
    public var asData: Data {
        return self.data(using: .utf8)!
    }
    
}

extension Bool: DataConvertible {
    
    public init?(data: Data) {
        guard let integer = UInt8(data: data) else { return nil }
        self = (integer != 0)
    }

    public var asData: Data {
        let value: UInt8 = self ? 1 : 0
        return value.asData
    }
}

extension FixedWidthInteger where Self: DataConvertible {

    public init?(data: Data) {
        guard data.count == MemoryLayout<Self>.size else { return nil }
        let littleEndian = data.withUnsafeBytes { $0.load(as: Self.self) }
        self = .init(littleEndian: littleEndian)
    }
    
    public var asData: Data {
        var littleEndian = self.littleEndian
        return Data(buffer: UnsafeBufferPointer(start: &littleEndian, count: 1))
    }
    
}

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

extension Float: DataConvertible {

    public init?(data: Data) {
        guard data.count == MemoryLayout<UInt32>.size else { return nil }
        let littleEndian = data.withUnsafeBytes { $0.load(as: UInt32.self) }
        let bitPattern = UInt32(littleEndian: littleEndian)
        self = .init(bitPattern: bitPattern)
    }

    public var asData: Data {
        var littleEndian = bitPattern.littleEndian
        return Data(buffer: UnsafeBufferPointer(start: &littleEndian, count: 1))
    }
    
}

extension Double: DataConvertible {

    public init?(data: Data) {
        guard data.count == MemoryLayout<UInt64>.size else { return nil }
        let littleEndian = data.withUnsafeBytes { $0.load(as: UInt64.self) }
        let bitPattern = UInt64(littleEndian: littleEndian)
        self = .init(bitPattern: bitPattern)
    }

    public var asData: Data {
        var littleEndian = bitPattern.littleEndian
        return Data(buffer: UnsafeBufferPointer(start: &littleEndian, count: 1))
    }
    
}

extension Date: DataConvertible {

    public init?(data: Data) {
        guard let timeInterval = TimeInterval(data: data) else {
            return nil
        }
        self = Date(timeIntervalSinceReferenceDate: timeInterval)
    }

    public var asData: Data {
        return self.timeIntervalSinceReferenceDate.asData
    }
    
}
