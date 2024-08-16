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

// reference from https://stackoverflow.com/questions/26227702/converting-nsdata-to-integer-in-swift
extension Data {
    enum Endianness {
        case BigEndian
        case LittleEndian
    }
    func scanValue<T: FixedWidthInteger>(at index: Data.Index, endianess: Endianness) -> T {
        let number: T = self.subdata(in: index..<index + MemoryLayout<T>.size).withUnsafeBytes({ $0.pointee })
        switch endianess {
        case .BigEndian:
            return number.bigEndian
        case .LittleEndian:
            return number.littleEndian
        }
    }
}

extension FixedWidthInteger where Self: DataConvertible {

    public init?(data: Data) {
        guard data.count == MemoryLayout<Self>.size else { return nil }
        self = data.scanValue(at: 0, endianess: .LittleEndian)
    }
    
    public var asData: Data {
        var littleEndian = self.littleEndian
        return Data(bytes: &littleEndian, count: MemoryLayout<Self>.size)
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
        let littleEndian: UInt32 = data.scanValue(at: 0, endianess: .LittleEndian)
        let bitPattern = UInt32(littleEndian: littleEndian)
        self = .init(bitPattern: bitPattern)
    }

    public var asData: Data {
        return bitPattern.littleEndian.asData
    }
    
}

extension Double: DataConvertible {

    public init?(data: Data) {
        guard data.count == MemoryLayout<UInt64>.size else { return nil }
        let littleEndian: UInt64 = data.scanValue(at: 0, endianess: .LittleEndian)
        let bitPattern = UInt64(littleEndian: littleEndian)
        self = .init(bitPattern: bitPattern)
    }

    public var asData: Data {
        return bitPattern.littleEndian.asData
    }
    
}

extension Date: DataConvertible {

    public init?(data: Data) {
        guard let timeInterval = TimeInterval(data: data) else { return nil }
        self = Date(timeIntervalSinceReferenceDate: timeInterval)
    }

    public var asData: Data {
        return timeIntervalSinceReferenceDate.asData
    }
    
}
