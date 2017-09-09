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
    var data: Data { get }
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

extension Bool: DataConvertible {
    
    public init?(data: Data) {
        guard data.count == MemoryLayout<UInt8>.size else { return nil }
        self = data.withUnsafeBytes { $0.pointee } != 0
    }

    public var data: Data {
        var value: UInt8 = self ? 1 : 0
        return Data(buffer: UnsafeBufferPointer(start: &value, count: 1))
    }
}

extension Int: DataConvertible {

    public init?(data: Data) {
        guard data.count == MemoryLayout<Int>.size else { return nil }
        let bigEndian: Int = data.withUnsafeBytes { $0.pointee }
        self = Int(bigEndian: bigEndian)
    }

    public var data: Data {
        var bigEndian = self.bigEndian
        return Data(buffer: UnsafeBufferPointer(start: &bigEndian, count: 1))
    }
}

extension UInt: DataConvertible {

    public init?(data: Data) {
        guard data.count == MemoryLayout<UInt>.size else { return nil }
        self = UInt(bigEndian: data.withUnsafeBytes { $0.pointee })
    }

    public var data: Data {
        var value = self.bigEndian
        return Data(buffer: UnsafeBufferPointer(start: &value, count: 1))
    }
}

extension Int8: DataConvertible {

    public init?(data: Data) {
        guard data.count == MemoryLayout<Int8>.size else { return nil }
        self = data.withUnsafeBytes { $0.pointee }
    }

    public var data: Data {
        var value = self
        return Data(buffer: UnsafeBufferPointer(start: &value, count: 1))
    }
}

extension UInt8: DataConvertible {

    public init?(data: Data) {
        guard data.count == MemoryLayout<UInt8>.size else { return nil }
        self = data.withUnsafeBytes { $0.pointee }
    }

    public var data: Data {
        var value = self
        return Data(buffer: UnsafeBufferPointer(start: &value, count: 1))
    }
}

extension Int16: DataConvertible {

    public init?(data: Data) {
        guard data.count == MemoryLayout<Int16>.size else { return nil }
        self = Int16(bigEndian: data.withUnsafeBytes { $0.pointee })
    }

    public var data: Data {
        var value = self.bigEndian
        return Data(buffer: UnsafeBufferPointer(start: &value, count: 1))
    }
}

extension UInt16: DataConvertible {

    public init?(data: Data) {
        guard data.count == MemoryLayout<UInt16>.size else { return nil }
        self = UInt16(bigEndian: data.withUnsafeBytes { $0.pointee })
    }

    public var data: Data {
        var value = self.bigEndian
        return Data(buffer: UnsafeBufferPointer(start: &value, count: 1))
    }
}

extension Int32: DataConvertible {

    public init?(data: Data) {
        guard data.count == MemoryLayout<Int32>.size else { return nil }
        self = Int32(bigEndian: data.withUnsafeBytes { $0.pointee })
    }

    public var data: Data {
        var value = self.bigEndian
        return Data(buffer: UnsafeBufferPointer(start: &value, count: 1))
    }
}

extension UInt32: DataConvertible {

    public init?(data: Data) {
        guard data.count == MemoryLayout<UInt32>.size else { return nil }
        self = UInt32(bigEndian: data.withUnsafeBytes { $0.pointee })
    }

    public var data: Data {
        var value = self.bigEndian
        return Data(buffer: UnsafeBufferPointer(start: &value, count: 1))
    }
}

extension Int64: DataConvertible {

    public init?(data: Data) {
        guard data.count == MemoryLayout<Int64>.size else { return nil }
        self = Int64(bigEndian: data.withUnsafeBytes { $0.pointee })
    }

    public var data: Data {
        var value = self.bigEndian
        return Data(buffer: UnsafeBufferPointer(start: &value, count: 1))
    }
}

extension UInt64: DataConvertible {

    public init?(data: Data) {
        guard data.count == MemoryLayout<UInt64>.size else { return nil }
        self = UInt64(bigEndian: data.withUnsafeBytes { $0.pointee })
    }

    public var data: Data {
        var value = self.bigEndian
        return Data(buffer: UnsafeBufferPointer(start: &value, count: 1))
    }
}

extension Float: DataConvertible {

    public init?(data: Data) {
        guard data.count == MemoryLayout<UInt32>.size else { return nil }
        let bigEndian: UInt32 = data.withUnsafeBytes { $0.pointee }
        let bitPattern = UInt32(bigEndian: bigEndian)
        self = Float(bitPattern: bitPattern)
    }

    public var data: Data {
        let bitPattern: UInt32 = self.bitPattern
        var bigEndian = bitPattern.bigEndian
        return Data(buffer: UnsafeBufferPointer(start: &bigEndian, count: 1))
    }
}

extension Double: DataConvertible {

    public init?(data: Data) {
        guard data.count == MemoryLayout<UInt64>.size else { return nil }
        let bigEndian: UInt64 = data.withUnsafeBytes { $0.pointee }
        let bitPattern = UInt64(bigEndian: bigEndian)
        self = Double(bitPattern: bitPattern)
    }

    public var data: Data {
        let bitPattern: UInt64 = self.bitPattern
        var bigEndian = bitPattern.bigEndian
        return Data(buffer: UnsafeBufferPointer(start: &bigEndian, count: 1))
    }
}

extension Date: DataConvertible {

    public init?(data: Data) {
        guard let timeInterval = TimeInterval(data: data) else {
            return nil
        }
        self = Date(timeIntervalSinceReferenceDate: timeInterval)
    }

    public var data: Data {
        return self.timeIntervalSinceReferenceDate.data
    }
}

extension URL: DataConvertible {

    public init?(data: Data) {
        guard let url = URL(dataRepresentation: data, relativeTo: nil, isAbsolute: true) else {
            return nil
        }
        self = url
    }

    public var data: Data {
        return self.absoluteURL.dataRepresentation
    }
}
