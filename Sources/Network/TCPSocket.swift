//
//  TCPSocket.swift
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

/// A TCP connection between a local and a remote socket.
public final class TCPSocket {

  /// Opens a TCP connection to a remote host.
  ///
  /// - Parameter address: An address of the remote host.
  public static func connect(to address: SocketAddress) throws -> TCPSocket {
    let fd = try check(sys_socket(address.family, SOCK_STREAM, 0))
    do {
      try check(address.withSockAddr({ sys_connect(fd, $0, $1) }))
    } catch {
      _ = sys_close(fd)
      throw error
    }
    return TCPSocket(fd: fd)
  }

  internal let fd: Int32

  internal init(fd: Int32) {
    self.fd = fd
  }

  public func read(_ buffer: UnsafeMutableRawBufferPointer) throws -> Int {
    try check(sys_recv(fd, buffer.baseAddress, buffer.count, 0))
  }

  public func write(_ buffer: UnsafeRawBufferPointer) throws -> Int {
    try check(sys_send(fd, buffer.baseAddress, buffer.count, 0))
  }

  public func close() throws {
    try check(sys_close(fd))
  }
}

// MARK: - Address

extension TCPSocket {
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

extension TCPSocket {

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

  /// Gets the value of the `SO_KEEPALIVE` option on this socket.
  public func isKeepAlive() throws -> Bool {
    var value = 0 as Int
    var size = socklen_t(MemoryLayout.size(ofValue: value))
    try check(sys_getsockopt(fd, SOL_SOCKET, SO_KEEPALIVE, &value, &size))
    return value != 0
  }

  /// Sets the value of the `SO_KEEPALIVE` option on this socket.
  public func setKeepAlive(_ value: Bool) throws {
    var value = Int(value ? 1 : 0)
    try check(sys_setsockopt(fd, SOL_SOCKET, SO_KEEPALIVE, &value, socklen_t(MemoryLayout.size(ofValue: value))))
  }

  /// Gets the value of the `SO_LINGER` option on this socket.
  public func linger() throws -> Int {
    var value = s_linger()
    var size = socklen_t(MemoryLayout.size(ofValue: value))
    try check(sys_getsockopt(fd, SOL_SOCKET, SO_LINGER, &value, &size))
    return value.l_onoff == 1 ? Int(value.l_linger) : 0
  }

  /// Sets the value of the `SO_LINGER` option on this socket.
  public func setLinger(_ value: Int) throws {
    var value = s_linger(l_onoff: value > 0 ? 1 : 0, l_linger: Int32(value))
    try check(sys_setsockopt(fd, SOL_SOCKET, SO_LINGER, &value, socklen_t(MemoryLayout.size(ofValue: value))))
  }

  /// Gets the value of the `TCP_NODELAY` option for this socket.
  public func isNoDelay() throws -> Bool {
    var value = 0 as Int
    var size = socklen_t(MemoryLayout.size(ofValue: value))
    try check(sys_getsockopt(fd, IPPROTO_TCP, TCP_NODELAY, &value, &size))
    return value != 0
  }

  /// Sets the value of the `TCP_NODELAY` option on this socket.
  public func setNoDelay(_ value: Bool) throws {
    var value = Int(value ? 1 : 0)
    try check(sys_setsockopt(fd, IPPROTO_TCP, TCP_NODELAY, &value, socklen_t(MemoryLayout.size(ofValue: value))))
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

extension TCPSocket {

  public func isNonblocking() throws -> Bool {
    try check(sys_fcntl(fd, F_GETFL)) & O_NONBLOCK != 0
  }

  public func setNonblocking(_ value: Bool) throws {
    var flags = try check(fcntl(fd, F_GETFL))
    flags = value ? flags | O_NONBLOCK : flags & ~O_NONBLOCK
    try check(sys_fcntl(fd, F_SETFL, flags))
  }
}
