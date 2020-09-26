//
//  IPAddress.swift
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

/// An IP address, either IPv4 or IPv6.
public enum IPAddress: Equatable {
  /// An IPv4 address.
  case v4(IPv4Address)
  /// An IPv6 address.
  case v6(IPv6Address)

  /// Returns the eight-bit integers that make up this address.
  public var octets: [UInt8] {
    switch self {
    case .v4(let address):
      return address.octets
    case .v6(let address):
      return address.octets
    }
  }

  /// Returns `true` if this address is an IPv4 address, and `false` otherwise.
  public var isIPv4: Bool {
    if case .v4 = self {
      return true
    }
    return false
  }

  /// Returns `true` if this address is an IPv6 address, and `false` otherwise.
  public var isIPv6: Bool {
    if case .v6 = self {
      return true
    }
    return false
  }

  /// Returns `true` for the special 'unspecified' address.
  public var isAny: Bool {
    switch self {
    case .v4(let address):
      return address.isAny
    case .v6(let address):
      return address.isAny
    }
  }

  /// Returns `true` if this is a loopback address.
  public var isLoopback: Bool {
    switch self {
    case .v4(let address):
      return address.isLoopback
    case .v6(let address):
      return address.isLoopback
    }
  }

  /// Returns `true` if this is a multicast address.
  public var isMulticast: Bool {
    switch self {
    case .v4(let address):
      return address.isMulticast
    case .v6(let address):
      return address.isMulticast
    }
  }

  public init?(_ string: String) {
    if let address = IPv4Address(string) {
      self = .v4(address)
    } else if let address = IPv6Address(string) {
      self = .v6(address)
    } else {
      return nil
    }
  }
}

// MARK: - IPAddress + CustomStringConvertible

extension IPAddress: CustomStringConvertible {
  public var description: String {
    switch self {
    case .v4(let address):
      return address.description
    case .v6(let address):
      return address.description
    }
  }
}

// MARK: - IPv4Address

/// An IPv4 address.
///
/// IPv4 addresses are defined as 32-bit integers in IETF RFC 791. They are usually represented as four octets.
public struct IPv4Address {
  /// An IPv4 address representing an unspecified address (0.0.0.0).
  public static let any = IPv4Address(0, 0, 0, 0)
  /// An IPv4 address with the address pointing to localhost (127.0.0.1).
  public static let localhost = IPv4Address(127, 0, 0, 1)
  /// An IPv4 address representing the broadcast address (255.255.255.255).
  public static let broadcast = IPv4Address(255, 255, 255, 255)

  internal var inner: in_addr

  /// Returns the four eight-bit integers that make up this address.
  public var octets: [UInt8] {
    withUnsafeBytes(of: inner.s_addr, Array.init)
  }

  /// Returns `true` for the special 'unspecified' address (0.0.0.0).
  ///
  /// This property is defined in _UNIX Network Programming, Second Edition_,
  /// W. Richard Stevens, p. 891; see also [ip7](http://man7.org/linux/man-pages/man7/ip.7.html).
  public var isAny: Bool {
    inner.s_addr == 0
  }

  /// Returns `true` if this is a loopback address (127.0.0.0/8).
  ///
  /// This property is defined by [IETF RFC 1122](https://tools.ietf.org/html/rfc1122).
  public var isLoopback: Bool {
    octets[0] == 0x7F
  }

  /// Returns `true` if the address is link-local (169.254.0.0/16).
  ///
  /// This property is defined by [IETF RFC 3927](https://tools.ietf.org/html/rfc3927).
  public var isLinkLocal: Bool {
    octets[0] == 0xA9 && octets[1] == 0xFE
  }

  /// Returns `true` if this is a multicast address (224.0.0.0/4).
  ///
  /// Multicast addresses have a most significant octet between 224 and 239,
  /// and is defined by [IETF RFC 5771](https://tools.ietf.org/html/rfc5771).
  public var isMulticast: Bool {
    octets[0] >= 0xE0 && octets[0] <= 0xEF
  }

  /// Returns `true` if this is a broadcast address (255.255.255.255).
  ///
  /// A broadcast address has all octets set to 255 as defined in [IETF RFC 919](https://tools.ietf.org/html/rfc919).
  public var isBroadcast: Bool {
    inner.s_addr == 0xFF_FF_FF_FF
  }

  /// Converts this address to an IPv4-compatible IPv6 address.
  ///
  /// `a.b.c.d` becomes `::a.b.c.d`
  public var asIPv6Compatible: IPv6Address {
    IPv6Address(0, 0, 0, inner.s_addr.bigEndian)
  }

  /// Converts this address to an IPv4-mapped IPv6 address.
  ///
  /// `a.b.c.d` becomes `::ffff:a.b.c.d`
  public var asIPv6Mapped: IPv6Address {
    IPv6Address(0, 0, 0xffff, inner.s_addr.bigEndian)
  }

  internal init(_ inner: in_addr) {
    self.inner = inner
  }

  public init(_ a: UInt32) {
    self.inner = in_addr(s_addr: a)
  }

  /// Creates a new IPv4 address from four eight-bit octets.
  ///
  /// The result will represent the IP address `a`.`b`.`c`.`d`.
  public init(_ a: UInt8, _ b: UInt8, _ c: UInt8, _ d: UInt8) {
    self.inner = in_addr(
      s_addr: in_addr_t((UInt32(a) << 24) | (UInt32(b) << 16) | (UInt32(c) << 8) | UInt32(d)).bigEndian
    )
  }

  public init?(_ string: String) {
    var addr = in_addr()
    guard string.withCString({ inet_pton(AF_INET, $0, &addr) }) == 1 else {
      return nil
    }
    self.inner = addr
  }
}

// MARK: - IPv4Address + Equatable

extension IPv4Address: Equatable {

  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.inner.s_addr == rhs.inner.s_addr
  }
}

// MARK: - IPv4Address + CustomStringConvertible

extension IPv4Address: CustomStringConvertible {
  public var description: String {
    let buffer = UnsafeMutablePointer<Int8>.allocate(capacity: Int(INET_ADDRSTRLEN))
    buffer.initialize(repeating: 0, count: Int(INET_ADDRSTRLEN))
    defer {
      buffer.deallocate()
    }
    _ = withUnsafePointer(to: inner) {
      inet_ntop(AF_INET, $0, buffer, socklen_t(INET_ADDRSTRLEN))
    }
    return String(cString: buffer)
  }
}

// MARK: - IPv6Address

/// An IPv6 address.
///
/// IPv6 addresses are defined as 128-bit integers in IETF RFC 4291. They are usually represented as eight 16-bit segments.
public struct IPv6Address {
  /// An IPv6 address representing the unspecified address (::).
  public static let any = IPv6Address(0, 0, 0, 0, 0, 0, 0, 0)
  /// An IPv6 address representing localhost (::1).
  public static let localhost = IPv6Address(0, 0, 0, 0, 0, 0, 0, 1)

  internal var inner: in6_addr

  /// Returns the eight 16-bit segments that make up this address.
  public var segments: [UInt16] {
    withUnsafeBytes(of: inner.__u6_addr.__u6_addr8) {
      Array($0.bindMemory(to: UInt16.self)).map(\.bigEndian)
    }
  }

  /// Returns the sixteen eight-bit integers the IPv6 address consists of.
  public var octets: [UInt8] {
    withUnsafeBytes(of: inner.__u6_addr.__u6_addr8, Array.init)
  }

  /// Returns `true` for the special 'unspecified' address (::).
  ///
  /// This property is defined in [IETF RFC 4291](https://tools.ietf.org/html/rfc4291).
  public var isAny: Bool {
    inner.__u6_addr.__u6_addr32.0 == 0
      && inner.__u6_addr.__u6_addr32.1 == 0
      && inner.__u6_addr.__u6_addr32.2 == 0
      && inner.__u6_addr.__u6_addr32.3 == 0
  }

  /// Returns `true` if this is a loopback address (::1).
  ///
  /// This property is defined by [IETF RFC 4291](https://tools.ietf.org/html/rfc4291).
  public var isLoopback: Bool {
    inner.__u6_addr.__u6_addr32.0 == 0
      && inner.__u6_addr.__u6_addr32.1 == 0
      && inner.__u6_addr.__u6_addr32.2 == 0
      && inner.__u6_addr.__u6_addr32.3 == UInt32(bigEndian: 1)
  }

  /// Returns `true` if this is a multicast address (ff00::/8).
  ///
  /// This property is defined by [IETF RFC 4291](https://tools.ietf.org/html/rfc4291).
  public var isMulticast: Bool {
    inner.__u6_addr.__u6_addr8.0 == 0xff
  }

  /// Returns `true` if this is a IPv4-compatible address (a.b.c.d => ::a.b.c.d).
  public var isIPv4Compatabile: Bool {
    inner.__u6_addr.__u6_addr32.0 == 0
      && inner.__u6_addr.__u6_addr32.1 == 0
      && inner.__u6_addr.__u6_addr32.2 == 0
      && inner.__u6_addr.__u6_addr32.3 != 0
      && inner.__u6_addr.__u6_addr32.3 != UInt32(bigEndian: 1)
  }

  /// Returns `true` if this is a IPv4-mapped address (a.b.c.d => ::ffff:a.b.c.d).
  public var isIPv4Mapped: Bool {
    inner.__u6_addr.__u6_addr32.0 == 0
      && inner.__u6_addr.__u6_addr32.1 == 0
      && inner.__u6_addr.__u6_addr32.2 == UInt32(bigEndian: 0x0000ffff)
  }

  /// Converts this address to an IPv4 address.
  ///
  /// Returns `nil` if this address is neither IPv4-compatible or IPv4-mapped.
  public var asIPv4: IPv4Address? {
    guard isIPv4Compatabile || isIPv4Mapped else {
      return nil
    }
    return IPv4Address(
      inner.__u6_addr.__u6_addr8.12, inner.__u6_addr.__u6_addr8.13,
      inner.__u6_addr.__u6_addr8.14, inner.__u6_addr.__u6_addr8.15
    )
  }

  internal init(_ inner: in6_addr) {
    self.inner = inner
  }

  public init(_ a: UInt32, _ b: UInt32, _ c: UInt32, _ d: UInt32) {
    self.inner = in6_addr(
      __u6_addr: .init(__u6_addr32: (a.bigEndian, b.bigEndian, c.bigEndian, d.bigEndian))
    )
  }

  /// Creates a new IPv6 address from eight 16-bit segments.
  ///
  /// The result will represent the IP address `a:b:c:d:e:f:g:h`.
  public init(
    _ a: UInt16, _ b: UInt16, _ c: UInt16, _ d: UInt16,
    _ e: UInt16, _ f: UInt16, _ g: UInt16, _ h: UInt16
  ) {
    self.inner = in6_addr(
      __u6_addr: .init(
        __u6_addr16: (
          a.bigEndian, b.bigEndian, c.bigEndian, d.bigEndian,
          e.bigEndian, f.bigEndian, g.bigEndian, h.bigEndian
        )
      )
    )
  }

  public init?(_ string: String) {
    var addr = in6_addr()
    guard string.withCString({ inet_pton(AF_INET6, $0, &addr) }) == 1 else {
      return nil
    }
    self.inner = addr
  }
}

// MARK: - IPv6Address + Equatable

extension IPv6Address: Equatable {

  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.inner.__u6_addr.__u6_addr32.0 == rhs.inner.__u6_addr.__u6_addr32.0
      && lhs.inner.__u6_addr.__u6_addr32.1 == rhs.inner.__u6_addr.__u6_addr32.1
      && lhs.inner.__u6_addr.__u6_addr32.2 == rhs.inner.__u6_addr.__u6_addr32.2
      && lhs.inner.__u6_addr.__u6_addr32.3 == rhs.inner.__u6_addr.__u6_addr32.3
  }
}

// MARK: - IPv6Address + CustomStringConvertible

extension IPv6Address: CustomStringConvertible {
  public var description: String {
    let buffer = UnsafeMutablePointer<Int8>.allocate(capacity: Int(INET6_ADDRSTRLEN))
    buffer.initialize(repeating: 0, count: Int(INET6_ADDRSTRLEN))
    defer {
      buffer.deallocate()
    }
    _ = withUnsafePointer(to: inner) {
      inet_ntop(AF_INET6, $0, buffer, socklen_t(INET6_ADDRSTRLEN))
    }
    return String(cString: buffer)
  }
}
