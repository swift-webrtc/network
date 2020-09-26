//
//  TCPListener.swift
//  webrtc-network
//
//  Created by sunlubo on 2020/9/5.
//  Copyright © 2020 sunlubo. All rights reserved.
//

import Core
import Logging
#if canImport(Darwin)
import Darwin.C
#else
import Glibc
#endif

/// A TCP socket server, listening for connections.
public final class TCPListener {

  /// Creates a new `TCPListener` which will be bound to the specified address.
  public static func bind(to address: SocketAddress, backlog: Int = 1024) throws -> TCPListener {
    let fd = try check(sys_socket(address.family, SOCK_STREAM, 0))
    do {
      var value = true
      try check(sys_setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &value, socklen_t(MemoryLayout.size(ofValue: value))))
      try check(address.withSockAddr({ sys_bind(fd, $0, $1) }))
      try check(sys_listen(fd, Int32(backlog)))
    } catch {
      _ = sys_close(fd)
      throw error
    }
    return TCPListener(fd: fd)
  }

  internal let fd: Int32

  internal init(fd: Int32) {
    self.fd = fd
  }

  /// Accept a new incoming connection from this listener.
  ///
  /// This function will block the calling thread until a new TCP connection is established.
  public func accept() throws -> TCPSocket {
    TCPSocket(fd: try check(sys_accept(fd, nil, nil)))
  }

  public func close() throws {
    try check(sys_close(fd))
  }
}

// MARK: - TCPListener Address

extension TCPListener {
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
}

// MARK: - Options

extension TCPListener {

  /// Gets the value of the `IP_TTL` option on this socket.
  public func ttl() throws -> Int {
    var value = 0
    var size = 0 as socklen_t
    try check(sys_getsockopt(fd, IPPROTO_IP, IP_TTL, &value, &size))
    return value
  }

  /// Sets the value for the `IP_TTL` option on this socket.
  public func setTtl(_ value: Int) throws {
    var value = value
    try check(sys_setsockopt(fd, IPPROTO_IP, IP_TTL, &value, socklen_t(MemoryLayout.size(ofValue: value))))
  }
}
