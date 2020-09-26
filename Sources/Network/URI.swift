//
//  URI.swift
//  webrtc-network
//
//  Created by sunlubo on 2020/9/19.
//  Copyright © 2020 sunlubo. All rights reserved.
//

/// Currently only the following formats are supported:
///
/// - stun:127.0.0.1
/// - stun:127.0.0.1:3478
///
public func parseURI(_ string: String) -> (scheme: String, host: IPAddress, port: SocketAddress.Port?)? {
  let parts = string.split(separator: ":")
  let host: IPAddress?
  let port: SocketAddress.Port?
  switch parts.count {
  case 2:
    host = try? DnsResolver.query(parts.dropFirst().joined(separator: ":")).ip
    port = nil
  case 3:
    host = try? DnsResolver.query(parts.dropFirst().dropLast().joined(separator: ":")).ip
    port = UInt16(parts[2]).flatMap(SocketAddress.Port.init(rawValue:))
  default:
    host = nil
    port = nil
  }
  if host == nil || parts.count == 3 && port == nil {
    return nil
  }

  return (String(parts[0]), host!, port)
}
