//
//  LinuxMain.swift
//  webrtc-network
//
//  Created by sunlubo on 2020/9/5.
//  Copyright © 2020 sunlubo. All rights reserved.
//

import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
  return [
    testCase(SocketAddressTests.allTests),
    testCase(IPAddressTests.allTests),
  ]
}
#endif
