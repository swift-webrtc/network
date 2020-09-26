//
//  DnsResolver.swift
//  webrtc-network
//
//  Created by sunlubo on 2020/9/6.
//  Copyright © 2020 sunlubo. All rights reserved.
//

#if canImport(Darwin)
import Darwin.C
#else
import Glibc
#endif

internal struct DnsResolver {

  internal static func query(_ string: String) throws -> SocketAddress {
    let parts = string.split(separator: ":")
    return try DnsResolver().query(host: String(parts[0]), port: parts.count > 1 ? UInt16(parts[1]) ?? 0 : 0)[0]
  }

  internal var socktype: Int32
  internal var proto: Int32

  internal init(socktype: Int32 = SOCK_STREAM, proto: Int32 = 0) {
    self.socktype = socktype
    self.proto = proto
  }

  internal func query(host: String, port: UInt16 = 0) throws -> [SocketAddress] {
    var hints = addrinfo()
    hints.ai_family = AF_UNSPEC
    hints.ai_socktype = socktype
    hints.ai_protocol = proto

    var result: UnsafeMutablePointer<addrinfo>?
    let ret = getaddrinfo(host, String(port), &hints, &result)
    if ret != 0 {
      throw NetworkError(code: Int(ret), message: String(cString: gai_strerror(ret)))
    }

    var list = [SocketAddress]()
    var next = result
    while let addr = next {
      switch addr.pointee.ai_family {
      case AF_INET:
        list.append(.v4(.init(addr.pointee.ai_addr.convert())))
      case AF_INET6:
        list.append(.v6(.init(addr.pointee.ai_addr.convert())))
      default:
        ()
      }
      next = next?.pointee.ai_next
    }
    freeaddrinfo(result)
    return list
  }
}
