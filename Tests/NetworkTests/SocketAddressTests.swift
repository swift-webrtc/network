//
//  SocketAddressTests.swift
//  webrtc-network
//
//  Created by sunlubo on 2020/9/6.
//  Copyright © 2020 sunlubo. All rights reserved.
//

@testable
import Network
import XCTest

final class SocketAddressTests: XCTestCase {

  func testSocketAddressV4() {
    let address = SocketAddressV4(ip: IPv4Address(127, 0, 0, 1), port: 8080)
    XCTAssertEqual(address.ip, IPv4Address(127, 0, 0, 1))
    XCTAssertEqual(address.port, 8080)
    XCTAssertEqual(address.description, "127.0.0.1:8080")
  }

  func testSocketAddressV6() {
    let address = SocketAddressV6(ip: IPv6Address(0, 0, 0, 0, 0, 0, 0, 1), port: 8080, flowinfo: 10, scopeId: 78)
    XCTAssertEqual(address.ip, IPv6Address(0, 0, 0, 0, 0, 0, 0, 1))
    XCTAssertEqual(address.port, 8080)
    XCTAssertEqual(address.flowinfo, 10)
    XCTAssertEqual(address.scopeId, 78)
    XCTAssertEqual(address.description, "[::1]:8080")
  }

  func testParse() {
    XCTAssertEqual(SocketAddressV4("224.120.45.1:23456"), SocketAddressV4(ip: IPv4Address(224, 120, 45, 1), port: 23456))
    XCTAssertEqual(SocketAddressV6("[2a02:6b8:0:1::1]:53"), SocketAddressV6(ip: IPv6Address(0x2a02, 0x6b8, 0, 1, 0, 0, 0, 1), port: 53))
    XCTAssertEqual(SocketAddress("224.120.45.1:23456"), .v4(SocketAddressV4(ip: IPv4Address(224, 120, 45, 1), port: 23456)))
    XCTAssertEqual(SocketAddress("[2a02:6b8:0:1::1]:53"), .v6(SocketAddressV6(ip: IPv6Address(0x2a02, 0x6b8, 0, 1, 0, 0, 0, 1), port: 53)))
  }

  static var allTests = [
    ("testSocketAddressV4", testSocketAddressV4),
    ("testSocketAddressV6", testSocketAddressV6),
    ("testParse", testParse),
  ]
}
