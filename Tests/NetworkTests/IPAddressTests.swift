//
//  IPAddressTests.swift
//  webrtc-network
//
//  Created by sunlubo on 2020/9/17.
//  Copyright © 2020 sunlubo. All rights reserved.
//

@testable
import Network
import XCTest

final class IPAddressTests: XCTestCase {

  func testIPv4Address() {
    let ip1 = IPv4Address(127, 0, 0, 1)
    let ip2 = IPv4Address("127.0.0.1")
    XCTAssertNotNil(ip2)
    XCTAssertEqual(ip1, ip2)
    XCTAssertEqual(ip1.description, "127.0.0.1")

    XCTAssertEqual(IPv4Address(127, 0, 0, 1).octets, [127, 0, 0, 1])

    XCTAssertTrue(IPv4Address(0, 0, 0, 0).isAny)
    XCTAssertFalse(IPv4Address(45, 22, 13, 197).isAny)

    XCTAssertTrue(IPv4Address(127, 0, 0, 1).isLoopback)
    XCTAssertFalse(IPv4Address(45, 22, 13, 197).isLoopback)

    XCTAssertTrue(IPv4Address(169, 254, 0, 0).isLinkLocal)
    XCTAssertTrue(IPv4Address(169, 254, 10, 65).isLinkLocal)
    XCTAssertFalse(IPv4Address(16, 89, 10, 65).isLinkLocal)

    XCTAssertTrue(IPv4Address(224, 254, 0, 0).isMulticast)
    XCTAssertTrue(IPv4Address(236, 168, 10, 65).isMulticast)
    XCTAssertFalse(IPv4Address(172, 16, 10, 65).isMulticast)

    XCTAssertTrue(IPv4Address(255, 255, 255, 255).isBroadcast)
    XCTAssertFalse(IPv4Address(236, 168, 10, 65).isBroadcast)

    XCTAssertEqual(IPv4Address(192, 0, 2, 255).asIPv6Compatible, IPv6Address(0, 0, 0, 0, 0, 0, 49152, 767))
    XCTAssertEqual(IPv4Address(192, 0, 2, 255).asIPv6Mapped, IPv6Address(0, 0, 0, 0, 0, 65535, 49152, 767))
  }

  func testIPv6Address() {
    let ip1 = IPv6Address(0x2a02, 0x6b8, 0, 0, 0, 0, 0x11, 0x11)
    let ip2 = IPv6Address("2a02:6b8::11:11")
    XCTAssertNotNil(ip2)
    XCTAssertEqual(ip1, ip2)
    XCTAssertEqual(ip1.description, "2a02:6b8::11:11")

    XCTAssertEqual(IPv6Address(0, 0, 0, 0, 0, 0xffff, 0xc00a, 0x2ff).segments, [0, 0, 0, 0, 0, 0xffff, 0xc00a, 0x2ff])
    XCTAssertEqual(IPv6Address(0xff00, 0, 0, 0, 0, 0, 0, 0).octets, [255, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])

    XCTAssertTrue(IPv6Address(0, 0, 0, 0, 0, 0, 0, 0).isAny)
    XCTAssertFalse(IPv6Address(0, 0, 0, 0, 0, 0xffff, 0xc00a, 0x2ff).isAny)

    XCTAssertTrue(IPv6Address(0, 0, 0, 0, 0, 0, 0, 0x1).isLoopback)
    XCTAssertFalse(IPv6Address(0, 0, 0, 0, 0, 0xffff, 0xc00a, 0x2ff).isLoopback)

    XCTAssertTrue(IPv6Address(0xff00, 0, 0, 0, 0, 0, 0, 0).isMulticast)
    XCTAssertFalse(IPv6Address(0, 0, 0, 0, 0, 0xffff, 0xc00a, 0x2ff).isMulticast)

    XCTAssertTrue(IPv6Address(0, 0, 0, 0, 0, 0, 0, 2).isIPv4Compatabile)
    XCTAssertFalse(IPv6Address(0, 0, 0, 0, 0, 0, 0, 0).isIPv4Compatabile)
    XCTAssertFalse(IPv6Address(0, 0, 0, 0, 0, 0, 0, 1).isIPv4Compatabile)
    XCTAssertFalse(IPv6Address(0xff00, 0, 0, 0, 0, 0, 0, 0).isIPv4Compatabile)

    XCTAssertTrue(IPv6Address(0, 0, 0, 0, 0, 0xffff, 0xc00a, 0x2ff).isIPv4Mapped)
    XCTAssertFalse(IPv6Address(0xff00, 0, 0, 0, 0, 0, 0, 0).isIPv4Mapped)
  }

  static var allTests = [
    ("testIPv4Address", testIPv4Address),
    ("testIPv6Address", testIPv6Address),
  ]
}
