//
//  Error.swift
//  webrtc-network
//
//  Created by sunlubo on 2020/9/5.
//  Copyright © 2020 sunlubo. All rights reserved.
//

#if canImport(Darwin)
import Darwin.C
#else
import Glibc
#endif

public struct NetworkError: Error {
  public let code: Int
  public let message: String

  internal init(errno: Int32) {
    self.code = Int(errno)
    self.message = String(cString: strerror(errno))
  }

  internal init(code: Int, message: String) {
    self.code = code
    self.message = message
  }
}

@discardableResult
internal func check<T>(_ body: @autoclosure () -> T) throws -> T where T: FixedWidthInteger {
  let ret = body()
  if ret == -1 {
    throw NetworkError(errno: errno)
  }
  return ret
}
