//
//  main.swift
//  webrtc-network
//
//  Created by sunlubo on 2020/10/18.
//  Copyright © 2020 sunlubo. All rights reserved.
//

import Network
import Foundation

do {
  let socket = try UDPSocket.bind(to: .v4(.init(ip: IPv4Address("192.168.100.73")!, port: 34254)))
  let message = [0, 1, 0, 0, 33, 18, 164, 66, 214, 202, 146, 171, 226, 237, 64, 151, 194, 143, 91, 7] as [UInt8]
  _ = try message.withUnsafeBytes { data in
    try socket.sendto(data, address: .v4(.init(ip: IPv4Address("217.10.68.145")!, port: 3478)))
  }
  sleep(30)
} catch {
  print(error)
}
