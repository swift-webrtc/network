//
//  UDPSocket.swift
//  webrtc-network
//
//  Created by sunlubo on 2020/9/5.
//  Copyright © 2020 sunlubo. All rights reserved.
//

import Core
#if canImport(Darwin)
import Darwin.C
#else
import Glibc
#endif

/// A UDP socket.
public final class UDPSocket {

  /// Creates a UDP socket from the given address.
  public static func bind(to address: SocketAddress) throws -> UDPSocket {
    let fd = try check(sys_socket(address.family, SOCK_DGRAM, 0))
    do {
      try check(address.withSockAddr({ sys_bind(fd, $0, $1) }))
    } catch {
      _ = sys_close(fd)
      throw error
    }
    return UDPSocket(fd: fd)
  }

  /// Creates a UDP socket and connects to a remote address, allowing the send and recv syscalls to be used to
  /// send data and also applies filters to only receive data from the specified address.
  public static func connect(to address: SocketAddress) throws -> UDPSocket {
    let fd = try check(sys_socket(address.family, SOCK_DGRAM, 0))
    do {
      try check(address.withSockAddr({ sys_connect(fd, $0, $1) }))
    } catch {
      _ = sys_close(fd)
      throw error
    }
    return UDPSocket(fd: fd)
  }

  internal let fd: Int32

  internal init(fd: Int32) {
    self.fd = fd
  }

  /// Sends data on the socket to the remote address to which it is connected.
  public func send(_ data: UnsafeRawBufferPointer) throws -> Int {
    try check(sys_send(fd, data.baseAddress!, data.count, 0))
  }

  /// Receives a single datagram message on the socket from the remote address to which it is connected.
  ///
  /// - Returns: The number of bytes read.
  public func recv(_ data: UnsafeMutableRawBufferPointer) throws -> Int {
    try check(sys_recv(fd, data.baseAddress, data.count, 0))
  }

  /// Sends data on the socket to the given address.
  ///
  /// - Returns: The number of bytes written.
  public func sendto(_ data: UnsafeRawBufferPointer, address: SocketAddress) throws -> Int {
    try address.withSockAddr {
      try check(sys_sendto(fd, data.baseAddress, data.count, 0, $0, $1))
    }
  }

  /// Receives a single datagram message on the socket.
  ///
  /// - Returns: The number of bytes read and the origin.
  public func recvfrom(_ data: UnsafeMutableRawBufferPointer) throws -> (Int, SocketAddress) {
    var addr = sockaddr_storage()
    let count = try addr.withMutableSockAddr { ptr, len -> Int in
      var len = socklen_t(len)
      return try check(sys_recvfrom(fd, data.baseAddress, data.count, 0, ptr, &len))
    }
    return (count, SocketAddress(addr)!)
  }

  public func close() throws {
    try check(sys_close(fd))
  }
}

// MARK: - Address

extension UDPSocket {
  /// The socket address of the local half of this TCP connection.
  public var localAddress: SocketAddress? {
    var addr = sockaddr_storage()
    do {
      try addr.withMutableSockAddr {
        var len = socklen_t($1)
        try check(sys_getsockname(fd, $0, &len))
      }
      return SocketAddress(addr)
    } catch {
      logger.error("getsockname: \(error)")
    }
    return nil
  }

  /// The socket address of the remote peer of this TCP connection.
  public var remoteAddress: SocketAddress? {
    var addr = sockaddr_storage()
    do {
      try addr.withMutableSockAddr {
        var len = socklen_t($1)
        try check(sys_getpeername(fd, $0, &len))
      }
      return SocketAddress(addr)
    } catch {
      logger.error("getpeername: \(error)")
    }
    return nil
  }
}

// MARK: - Options

extension UDPSocket {

  /// Gets the value of the `SO_RCVTIMEO` option on this socket.
  public func readTimeout() throws -> Duration {
    var value = timeval()
    var size = socklen_t(MemoryLayout.size(ofValue: value))
    try check(sys_getsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &value, &size))
    return Duration(value)
  }

  /// Sets the value of the `SO_RCVTIMEO` option on this socket.
  public func setReadTimeout(_ duration: Duration) throws {
    var value = duration.ctimeval
    try check(sys_setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &value, socklen_t(MemoryLayout.size(ofValue: value))))
  }

  /// Gets the value of the `SO_SNDTIMEO` option on this socket.
  public func writeTimeout() throws -> Duration {
    var value = timeval()
    var size = socklen_t(MemoryLayout.size(ofValue: value))
    try check(sys_getsockopt(fd, SOL_SOCKET, SO_SNDTIMEO, &value, &size))
    return Duration(value)
  }

  /// Sets the value of the `SO_SNDTIMEO` option on this socket.
  public func setWriteTimeout(_ duration: Duration) throws {
    var value = duration.ctimeval
    try check(sys_setsockopt(fd, SOL_SOCKET, SO_SNDTIMEO, &value, socklen_t(MemoryLayout.size(ofValue: value))))
  }

  /// Gets the value of the `SO_RCVBUF` option on this socket.
  public func readBufferSize() throws -> Int {
    var value = 0
    var size = socklen_t(MemoryLayout.size(ofValue: value))
    try check(sys_getsockopt(fd, SOL_SOCKET, SO_RCVBUF, &value, &size))
    return value
  }

  /// Sets the value of the `SO_RCVBUF` option on this socket.
  public func setReadBufferSize(_ value: Int) throws {
    var value = value
    try check(sys_setsockopt(fd, SOL_SOCKET, SO_RCVBUF, &value, socklen_t(MemoryLayout.size(ofValue: value))))
  }

  /// Gets the value of the `SO_SNDBUF` option on this socket.
  public func writeBufferSize() throws -> Int {
    var value = 0
    var size = socklen_t(MemoryLayout.size(ofValue: value))
    try check(sys_getsockopt(fd, SOL_SOCKET, SO_SNDBUF, &value, &size))
    return value
  }

  /// Sets the value of the `SO_SNDBUF` option on this socket.
  public func setWriteBufferSize(_ value: Int) throws {
    var value = value
    try check(sys_setsockopt(fd, SOL_SOCKET, SO_SNDBUF, &value, socklen_t(MemoryLayout.size(ofValue: value))))
  }

  /// Gets the value of the `SO_BROADCAST` option for this socket.
  public func isBroadcast() throws -> Bool {
    var value = 0 as Int
    var size = socklen_t(MemoryLayout.size(ofValue: value))
    try check(sys_getsockopt(fd, SOL_SOCKET, SO_BROADCAST, &value, &size))
    return value != 0
  }

  /// Sets the value of the `SO_BROADCAST` option on this socket.
  public func setBroadcast(_ value: Bool) throws {
    var value = Int(value ? 1 : 0)
    try check(sys_setsockopt(fd, SOL_SOCKET, SO_BROADCAST, &value, socklen_t(MemoryLayout.size(ofValue: value))))
  }

  /// Gets the value of the `IP_TTL` option on this socket.
  public func ttl() throws -> Int {
    var value = 0
    var size = socklen_t(MemoryLayout.size(ofValue: value))
    try check(sys_getsockopt(fd, IPPROTO_IP, IP_TTL, &value, &size))
    return value
  }

  /// Sets the value for the `IP_TTL` option on this socket.
  public func setTtl(_ value: Int) throws {
    var value = value
    try check(sys_setsockopt(fd, IPPROTO_IP, IP_TTL, &value, socklen_t(MemoryLayout.size(ofValue: value))))
  }
}

// MARK: - Nonblocking

extension UDPSocket {

  public func isNonblocking() throws -> Bool {
    try check(sys_fcntl(fd, F_GETFL)) & O_NONBLOCK != 0
  }

  public func setNonblocking(_ value: Bool) throws {
    var flags = try check(fcntl(fd, F_GETFL))
    flags = value ? flags | O_NONBLOCK : flags & ~O_NONBLOCK
    try check(sys_fcntl(fd, F_SETFL, flags))
  }
}
