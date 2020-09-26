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

  internal init?(_ ifaddr: ifaddrs) {
    guard let address = SocketAddress(ifaddr.ifa_addr.convert(to: sockaddr_storage.self)) else {
      return nil
    }

    self.name = String(cString: ifaddr.ifa_name)
    self.address = address
    self.netmask = SocketAddress(ifaddr.ifa_netmask.convert(to: sockaddr_storage.self))
  }
}

extension NetworkInterface {

  public static var all: [NetworkInterface] {
    var ifaddr: UnsafeMutablePointer<ifaddrs>?
    guard getifaddrs(&ifaddr) != -1 else {
      return []
    }

    var list = [NetworkInterface]()
    var next = ifaddr
    while next != nil {
      if let ni = NetworkInterface(next!.pointee) {
        list.append(ni)
      }
      next = next?.pointee.ifa_next
    }
    freeifaddrs(ifaddr)
    return list
  }
}

// MARK: - NetworkInterface + CustomStringConvertible

extension NetworkInterface: CustomStringConvertible {
  public var description: String {
    "\(name): \(address.family == AF_INET ? "inet" : "inet6") \(address.ip) \(netmask.map({ "netmask \($0.ip)" }) ?? "")"
  }
}
