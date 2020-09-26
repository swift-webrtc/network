//
//  System.swift
//  webrtc-network
//
//  Created by sunlubo on 2020/9/26.
//  Copyright © 2020 sunlubo. All rights reserved.
//

#if canImport(Darwin)
import Darwin.C
#else
import Glibc
#endif

internal typealias s_linger = linger

internal func sys_socket(_ domain: Int32, _ type: Int32, _ proto: Int32) -> Int32 {
  socket(domain, type, proto)
}

internal func sys_bind(_ socket: Int32, _ address: UnsafePointer<sockaddr>!, _ address_len: socklen_t) -> Int32 {
  bind(socket, address, address_len)
}

internal func sys_listen(_ socket: Int32, _ backlog: Int32) -> Int32 {
  listen(socket, backlog)
}

internal func sys_accept(_ socket: Int32, _ address: UnsafeMutablePointer<sockaddr>!, _ address_len: UnsafeMutablePointer<socklen_t>!) -> Int32 {
  accept(socket, address, address_len)
}

internal func sys_connect(_ socket: Int32, _ address: UnsafePointer<sockaddr>!, _ address_len: socklen_t) -> Int32 {
  connect(socket, address, address_len)
}

internal func sys_send(_ socket: Int32, _ buffer: UnsafeRawPointer!, _ length: Int, _ flags: Int32) -> Int {
  send(socket, buffer, length, flags)
}

internal func sys_recv(_ socket: Int32, _ buffer: UnsafeMutableRawPointer!, _ length: Int, _ flags: Int32) -> Int {
  recv(socket, buffer, length, flags)
}

internal func sys_sendto(_ socket: Int32, _ buffer: UnsafeRawPointer!, _ length: Int, _ flags: Int32, _ dest_addr: UnsafePointer<sockaddr>!, _ dest_len: socklen_t) -> Int {
  sendto(socket, buffer, length, flags, dest_addr, dest_len)
}

internal func sys_recvfrom(_ socket: Int32, _ buffer: UnsafeMutableRawPointer!, _ length: Int, _ flags: Int32, _ address: UnsafeMutablePointer<sockaddr>!, _ address_len: UnsafeMutablePointer<socklen_t>!) -> Int {
  recvfrom(socket, buffer, length, flags, address, address_len)
}

internal func sys_shutdown(_ socket: Int32, _ how: Int32) -> Int32 {
  shutdown(socket, how)
}

internal func sys_close(_ fd: Int32) -> Int32 {
  close(fd)
}

internal func sys_getpeername(_ socket: Int32, _ address: UnsafeMutablePointer<sockaddr>!, _ address_len: UnsafeMutablePointer<socklen_t>!) -> Int32 {
  getpeername(socket, address, address_len)
}

internal func sys_getsockname(_ socket: Int32, _ address: UnsafeMutablePointer<sockaddr>!, _ address_len: UnsafeMutablePointer<socklen_t>!) -> Int32 {
  getsockname(socket, address, address_len)
}

internal func sys_getsockopt(_ socket: Int32, _ level: Int32, _ option_name: Int32, _ option_value: UnsafeMutableRawPointer!, _ option_len: UnsafeMutablePointer<socklen_t>!) -> Int32 {
  getsockopt(socket, level, option_name, option_value, option_len)
}

internal func sys_setsockopt(_ socket: Int32, _ level: Int32, _ option_name: Int32, _ option_value: UnsafeRawPointer!, _ option_len: socklen_t) -> Int32 {
  setsockopt(socket, level, option_name, option_value, option_len)
}

internal func sys_fcntl(_ fd: Int32, _ cmd: Int32) -> Int32 {
  fcntl(fd, cmd)
}

internal func sys_fcntl(_ fd: Int32, _ cmd: Int32, _ value: Int32) -> Int32 {
  fcntl(fd, cmd, value)
}
