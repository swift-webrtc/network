//
//  LinuxMain.swift
//  webrtc-network
//
//  Created by sunlubo on 2020/9/5.
//  Copyright © 2020 sunlubo. All rights reserved.
//

import NetworkTests
import XCTest

var tests = [XCTestCaseEntry]()
tests += SocketAddressTests.allTests
tests += IPAddressTests.allTests
XCTMain(tests)
