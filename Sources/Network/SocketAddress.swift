//
//  SocketAddress.swift
//  webrtc-network
//
//  Created by sunlubo on 2020/9/5.
//  Copyright © 2020 sunlubo. All rights reserved.
//

#if canImport(Darwin)
import Darwin.C
#else
import Glibc
#endif

/// An internet socket address, either IPv4 or IPv6.
///
/// Internet socket addresses consist of an IP address, a 16-bit port number,
/// as well as possibly some version-dependent additional information.
public enum SocketAddress: Equatable {
  /// An IPv4 socket address.
  case v4(SocketAddressV4)
  /// An IPv6 socket address.
  case v6(SocketAddressV6)

  public var ip: IPAddress {
    switch self {
    case .v4(let address):
      return .v4(address.ip)
    case .v6(let address):
      return .v6(address.ip)
    }
  }

  public var port: Port {
    switch self {
    case .v4(let address):
      return address.port
    case .v6(let address):
      return address.port
    }
  }

  /// Returns `true` if the IP address in this `SocketAddress` is an IPv4 address, and false otherwise.
  public var isIPv4: Bool {
    if case .v4 = self {
      return true
    }
    return false
  }

  /// Returns `true` if the IP address in this `SocketAddress` is an IPv6 address, and false otherwise.
  public var isIPv6: Bool {
    if case .v6 = self {
      return true
    }
    return false
  }

  internal var family: Int32 {
    switch self {
    case .v4:
      return AF_INET
    case .v6:
      return AF_INET6
    }
  }

  public init?(_ addr: sockaddr_storage) {
    switch addr.ss_family {
    case sa_family_t(AF_INET):
      self = .v4(.init(addr.convert()))
    case sa_family_t(AF_INET6):
      self = .v6(.init(addr.convert()))
    default:
      return nil
    }
  }

  public init(ip: IPAddress, port: Port) {
    switch ip {
    case .v4(let address):
      self = .v4(.init(ip: address, port: port))
    case .v6(let address):
      self = .v6(.init(ip: address, port: port))
    }
  }

  public init?(_ string: String) {
    if let address = SocketAddressV4(string) {
      self = .v4(address)
    } else if let address = SocketAddressV6(string) {
      self = .v6(address)
    } else if let address = try? DnsResolver.query(string) {
      self = address
    } else {
      return nil
    }
  }

  @discardableResult
  public func withSockAddr<R>(
    _ body: (UnsafePointer<sockaddr>, socklen_t) throws -> R
  ) rethrows -> R {
    switch self {
    case .v4(let address):
      return try withUnsafePointer(to: address.inner) {
        try $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
          try body($0, socklen_t(MemoryLayout.size(ofValue: address.inner)))
        }
      }
    case .v6(let address):
      return try withUnsafePointer(to: address.inner) {
        try $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
          try body($0, socklen_t(MemoryLayout.size(ofValue: address.inner)))
        }
      }
    }
  }
}

// MARK: - SocketAddress + CustomStringConvertible

extension SocketAddress: CustomStringConvertible {
  public var description: String {
    switch self {
    case .v4(let address):
      return address.description
    case .v6(let address):
      return address.description
    }
  }
}

// MARK: - SocketAddress.Port

extension SocketAddress {
  public struct Port: RawRepresentable, Equatable {
    /// The unspecified port (0).
    public static let any: Self = 0
    /// The STUN port (3478).
    public static let stun: Self = 3478
    /// The TURN port (3478).
    public static let turn: Self = 3478
    /// The TURN over TLS port (5349).
    public static let turns: Self = 5349

    public var rawValue: UInt16

    public init?(rawValue: UInt16) {
      self.rawValue = rawValue
    }
  }
}

// MARK: - SocketAddress.Port + ExpressibleByIntegerLiteral

extension SocketAddress.Port: ExpressibleByIntegerLiteral {

  public init(integerLiteral value: IntegerLiteralType) {
    self.rawValue = UInt16(value)
  }
}

// MARK: - SocketAddress.Port + CustomStringConvertible

extension SocketAddress.Port: CustomStringConvertible {
  public var description: String {
    String(rawValue)
  }
}

// MARK: - SocketAddressV4

/// An IPv4 socket address.
///
/// IPv4 socket addresses consist of an IPv4 address and a 16-bit port number, as stated in IETF RFC 793.
public struct SocketAddressV4 {
  internal var inner: sockaddr_in
  /// The IP address associated with this socket address.
  public var ip: IPv4Address {
    IPv4Address(inner.sin_addr)
  }
  /// The port number associated with this socket address.
  public var port: SocketAddress.Port {
    SocketAddress.Port(rawValue: UInt16(bigEndian: inner.sin_port))!
  }

  internal init(_ inner: sockaddr_in) {
    self.inner = inner
  }

  /// Creates a new socket address from an IPv4 address and a port number.
  public init(ip: IPv4Address, port: SocketAddress.Port) {
    self.inner = sockaddr_in()
    self.inner.sin_family = sa_family_t(AF_INET)
    self.inner.sin_addr = ip.inner
    self.inner.sin_port = port.rawValue.bigEndian
  }

  public init?(_ string: String) {
    let parts = string.split(separator: ":")
    guard let ip = IPv4Address(String(parts[0])), let port = UInt16(parts[1]) else {
      return nil
    }
    self = Self(ip: ip, port: SocketAddress.Port(rawValue: port)!)
  }
}

// MARK: - SocketAddressV4 + Equatable

extension SocketAddressV4: Equatable {

  public static func == (lhs: SocketAddressV4, rhs: SocketAddressV4) -> Bool {
    lhs.ip == rhs.ip && lhs.port == rhs.port
  }
}

// MARK: - SocketAddressV4 + CustomStringConvertible

extension SocketAddressV4: CustomStringConvertible {
  public var description: String {
    "\(ip.description):\(port)"
  }
}

// MARK: - SocketAddressV6

/// An IPv6 socket address.
///
/// IPv6 socket addresses consist of an Ipv6 address, a 16-bit port number, as well as fields containing the traffic class, the flow label, and a scope identifier (see IETF RFC 2553, Section 3.3 for more details).
public struct SocketAddressV6 {
  internal var inner: sockaddr_in6
  /// The IP address associated with this socket address.
  public var ip: IPv6Address {
    IPv6Address(inner.sin6_addr)
  }
  /// The port number associated with this socket address.
  public var port: SocketAddress.Port {
    SocketAddress.Port(rawValue: UInt16(bigEndian: inner.sin6_port))!
  }
  /// The flow information associated with this address.
  public var flowinfo: UInt32 {
    UInt32(bigEndian: inner.sin6_flowinfo)
  }
  /// The scope ID associated with this address.
  public var scopeId: UInt32 {
    UInt32(bigEndian: inner.sin6_scope_id)
  }

  internal init(_ inner: sockaddr_in6) {
    self.inner = inner
  }

  /// Creates a new socket address from an IPv6 address, a 16-bit port number,
  /// and the `flowinfo` and `scope_id` fields.
  public init(ip: IPv6Address, port: SocketAddress.Port, flowinfo: UInt32 = 0, scopeId: UInt32 = 0) {
    self.inner = sockaddr_in6()
    self.inner.sin6_family = sa_family_t(AF_INET6)
    self.inner.sin6_addr = ip.inner
    self.inner.sin6_port = port.rawValue.bigEndian
    self.inner.sin6_flowinfo = flowinfo.bigEndian
    self.inner.sin6_scope_id = scopeId.bigEndian
  }

  public init?(_ string: String) {
    let parts = string.split(separator: "]")
    guard let ip = IPv6Address(String(parts[0].dropFirst())), let port = UInt16(parts[1].dropFirst()) else {
      return nil
    }
    self = Self(ip: ip, port: SocketAddress.Port(rawValue: port)!)
  }
}

// MARK: - SocketAddressV6 + Equatable

extension SocketAddressV6: Equatable {

  public static func == (lhs: SocketAddressV6, rhs: SocketAddressV6) -> Bool {
    lhs.ip == rhs.ip && lhs.port == rhs.port
  }
}

// MARK: - SocketAddressV6 + CustomStringConvertible

extension SocketAddressV6: CustomStringConvertible {
  public var description: String {
    "[\(ip.description)]:\(port)"
  }
}

// MARK: - sockaddr_storage

extension sockaddr_storage {

  public mutating func withMutableSockAddr<R>(_ body: (UnsafeMutablePointer<sockaddr>, Int) throws -> R) rethrows -> R {
    try withUnsafeMutableBytes(of: &self) {
      try body($0.baseAddress!.assumingMemoryBound(to: sockaddr.self), $0.count)
    }
  }

  public func convert<T>(to type: T.Type = T.self) -> T {
    withUnsafePointer(to: self) {
      $0.withMemoryRebound(to: T.self, capacity: 1, \.pointee)
    }
  }
}

// MARK: - sockaddr

extension UnsafeMutablePointer where Pointee == sockaddr {

  public func convert<T>(to type: T.Type = T.self) -> T {
    withMemoryRebound(to: type, capacity: 1, \.pointee)
  }
}
