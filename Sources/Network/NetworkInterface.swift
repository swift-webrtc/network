//
//  NetworkInterface.swift
//  webrtc-network
//
//  Created by sunlubo on 2020/9/23.
//  Copyright © 2020 sunlubo. All rights reserved.
//

#if canImport(Darwin)
import Darwin.C
#else
import Glibc
#endif

public struct NetworkInterface {
  public let name: String
  public let address: SocketAddress
  public let netmask: SocketAddress?

  internal init?(_ ifaddrs: ifaddrs) {
    guard let ifa_addr = ifaddrs.ifa_addr, let address = SocketAddress(ifa_addr.convert(to: sockaddr_storage.self)) else {
      return nil
    }

    self.name = String(cString: ifaddrs.ifa_name)
    self.address = address
    self.netmask = SocketAddress(ifaddrs.ifa_netmask.convert(to: sockaddr_storage.self))
  }
}

extension NetworkInterface {

  public static var all: [NetworkInterface] {
    var ifaddrs: UnsafeMutablePointer<ifaddrs>?
    guard getifaddrs(&ifaddrs) != -1 else {
      return []
    }

    var list = [NetworkInterface]()
    var next = ifaddrs
    while next != nil {
      if let ni = NetworkInterface(next!.pointee) {
        list.append(ni)
      }
      next = next?.pointee.ifa_next
    }
    freeifaddrs(ifaddrs)
    return list
  }
}

// MARK: - NetworkInterface + CustomStringConvertible

extension NetworkInterface: CustomStringConvertible {
  public var description: String {
    "\(name): \(address.family == AF_INET ? "inet" : "inet6") \(address.ip) \(netmask.map({ "netmask \($0.ip)" }) ?? "")"
  }
}
